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

### Storage Setup

We will be creating an Azure file share to store our data in for the DBP.

```text
export AKS_PERS_SHARE_NAME=aksshare

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=`az storage account show-connection-string -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -o tsv`

# Create the file share
az storage share create -n $AKS_PERS_SHARE_NAME

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $AKS_PERS_RESOURCE_GROUP --account-name $AKS_PERS_STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)

# Echo storage key
echo Storage account key: $STORAGE_KEY
```

Create a kubernetes secret with the credentials for connecting to the azure file.

```text
kubectl create secret generic azurefile-secret --from-literal=azurestorageaccountname=$AKS_PERS_STORAGE_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$STORAGE_KEY -n $DESIREDNAMESPACE
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

Deploy the dbp: 

```text
helm install alfresco-incubator/alfresco-dbp -f values.yaml \
--set alfresco-infrastructure.persistence.azureFile.enabled=true \
--set alfresco-infrastructure.persistence.azureFile.secretName=azurefile-secret \
--set alfresco-infrastructure.persistence.azureFile.shareName=$AKS_PERS_SHARE_NAME \
--set alfresco-infrastructure.nginx-ingress.enabled=false \
--namespace=$DESIREDNAMESPACE
```











