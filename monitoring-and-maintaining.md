---
description: >-
  Tips & Tricks, logs, checking stuff inside the containers, updating
  deployments
---

# Monitoring and Maintaining

### ELK Setup

Install Elastic Search

```text
helm install --name elastic stable/elasticsearch --namespace=logging
```

Install fluent-bit

```text
helm install --name fluent-bit stable/fluent-bit --namespace=logging --set backend.type=es --set backend.es.host=elastic-elasticsearch-client
```

Install Kibana



  
  
Prometheus Quick Setup

