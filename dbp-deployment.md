---
description: 'Configuring, fine-tuning'
---

# DBP deployment - Azure

### Cluster Setup

Create a Resource group and a  Storage Account:

```text
export AKS_PERS_STORAGE_ACCOUNT_NAME=aksdeploy$RANDOM
export AKS_PERS_RESOURCE_GROUP=myAKSShare
export AKS_PERS_LOCATION=westeurope

az group create --name $AKS_PERS_RESOURCE_GROUP --location $AKS_PERS_LOCATION
az storage account create -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -l $AKS_PERS_LOCATION --sku Standard_LRS

```

Create your cluster: 

```bash
az aks create --resource-group $AKS_PERS_RESOURCE_GROUP \
--name myAKSCluster --node-count 3 --enable-addons monitoring \
--generate-ssh-keys --kubernetes-version 1.12.5
```

Get your credentials for the cluster:

```text
az aks get-credentials --resource-group $AKS_PERS_RESOURCE_GROUP --name myAKSCluster
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

### Setup Storage

Install the NFS Server chart:

```text
helm install stable/nfs-server-provisioner --name nfsserver --namespace $DESIREDNAMESPACE
```

### Ingress Setup

Add the alfresco repositories to helm

```text
helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator
helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
```

Install nginx-ingress to your namespace.

```text
helm install stable/nginx-ingress --name ingress --namespace $DESIREDNAMESPACE
```

### DBP Setup

Get your External ingress ip address and export it to a variable.

```text
export LBIP=$(kubectl get svc ingress-nginx-ingress-controller -n $DESIREDNAMESPACE -o jsonpath={.status.loadBalancer.ingress[0].ip}) && echo $LBIP
```

Get the values file from the alfresco-dbp-deployment repo and set the ingress ip there.

```text
curl -O https://raw.githubusercontent.com/Alfresco/alfresco-dbp-deployment/master/charts/incubator/alfresco-dbp/values.yaml
sed -i s/https/http/g values.yaml
sed -i s/REPLACEME/$LBIP.nip.io/g values.yaml
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
    url: "http://alfresco-identity-service.$LBIP.nip.io/auth"
  gateway:
    http: true
    host: "activiti-cloud-gateway.$LBIP.nip.io"

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
      IDENTITY_SERVICE_URI: "http://alfresco-identity-service.$LBIP.nip.io/auth"
  externalHost: "alfresco-cs-repository.$LBIP.nip.io"
  alfresco-digital-workspace:
    APP_CONFIG_OAUTH2_HOST: "http://alfresco-identity-service.$LBIP.nip.io/auth/realms/alfresco"
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
        hostName: "activiti-cloud-gateway.$LBIP.nip.io"
EOF
```

Deploy the chart

```text
helm install alfresco-incubator/alfresco-dbp -f myvalues.yml --namespace $DESIREDNAMESPACE --set persistence.enabled=true,persistence.size=30Gi
```







