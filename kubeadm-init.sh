#!/bin/sh
IP=
sudo kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=$IP

# To make kubectl work for your non-root user
mkdir -p $HOME/.kube  && 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config  && 
sudo chown $(id -u):$(id -g) $HOME/.kube/config
