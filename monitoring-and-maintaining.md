---
description: >-
  Tips & Tricks, logs, checking stuff inside the containers, updating
  deployments
---

# Monitoring and Maintaining

### Kubectl tips


This will save you a lot of typing, but I've not used it in the examples below.

```console
$ alias k=kubectl
```

#### Cheat sheet and book

Check out the official [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) which gives plenty of examples. 
Even better, brand new for Kubernetes 1.14, [kubectl has it's own gitbook](https://kubectl.docs.kubernetes.io/).

#### Get a shell in a container

Assuming you're using a container with `bash` installed

```bash
kubectl exec -ti pod-name bash
```

Alpine only has `sh` installed

```bash
kubectl exec -ti pod-name sh
```

Note that there are containers that don't even offer shells (ones based directly on "scratch" or [Distroless](https://github.com/GoogleContainerTools/distroless)).

#### Get a shell in a _specific_ container

To run a shell in a _specific_ container in a pod use `-c`:

```bash
kubectl exec -ti pod-name -c container-name bash
```

You can use this with any *running* container. Indeed you can also use it with an `initContainer` if it's stuck.

You can find the list of containers _viz._

```bash
kubectl get po pod-name \
  -o jsonpath="{.spec['containers','initContainers'][*].name}"
```

Here's a real example.

```console
$ kubectl get po acs-alfresco-cs-repository-577c788567-wlg5g \
  -n nic-acs-trial \
  -o jsonpath="{.spec['containers','initContainers'][*].name}"
alfresco-content-services init-db
```

#### Logs

You can get logs via

```bash
kubectl logs pod-name
```

You can also get them for pods that have been replaced by newer instances

```bash
kubectl logs pod-name --previous
```

For issues with pods, then `describe` shows any issues at the end

```bash
k describe po pod-name
```

#### Extra tools

If you're working with mutliple clusters, or with a particular namespace, then [kubectx and kubens](https://kubectx.dev) are useful.

## Three Pillars of Observability

Logs, metrics, and traces are called the three pillars of observability. The typical open source tools used for these tasks follow:

* Logs are sent to an ELK stack
* Metrics are sent to Prometheus, and visualised in Grafana
* Traces are sent to Jaeger

### Prometheus, Graphana and Alert Manager

The simplest way to get started is to use the [kube-prometheus package](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus).

This installs Prometheus using the Prometheus Operator and sets up a
lot of the common monitoring for you.

Follow their Quickstart (which _can_ throw a lot of errors at the first command). 

kube-prometheus relies on understanding JSonnet to configure it.

#### Port-Forwarding

If you have a bastion host, you will need to tunnel to get to that

```bash
ssh -L 9090:127.0.0.1:9090 bastion-host -N -f
```

Then visit http://localhost:9090

Repeat for ports 3000 (graphana) and 9093 (alert-manager).

#### Alfresco Content Services

ACS 6.1.0 exposes a Prometheus endpoint at `/alfresco/s/prometheus` and you can read more about it in the [acs-packaging site](https://github.com/Alfresco/acs-packaging/tree/master/docs/micrometer).

#### Istio

If you use istio service mesh, it comes with Promethueus, _et al._.

### ELK Setup

First let's create a separate namespace

```bash
kubectl create ns logging
```

Install Elastic Search

```bash
helm install --name elastic stable/elasticsearch --namespace=logging
```

Install fluent-bit

```bash
helm install --name fluent-bit stable/fluent-bit --namespace=logging --set backend.type=es --set backend.es.host=elastic-elasticsearch-client
```

Install Kibana

