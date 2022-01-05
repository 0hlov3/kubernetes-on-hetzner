# Installs Ingress-NGINX with Helm3


## Add the Helm Repo
```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

## Nginx-External deployment
```shell
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -f values.yaml --namespace ingress-nginx --create-namespace
```

## Annotations

| Annotations                                   | Description | Option |
| --------------------------------------------- | ----------- | ------ |
| load-balancer.hetzner.cloud/location          |             |        |
| load-balancer.hetzner.cloud/network-zone      |             |        |
| load-balancer.hetzner.cloud/use-private-ip    |             |        |
| load-balancer.hetzner.cloud/balancers-enabled |             |        |

```
load-balancer.hetzner.cloud/location: nbg1
# For internal IP-Only
load-balancer.hetzner.cloud/use-private-ip: "true"
```

## Possible-Locations

| eu-central	      | us-east              |
| ------------------- | -------------------- |
| DE Falkenstein fsn1 |	US Ashburn, VA ash
| DE Nuremberg nbg1	  |
| FI Helsinki hel1    |

## Notes
Metrics are Disabled right now.