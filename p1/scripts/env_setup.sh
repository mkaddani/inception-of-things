#!/usr/bin/env bash

# This script installs Vagrant and VirtualBox on Debian 11 (Bullseye).

# Uncomment the following line if you need to install Git as well:
# sudo apt-get install -y git

# Install VirtualBox
# Reference: https://www.virtualbox.org/wiki/Linux_Downloads
# Use `hostnamectl` to confirm your Debian version (e.g., bullseye).

sudo apt-get update
sudo apt-get install -y wget curl

# Add the VirtualBox repository to your sources list.
sudo echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian bullseye contrib' >>  /etc/apt/sources.list

# Download and add the VirtualBox public key to your keyring.
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

# Update the package list and install VirtualBox.
sudo apt-get update
sudo apt-get install -y virtualbox-6.1

# Install Vagrant
# Reference: https://developer.hashicorp.com/vagrant/install
# Download and add the HashiCorp public key to your keyring.
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp repository to your sources list.
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update the package list and install Vagrant.
sudo apt update && sudo apt install -y vagrant
