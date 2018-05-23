#!/bin/bash

# References
# https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/

# Create private keys for users
mkdir -p certificates

for user in jsalmeron juan dbarranco; do
  openssl genrsa -out certificates/$user.key 2048
done

# Create CSR for users with proper group membership

#jsalmeron - groups: tech-lead,dev
openssl req -new -key certificates/jsalmeron.key -subj "/CN=jsalmeron/O=tech-lead/O=dev" -out certificates/jsalmeron.csr
#juan - groups: dev, api
openssl req -new -key certificates/juan.key -subj "/CN=juan/O=dev/O=api" -out certificates/juan.csr
#dbarranco - groups: sre
openssl req -new -key certificates/dbarranco.key -subj "/CN=dbarranco/O=sre" -out certificates/dbarranco.csr

# Send requests to server
cat <<EOF | tee jsalmeron-csr.yaml | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: jsalmeron
spec:
  groups:
  - tech-lead
  - dev
  request: $(cat certificates/jsalmeron.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
cat <<EOF | tee juan-csr.yaml | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: juan
spec:
  groups:
  - api
  - dev
  request: $(cat certificates/juan.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
cat <<EOF | tee dbarranco-csr.yaml | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: dbarranco
spec:
  groups:
  - sre
  request: $(cat certificates/dbarranco.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

# Approve CSRs
kubectl certificate approve jsalmeron dbarranco juan

# Fetch certificates
for user in jsalmeron juan dbarranco; do
  kubectl get csr $user -o jsonpath='{.status.certificate}' | base64 --decode > certificates/$user.crt
done

# Setup kube config
ADMIN_KUBECONFIG=$KUBECONFIG
for user in jsalmeron juan dbarranco; do
  export KUBECONFIG=kubecfg-$user
  kubectl config set-cluster session03 --embed-certs=true --certificate-authority=ca.crt --server=https://54.167.167.9:6443
  kubectl config set-credentials $user --client-certificate=certificates/$user.crt --client-key=certificates/$user.key --embed-certs=true
  kubectl config set-context $user-session03-context --cluster=session03 --user=$user
  kubectl config use-context $user-session03-context
done
export KUBECONFIG=$ADMIN_KUBECONFIG

# Set permissions with roles
#
# # Create namespaces
kubectl create ns team-vision
kubectl create ns team-api

# Apply roles / rolebindings

kubectl create -f roles.yaml
kubectl create -f rolebindings.yaml

# Apply quotas and limits

kubectl create -f quotas.yaml
kubectl create -f limits.yaml
