# CI/CD Considerations

There's a multitude of options you could use here.

What i believe brings a lot of flexibility to the table is running jobs as containers. That is just amazing because you don't need to have a snowflake agents, you can just use docker-hub images for the tooling you need. Everything is quick and painless, and its IN CODE !!! Gone forever are the days of clicking trough CI. 

### JenkinsX - Just Press RUN

Jenkins is still at the top of CI software on the market, with other trying their best to keep up.

GitOps

Build Pipeline as code but not just a template language, groovy.

Shared Libraries.

All docker ecosystem in kubernetes.

![](.gitbook/assets/image%20%282%29.png)

### Gitlab CI 

Starting with community edition you can easily just deploy it within your own k8s cluster and have jobs running also in the same cluster.

Gitlab has a prebuilt helm deployment setup but you can always just alter that to your needs.



#### The CI/CD flow

![The Gitlab CI Flow](.gitbook/assets/image%20%281%29.png)

From our experience Gitlab was very very easy to use since you do not even need to setup your cluster. Gitlab does it for you automatically.

#### Monitoring OOTB

You get all the environments out of the box and, as a cherry on top you get monitoring with prometheus on your deployed ingress.

![Prometheus scraping and custom UI per environment within your project](.gitbook/assets/image%20%283%29.png)

