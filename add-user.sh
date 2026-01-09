#!/bin/sh
IP= # Load balancer (public) IP

openssl genrsa -out kuro.key 2048
openssl req -new -key kuro.key -out kuro.csr -subj "/CN=kuro"
cat kuro.csr | base64 | tr -d "\n" > kuro-base64.csr
cat <<EOF | tee csr.yaml -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: kuro
spec:
  request: $(cat kuro-base64.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 864000  # 10 days
  usages:
  - client auth
EOF
kubectl apply -f csr.yaml
kubectl certificate approve kuro


kubectl get csr/kuro -o jsonpath="{.status.certificate}" | base64 -d > kuro.crt
kubectl config set-cluster kubernetes --server=https://$IP:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig=kuro.conf
kubectl config set-credentials kuro --client-key=kuro.key --client-certificate=kuro.crt --embed-certs=true --kubeconfig=kuro.conf
kubectl config set-context kuro@kubernetes --cluster=kubernetes --user=kuro --kubeconfig=kuro.conf
kubectl config use-context kuro@kubernetes --kubeconfig=kuro.conf

kubectl auth can-i create pods --namespace=default --kubeconfig=kuro.conf -v 6


kubectl create role kuro-role --verb=create,get,list --resource=pods --namespace default
kubectl create rolebinding kuro-rolebinding --role=kuro-role --user=kuro --namespace default
