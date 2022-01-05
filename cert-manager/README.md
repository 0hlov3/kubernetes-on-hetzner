# cert-manager deployment

## [Add the Jetstack Helm repository:](https://cert-manager.io/docs/installation/helm/)
```shell
helm repo add jetstack https://charts.jetstack.io
$ helm repo update
```

## cert-manager helm deployment
```shell
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f values.yaml
```

## Create the ClusterIssuer
```shell
kubectl apply -f ClusterIssuer.yaml
```