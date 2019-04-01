---
description: >-
  Rolling out custom docker images, adding more services to the deployment,
  adding an extra frontend
---

# Extending the a DBP deployment

### Rolling Upgrades - Standard upgrades in k8s

We have created a test image with an ADF app we will use for the purpose of demonstrating upgrades.

To change the version of a currently deployed image, we can either use:

* Helm upgrade
* Kubectl Deployment upgrade 
* Kubectl Patch. 

Lets do a helm upgrade, the other ones can be found here -&gt;

{% embed url="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/\#updating-a-deployment" %}

{% embed url="https://kubernetes.io/docs/tasks/run-application/update-api-object-kubectl-patch/" %}

Since we will be using release name trough the next commands lets export a release name variable:

```text
export releaseName=<your dbp releasename>
```

```text
helm upgrade $releaseName alfresco-incubator/alfresco-dbp \
--reuse-values \
--set alfresco-content-services.alfresco-digital-workspace.image.repository="svidrascu/devcon" \
--namespace $DESIREDNAMESPACE

#check the digital workspace pod and endpoint
```

Now lets see the history of the deployment

```text
helm history releaseName
```

Since it seems we forgot to set the tag on the image, let's do that since the frontend looks to be down.

```text
helm upgrade $releaseName alfresco-incubator/alfresco-dbp \
--reuse-values \
--set alfresco-content-services.alfresco-digital-workspace.image.tag="latest" \
--namespace $DESIREDNAMESPACE
```

Ok, now let's see the history and rollback to version 1.

```text
helm history $releaseName

helm rollback $releaseName 1

#Check the digital-workspace endpoint and pod
```

{% hint style="warning" %}
The upgrades/rollbacks we just did are on an adf frontend so usually no data gets lost but in the case of other applications, like repo for example you will have to have in place pre-upgrade/post-upgrade helm hooks or pod lifecycle events.   
These will help you handling data backups/snapshots and restoration on rollbacks so that you do not corrupt your data.
{% endhint %}

### Adding an extra ADF Frontend

Adding additional apps connecting to an extra ADF Frontend is fairly easy. Let's clone the workshop repo.

```text
git clone https://github.com/svidrascu/dbp-workshop.git
```

This repo already has a chart in it, a very basic one that holds a generated adf app, let's install it.

```text
cd dbp-workshop
helm install dbp-workshop/devcon --name adf --namespace $DESIREDNAMESPACE
```

Now if you access the same host as digital-workspace but under /development/ path you will see that your app is deployed. And in our case it actually uses the same backend repository as digital workspace so you could potentially have two frontends for different purposes and users. 

