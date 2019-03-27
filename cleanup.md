# Cleanup

Get all helm installations:

```text
helm ls
```

Delete them all using:

```text
helm delete --purge release-name1 release-name2
```

Delete the cluster:

```text
eksctl delete cluster <your clustername> -r <your region>
```

Delete the ec2 machine and the ec2 + cloudformation service roles you created.

