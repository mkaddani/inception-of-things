#!/usr/bin/env bash

# Update the package list and install essential utilities.
sudo apt-get update
sudo apt-get install -y curl vim net-tools

# Add /sbin to the PATH for the current session to access networking tools.
export PATH=$PATH:/sbin/

# Configure the network interface eth1 with the specified IP and netmask.
sudo ifconfig eth1 192.168.56.111 netmask 255.255.255.0 up

# Set the environment variable for the K3s agent configuration file location.
export K3S_CONFIG_FILE="/vagrant/confs/configSW.yaml"

# Install K3s with the agent role.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=agent sh -
