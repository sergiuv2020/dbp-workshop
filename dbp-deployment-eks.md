---
description: 'Configuring, fine-tuning'
---

# DBP Deployment EKS

### Cluster Setup

Create the cluster

```text
eksctl create cluster \
--name=<your-name-here> \
--region=<your region> \
--nodes=2 \
--node-type=m5.xlarge \
--external-dns-access \
--zones=zonea,zoneb
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

Install External DNS

```text
helm install stable/external-dns \
--name externaldns \
--namespace kube-system \
--set aws.region="eu-west-1" \
--set rbac.create=true
--set txtOwnerId="workshop"

```

#### 

### Storage Setup

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

Export a DNS host you would like to use:

```text
export DNSHOST=YourDnsHost 
# eg test.hostedzone
```

Create your values file.

```text
cat <<EOF > myvalues.yaml
global:
  keycloak:
    url: "https://alfresco-identity-service.$DNSHOST/auth"
  gateway:
    host: "activiti-cloud-gateway.$DNSHOST"
alfresco-infrastructure:
  alfresco-identity-service:
    keycloak:
      postgresql:
        password: identity
        persistence:
          existingClaim: null
  nginx-ingress:
    controller:
      publishService:
        enabled: true
      service:
        targetPorts:
          http: http
          https: http
        annotations:
          external-dns.alpha.kubernetes.io/hostname: "*.$DNSHOST"
  persistence:
    storageClass:
      enabled: true
      name: "nfs"
alfresco-digital-workspace:
  enabled: true
alfresco-content-services:
  alfresco-digital-workspace:
    "APP_CONFIG_AUTH_TYPE": "OAUTH"
    "APP_CONFIG_OAUTH2_HOST": "http://alfresco-identity-service.$DNSHOST/auth/realms/alfresco"
    "APP_CONFIG_OAUTH2_CLIENTID": "alfresco"
    "APP_CONFIG_OAUTH2_IMPLICIT_FLOW": "\"true\""
    "APP_CONFIG_OAUTH2_SILENT_LOGIN": "\"true\""
    "APP_CONFIG_OAUTH2_REDIRECT_LOGIN": "/digital-workspace/"
    "APP_CONFIG_OAUTH2_REDIRECT_LOGOUT": "/digital-workspace/logout" 
  repository:
    environment:
      IDENTITY_SERVICE_URI: "http://alfresco-identity-service.$DNSHOST/auth"
    replicaCount: 1
    livenessProbe: 
      initialDelaySeconds: 420
    readynessProbe:
      initialDelaySeconds: 500
    resources:
      requests:
        memory: "2000Mi"
  externalHost: "alfresco-cs-repository.$DNSHOST"  
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
  postgresql:
    persistence:
      existingClaim: null
activiti-cloud-full-example:
  infrastructure:
    activiti-cloud-gateway:
      ingress:
        hostName: "activiti-cloud-gateway.$DNSHOST"
        
EOF
                     
```

Deploy the chart

```text
helm install alfresco-incubator/alfresco-dbp -f myvalues.yaml --namespace $DESIREDNAMESPACE
```

