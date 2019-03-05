---
description: >-
  Tips & Tricks, logs, checking stuff inside the containers, updating
  deployments
---

# Monitoring and Maintaining

### Kubectl tips

This will save you a lot of typing!

```bash
alias k=kubectl
```

Check out the official [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) which gives plenty of examples.

If you're working with mutliple clusters, a fixed namespace, then [kubectx and kubens](https://kubectx.dev) are useful.

### Prometheus, Graphana and Alert Manager

The simplest way to get started is to use the [kube-prometheus package](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus).

This installs Prometheus using the Prometheus Operator and sets up a
lot of the common monitoring for you.

Follow their Quickstart (which _can_ throw a lot of errors).

#### Port-Forwarding

If you have a bastion host, you will need to tunnel to get to that

```bash
ssh -L 9090:127.0.0.1:9090 bastion-host -N -f
```

Then visit http://localhost:9090

Repeat for ports 3000 (graphana) and 9093 (alert-manager).

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

