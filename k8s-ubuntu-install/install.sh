#!/bin/bash

# Disable UFW cause of Problems with Docker
sudo systemctl stop ufw.service
sudo systemctl disable ufw.service

sudo iptables -F
# Letting iptables see bridged traffic
test -e /etc/modules-load.d/k8s.conf || cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

test -e /etc/sysctl.d/k8s.conf || cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

# Update the apt package index and install packages needed to use the Kubernetes apt repository:
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo apt-get update
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Configure Containerd
sudo test -d /etc/containerd || sudo mkdir /etc/containerd
sudo test -e /etc/containerd/config.toml || sudo cat > /etc/containerd/config.toml <<EOF
disabled_plugins = ["cri"]

#root = "/var/lib/containerd"
#state = "/run/containerd"
#subreaper = true
#oom_score = 0

#[grpc]
#  address = "/run/containerd/containerd.sock"
#  uid = 0
#  gid = 0

#[debug]
#  address = "/run/containerd/debug.sock"
#  uid = 0
#  gid = 0
#  level = "info"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
EOF

# Install Docker
sudo test -d /etc/docker || sudo mkdir /etc/docker
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

## Set up stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

## Add Docker’s official GPG key:
sudo test -e /usr/share/keyrings/docker-archive-keyring.gpg || curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

## Install Docker Engine
sudo apt-get update
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io

## Start and enable Docker
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Disable SWAP
sudo sed -i~ /swap/d /etc/fstab

sudo test -d /etc/systemd/system/kubelet.service.d || sudo mkdir /etc/systemd/system/kubelet.service.d
sudo test -e etc/systemd/system/kubelet.service.d/20-hcloud.conf || sudo cat > etc/systemd/system/kubelet.service.d/20-hcloud.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF
# Install Kubeadm Kubectl & Kubelet
## Download the Google Cloud public signing key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

## Add the Kubernetes apt repository:
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

## Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo apt-get install -y kubelet=1.22.5-00 kubeadm=1.22.5-00 kubectl=1.22.5-00
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo apt-mark hold kubelet kubeadm kubectl

## Enable Kubelet
sudo systemctl enable --now kubelet