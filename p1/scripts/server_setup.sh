#!/usr/bin/env bash

# Update package list and install necessary utilities.
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

# Save the K3s server node token to a file for use by other nodes.
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/server_token

# Wait for the node 'mkaddanis' to reach the "Ready" state.
kubectl wait --for=condition=Ready node/mkaddanis

# Display the list of nodes with detailed information.
sudo kubectl get nodes -o wide
