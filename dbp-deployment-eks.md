---
description: 'Configuring, fine-tuning'
---

# DBP Deployment EKS

### Cluster Setup

Create the cluster

```text
eksctl create cluster --name=<your-name-here> --region=eu-west-1 --nodes=3 --zones=eu-west-1a,eu-west-1b
```

{% hint style="info" %}
Cluster creation takes ~15 minutes
{% endhint %}

List cluster nodes once it is created:

```text
kubectl get nodes
```

Initialize helm

```text
kubectl create sa tiller -n kube-system
kubectl create clusterrolebinding tiller-clusterrole-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
```

Create a namespace

```text
export DESIREDNAMESPACE=example
kubectl create namespace $DESIREDNAMESPACE
```

Create the secret object you got from quay.io

```text
kubectl create -f ~/secret.yaml -n $DESIREDNAMESPACE
```

{% hint style="info" %}
[https://eksworkshop.com/spotworkers/](https://eksworkshop.com/spotworkers/)

[https://eksworkshop.com/scaling/deploy\_ca/](https://eksworkshop.com/scaling/deploy_ca/)
{% endhint %}

### Ingress Setup <a id="ingress-setup"></a>

Install nginx-ingress to your namespace.

```text
cat <<EOF > ingressvalues.yml 
rbac:
  create: true
controller:
  scope:
    enabled: true  
  config:
    ssl-redirect: "false"
    server-tokens: "false"
EOF
helm install stable/nginx-ingress -f ingressvalues.yml --name ingress --namespace $DESIREDNAMESPACE
```

Get the lb adress of your ingress

```text
kubectl get svc/ingress-nginx-ingress-controller -n example -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Go to Route53 and create an A entry with the elb you just got as an alias.

{% hint style="warning" %}
The entry must be a wildcard entry.
{% endhint %}

![](.gitbook/assets/image%20%287%29.png)

Save the entry to a variable:

```text
export DNSHOST=<Your Hostname withour the wildcard>
```

### Setup Storage

Install the NFS Server chart:

```text
helm install stable/nfs-server-provisioner --name nfsserver --namespace $DESIREDNAMESPACE  --set persistence.enabled=true,persistence.size=30Gi 
```

### Deploy the Digital Business Platform

Add the alfresco repositories to helm

```text
helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator
helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
```

Create your values file.

```text
cat <<EOF > myvalues.yml 
global:
  keycloak:
    url: "http://alfresco-identity-service.$DNSHOST/auth"
  gateway:
    http: true
    host: "activiti-cloud-gateway.$DNSHOST"

alfresco-infrastructure:
  persistence:
    storageClass:
      enabled: true
      name: "nfs"
  nginx-ingress:
    enabled: false

alfresco-content-services:
  repository:
    replicaCount: 1
    livenessProbe:
      initialDelaySeconds: 420
    environment:
      IDENTITY_SERVICE_URI: "http://alfresco-identity-service.$DNSHOST/auth"
  externalHost: "alfresco-cs-repository.$DNSHOST"
  alfresco-digital-workspace:
    APP_CONFIG_OAUTH2_HOST: "http://alfresco-identity-service.$DNSHOST/auth/realms/alfresco"
  transformrouter:
    replicaCount: 1
  imagemagick:
    replicaCount: 1
  libreoffice:
    replicaCount: 1
  pdfrenderer:
    replicaCount: 1
  tika:
    replicaCount: 1
  share:
    replicaCount: 1
replicaCount: 1

activiti-cloud-full-example:
  infrastructure:
    activiti-cloud-gateway:
      ingress:
        hostName: "activiti-cloud-gateway.$DNSHOST"
EOF
```

Deploy the chart

```text
helm install alfresco-incubator/alfresco-dbp -f myvalues.yml --namespace $DESIREDNAMESPACE
```

