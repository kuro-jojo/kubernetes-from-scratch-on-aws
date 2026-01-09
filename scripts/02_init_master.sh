#!/bin/sh

echo "======= Initialize the cluster ======="

IP=

if [ -n $IP ];then
	echo "Please update the IP variable (the controle plane endpoint IP)"
	exit 1
fi

sudo kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=$IP

# To make kubectl work for your non-root user
mkdir -p $HOME/.kube  && 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config  && 
sudo chown $(id -u):$(id -g) $HOME/.kube/config


echo "======= Deploy a Container Network Interface (flannel)======="

# To install flannel as the CNI

ARCH=$(uname -m)
  case $ARCH in
    armv7*) ARCH="arm";;
    aarch64) ARCH="arm64";;
    x86_64) ARCH="amd64";;
  esac
mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-$ARCH-v1.7.1.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-$ARCH-v1.7.1.tgz


kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "========== Now you can join a worker node to the master by running the join command output ========"

echo "or run the following"

HASH=$(sudo cat /etc/kubernetes/pki/ca.crt | openssl x509 -pubkey  | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //')
TOKEN=$(kubeadm token list | awk {'if(NR==2) print $1'})
echo "sudo kubeadm join 10.0.0.8:6443 --token $TOKEN \
	--discovery-token-ca-cert-hash sha256:$HASH  \
	--cri-socket unix:///var/run/cri-dockerd.sock"

