---
description: Infrastructure Debugging
---

# Troubleshooting of DBP deployment

### First Steps

Dashboard Setup:

```text
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
EOF
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

Get the secret token for connecting:

```text
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

Proxy the connection to the dashboard:

```text
kubectl proxy
```

Create tunnel to localhost:

```text
ssh -f ec2-user@PUBLIC-IP-EC2-INSTANCE -L 8001:localhost:8001 -N
```

Pod failures:

* Image missing failures
* Missing Resources
* Storage Bindings
* Storage Failures
* Ingress Failures
* OOM instant restarts
* Java limits

Helm issues:

* Parent to child value relationships
* Stateful Sets and Volume Failures
* Setting Dynamic values on current chart

ReplicaSet Issues:

* Scaling Failures only at replica-set level

Cluster Autoscaling

* Not ready nodes
* Resource Definitions

Further reading:

{% embed url="https://github.com/hjacobs/kubernetes-failure-stories" %}

{% embed url="https://srcco.de/posts/kubernetes-failure-stories.html" %}



