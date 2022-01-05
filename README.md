# Install a Kubernetes-Cluster on Hetzner Cloud

## Install [hcloud](https://github.com/hetznercloud/cli)
```shell
brew install hcloud
```

```shell
hcloud context create $ProjectName
```
## Create 2 Nodes

## Install 2 Nodes

## Add Users

```shell
useradd -m --user-group -s /bin/bash -G sudo docker testuser
```

## Configure Sudoers


## Configure SSH

## Initialize the Cluster (controller01 only)
First get the PublicIP of the Controller.

```shell
hcloud server list
```
```shell
#Output
❯ hcloud server list
ID         NAME           STATUS    IPV4              IPV6          DATACENTER
$ServerID   controller01   running   $externalIPv4   $externalIPv6   $Location
$ServerID   node01         running   $externalIPv4   $externalIPv6   $Location
```

Get the Private-IP
```
hcloud server ip controller01
```
```
#Output
$PrivateIP
```
```shell
kubeadm init --apiserver-advertise-address $externalIPv4 --apiserver-cert-extra-sans $PrivateIP,$externalIPv4 --control-plane-endpoint $PrivateIP --pod-network-cidr 10.244.0.0/16
```
## Join other Nodes

## Install [hcloud-cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager)

## Install [csi-driver](https://github.com/hetznercloud/csi-driver)

## Install [ingress-nginx](./ingress-nginx/README.md)

## Install [cert-manager](./cert-manager/README.md)

## Create Labels

## Create Firewall

## Create API-Tokens

## Testing
```shell
k apply -f test-deployment/nginx.yaml
```

```shell
kubectl delete deployment nginx && \
kubectl delete service nginx && \
kubectl delete ingress nginx
```

```shell 
kubectl apply -f test-deployment/csi-pvc-test
```

```shell
kubectl delete pod my-csi-app
kubectl delete pvc csi-pvc
# Check if PV was deleted too
kubectl get pv -A
'''