#!/usr/bin/env bash

# Update package list and install essential utilities.
sudo apt-get update
sudo apt-get install -y curl vim net-tools

# Add /sbin to the PATH for current session to access networking tools.
export PATH=$PATH:/sbin/

# Configure the network interface eth1 with the specified IP and netmask.
sudo ifconfig eth1 192.168.56.110 netmask 255.255.255.0 up

# Set the environment variable for the K3s configuration file location.
export K3S_CONFIG_FILE="/vagrant/confs/configS.yaml"

# Install K3s with the server role.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=server sh -

# ===============================================================================
# Wait for the K3s node 'mkaddanis' to be ready.
echo "[Log][mkaddaniS]: Waiting for the node to be ready"
sleep 10
kubectl wait --for=condition=Ready node/mkaddanis
# Alternatively, use the commented out loop to check node readiness.
# until kubectl get node mkaddanis | grep -i " Ready "; do sleep 1 ; done
# ===============================================================================

# Display all nodes with detailed information.
sudo kubectl get nodes -o wide

# ===============================================================================
# Install nginx-ingress controller.
# Reference: https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml
sleep 5

# Wait for the ingress endpoints to be ready.
while kubectl get endpoints -n ingress-nginx | grep '<none>' > /dev/null; do
  echo "Waiting for ingress endpoints to be ready..."
  sleep 1
done
echo "Endpoint is ready!"

# Display all resources in the ingress-nginx namespace.
kubectl get all -n ingress-nginx
kubectl get endpoints -n ingress-nginx

# Wait for the ingress deployment to be fully available.
while kubectl get deployment -n ingress-nginx | grep '0/1' > /dev/null; do
  echo "Waiting for ingress Deployment to be ready..."
  sleep 1
done
echo "Deployment is ready!"
# ===============================================================================

# Apply the application deployments and services.
kubectl apply -f /vagrant/confs/app1.yaml
kubectl apply -f /vagrant/confs/app2.yaml
kubectl apply -f /vagrant/confs/app3.yaml
# ===============================================================================

# Apply the Ingress configuration for all applications.
kubectl apply -f /vagrant/confs/ig-all.yml
