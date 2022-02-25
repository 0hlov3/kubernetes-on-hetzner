#!/bin/bash

export DEBIAN_FRONTEND="noninteractive"
export KUBERNETES_VERSION="1.22.6-00"
export DPKG_LOCK_TIMOUT="-1"

#############################################
# Disable UFW cause of Problems with Docker #
#############################################
echo '> Disable ufw and purge iptables ...'
sudo systemctl stop ufw.service
sudo systemctl disable ufw.service
sudo iptables -F

########################################
# Letting iptables see bridged traffic #
########################################
echo '> Letting iptables see bridged traffic ...'
test -e /etc/modules-load.d/k8s.conf || cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

test -e /etc/sysctl.d/k8s.conf || cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

#################################################################
# Installs packages needed to use the Kubernetes apt repository #
#################################################################
echo '> Installs packages needed to use the Kubernetes apt repository  ...'
sudo apt-get -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} update
sudo apt-get -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} install -y apt-transport-https ca-certificates curl gnupg lsb-release

####################################
# Configures Containerd #
####################################
echo '> Configure Containerd ...'
sudo test -d /etc/containerd || sudo mkdir /etc/containerd
sudo test -e /etc/containerd/config.toml || sudo cat > /etc/containerd/config.toml <<EOF
disabled_plugins = ["cri"]

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
EOF

#################
# Install Docker#
#################
echo '> Configure Docker ...'
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

##############################
## Set up stable repository ##
##############################
echo '> Set up stable Docker repository ...'
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

####################################
## Add Docker’s official GPG key: ##
####################################
sudo test -e /usr/share/keyrings/docker-archive-keyring.gpg || curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
################################
# Update the apt package index #
################################
echo '> Update the apt package index ...'
sudo apt-get -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} update
###########################
## Install Docker Engine ##
##########################
echo '> Install Docker Engine ...'
sudo apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} install -y docker-ce docker-ce-cli containerd.io

#############################
## Start and enable Docker ##
#############################
echo '> Start and enable Docker ...'
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

################
# Disable SWAP #
################
echo '> Disable SWAP ...'
sudo sed -i~ /swap/d /etc/fstab

#####################
# Configure Kubelet #
#####################
sudo test -d /etc/systemd/system/kubelet.service.d || sudo mkdir /etc/systemd/system/kubelet.service.d
sudo test -e /etc/systemd/system/kubelet.service.d/20-hcloud.conf || sudo cat > /etc/systemd/system/kubelet.service.d/20-hcloud.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF

###################################################
# Install Kubeadm Kubectl & Kubelet               #
###################################################
## Download the Google Cloud public signing key: ##
###################################################
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

########################################
## Add the Kubernetes apt repository: ##
########################################
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

############################################################################################
## Update apt package index, install kubelet, kubeadm and kubectl, and pin their version: ##
############################################################################################
sudo apt-get -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} update
sudo apt-get -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} install -y kubelet=${KUBERNETES_VERSION} kubeadm=${KUBERNETES_VERSION} kubectl=${KUBERNETES_VERSION}
sudo apt-mark -o DPkg::Lock::Timeout=${DPKG_LOCK_TIMOUT} hold kubelet kubeadm kubectl

####################
## Enable Kubelet ##
####################
sudo systemctl enable --now kubelet