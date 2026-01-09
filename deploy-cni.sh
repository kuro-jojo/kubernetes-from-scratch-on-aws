#!/bin/sh
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
