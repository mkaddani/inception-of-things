#!/usr/bin/env bash

# Part Three: Setting up the K3D cluster and ArgoCD

# Create a K3D cluster and configure kubeconfig for kubectl access
echo "===============================[K3D mkaddani-cluster set-up]========================================="
k3d cluster create mkaddani-cluster \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  --servers 1 \
  --agents 7

k3d kubeconfig merge mkaddani-cluster --kubeconfig-switch-context
kubectl get pods --all-namespaces

# Create Namespaces for soft isolation
echo "===============================[K3D mkaddani-cluster Create NameSpaces]=============================="
kubectl create ns argocd
kubectl create ns dev
kubectl get namespaces

# Apply the ArgoCD manifest
echo "===============================[Install ArgoCD]=============================="
# Install ArgoCD using the provided manifest
kubectl apply -n argocd -f ../confs/argocd.install.yaml

# Wait for ArgoCD endpoints to be ready
while kubectl get endpoints -n argocd | grep '<none>' > /dev/null; do
  echo "Waiting for ArgoCD endpoints to be ready..."
  sleep 1
done
echo "Endpoint is ready!"

# Expose ArgoCD via Ingress
echo "Exposing ArgoCD via ingress"
kubectl apply -f ../confs/ingress.argocd.yaml

# Wait until ArgoCD is accessible via localhost
echo "Waiting for ArgoCD at localhost:8080/argocd"
while true; do
  if curl -L -s -o /dev/null -w "%{http_code}\n" localhost:8080/argocd | grep -q '200'; then
    echo "ArgoCD is up!"
    break  # Exit the loop if the link is accessible
  else
    echo "ArgoCD ..."
  fi
  sleep 5  # Wait for 5 seconds before the next check
done
echo 'Use localhost:8080/argocd'

# Apply app1 ArgoCD configuration
kubectl apply -f ../confs/app1.argocd.yaml

# Expose application via Ingress
echo "Exposing WillApp via ingress"
kubectl apply -f ../confs/ingress.willapp.yaml
echo 'Use localhost:8080/'

# Display ArgoCD credentials
echo "==========================[ArgoCD]=================================="
echo "Please use these credentials:"
echo "ArgoCD user: admin"
echo "ArgoCD password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo '====================================================================='

# Optional: Clean up and delete the cluster (Uncomment to use)
# k3d cluster delete mkaddani-cluster --verbose
