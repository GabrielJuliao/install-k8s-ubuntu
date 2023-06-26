#!/bin/bash

# KUBERNETES 1.26
# CONTAINERD 1.6.16
# UBUNTU 22.04 

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Prompt the user for control plane information
read -p "Are you running on a control plane? (y/n): " answer

# Convert the user's answer to lowercase for case-insensitive comparison
answer_lowercase="${answer,,}"

is_control_plane=false

if [[ $answer_lowercase == "yes" || $answer_lowercase == "y" ]]; then
    is_control_plane=true
fi

# ------ NEWTWORK CONFIG BEGIN ------
printf "Starting network configuriation...\n"
printf "overlay\nbr_netfilter\n" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter
printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" >> /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system
printf "Network configuration is done! If you want to use a multi node setup make sure hostnames are resolved to IP addresses.\nThis can be achieved by editing /etc/hosts"
# ------ NEWTWORK CONFIG END ------


# ------ INSTALL CONTAINERD BEGIN ------
wget https://github.com/containerd/containerd/releases/download/v1.6.16/containerd-1.6.16-linux-amd64.tar.gz -P /tmp/
tar Cxzvf /usr/local /tmp/containerd-1.6.16-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd

# dependencies >>
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -P /tmp/
install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz -P /tmp/
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-amd64-v1.2.0.tgz
# dependencies <<

# configuration >>
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
# configuration <<

# ------ INSTALL CONTAINERD END ------


# ------ INSTALL KUBERNETES BEGIN ------
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=1.26.1-00 kubeadm=1.26.1-00 kubectl=1.26.1-00
apt-mark hold kubelet kubeadm kubectl
# ------ INSTALL KUBERNETES END ------


# ------ INIT CONTROL PLANE BEGIN ------
if [[ $is_control_plane == true ]]; then

kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version 1.26.1
ufw allow 6783
ufw allow 6784

echo -e "Remember to run the below commands as a normal user.\n"
echo -e kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
echo -e "mkdir -p \$HOME/.kube"
echo -e "sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo -e "sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config\n"
echo -e
echo -e "Use the below command to generate the token for your workers node."
echo -e "kubeadm token create --print-join-command"

fi
# ------ INIT CONTROL PLANE END ------