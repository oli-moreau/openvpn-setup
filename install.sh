#!/bin/bash

# Include the required functions
source lib/prompt.sh
source lib/serverSide.sh
source lib/clientSide.sh

# Set the current and log path
current_path=$(pwd)
log_path="$current_path/lib/log"
mkdir -p $log_path

# Start of the installation
message_start

echo "Setting up easy-rsa..."
easyrsa_setup &>$log_path/easyrsa_setup.txt

echo "Creating the vars file..."
create_vars_file

echo "Installing openvpn & ufw..."
base_install &>$log_path/base_install.txt

echo "Generating & signing certificates (this may take a while)..."
gen_sign &>/$log_path/gen_sign.txt

echo "Configuring the server..."
server_config

echo "IP forwarding..."
ip_forwarding &>$log_path/ip_forwarding.txt

echo "Configuring ufw..."
ufw_config &>$log_path/ufw_config.txt

echo "Starting service..."
service_start &>$log_path/service_start.txt

echo "Configuring client's ovpn file..."
client_config

echo "Generating client's ovpn file..."
sudo bash -c "$(declare -f generate_ovpn); generate_ovpn $(whoami)"

mv ~/client-configs/files/client1.ovpn ~/

# End of installation
message_end