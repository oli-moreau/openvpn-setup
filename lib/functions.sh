#!/bin/bash

center_text() {
    spaces=$(((width - ${#1}) / 2))
    printf "%*s%s%*s\n" $spaces "" "${1}" $spaces
}

message_start() {
  width=$(tput cols)
  echo "$(printf '=%.0s' $(seq 1 $width))"
    center_text "OpenVPN installation"
    center_text "Make sure that the user have sudo privileges!"
    center_text "Logs are in $log_path"
  echo "$(printf '=%.0s' $(seq 1 $width))"
}

easyrsa_setup() {
    sudo apt install -y easy-rsa
    mkdir ~/easy-rsa
    ln -s /usr/share/easy-rsa/* ~/easy-rsa/
    chmod 700 ~/easy-rsa
    cd ~/easy-rsa
    ./easyrsa init-pki
}

create_vars_file() {
    touch vars
    vars_content=("EASYRSA_REQ_COUNTRY" "EASYRSA_REQ_PROVINCE" "EASYRSA_REQ_CITY" "EASYRSA_REQ_ORG" "EASYRSA_REQ_EMAIL")
    for data in "${vars_content[@]}"; do
    read -p "${data//_/ }: " value
    while [[ -z "$value" ]]; do
        echo "Input cannot be empty"
        read -p "${data//_/ }: " value
    done
    echo "set_var $data    \"$value\"" >> vars
    done
    sed -i -e '$ a set_var EASYRSA_REQ_OU         "Community"' \
    -e '$ a set_var EASYRSA_ALGO           "ec"' \
    -e '$ a set_var EASYRSA_DIGEST         "sha512"' vars
}

base_install() {
    sudo apt install -y openvpn ufw
    mkdir -p ~/client-configs/keys
    chmod -R 700 ~/client-configs
}

gen_sign() {
    echo -e "\n" | ./easyrsa build-ca nopass
    echo -e "\n" | ./easyrsa gen-req server nopass
    sudo cp pki/private/server.key /etc/openvpn/
    echo 'yes' | ./easyrsa sign-req server server
    sudo cp pki/issued/server.crt /etc/openvpn/
    sudo cp pki/ca.crt /etc/openvpn/
    ./easyrsa gen-dh
    sudo openvpn --genkey secret ta.key
    sudo cp ta.key /etc/openvpn/
    sudo cp pki/dh.pem /etc/openvpn/
    echo -e "\n" | ./easyrsa gen-req client1 nopass
    cp pki/private/client1.key ~/client-configs/keys/
    echo 'yes' | ./easyrsa sign-req client client1
    cp pki/issued/client1.crt ~/client-configs/keys/
    sudo cp ta.key ~/client-configs/keys/
    sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/
}

server_config() {
    sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/
    sudo sed -i -e '/cipher AES-256-CBC/a auth SHA256' \
    -e 's/^;proto tcp$/proto tcp/' \
    -e 's/^proto udp$/;proto udp/' \
    -e 's/^port 1194$/port 443/' \
    -e 's/^dh dh2048.pem$/dh dh.pem/' \
    -e 's/^;user nobody$/user nobody/' \
    -e 's/^;group nogroup$/group nogroup/' \
    -e 's/^explicit-exit-notify 1$/explicit-exit-notify 0/' \
    -e 's/^;push "redirect-gateway def1 bypass-dhcp"$/push "redirect-gateway def1 bypass-dhcp"/' \
    -e 's/^;push "dhcp-option DNS 208.67.222.222"$/push "dhcp-option DNS 8.8.8.8"/' \
    -e 's/^;push "dhcp-option DNS 208.67.220.220"$/push "dhcp-option DNS 8.8.4.4"/' /etc/openvpn/server.conf
}

ip_forwarding() {
    sudo sed -i 's/^#net.ipv4.ip_forward=1$/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sudo sysctl -p
}

ufw_config() {
    # Ufw before rules
    sudo sed -i -e '$ a #' \
    -e '$ a # START OPENVPN RULES' \
    -e '$ a *nat' \
    -e '$ a :POSTROUTING ACCEPT [0:0] ' \
    -e '$ a -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE' \
    -e '$ a COMMIT' \
    -e '$ a # END OPENVPN RULES' /etc/ufw/before.rules

    # Ufw forward policy
    sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

    # Ufw allow rules
    sudo ufw allow 443/tcp
    sudo ufw allow OpenSSH
    sudo ufw reload
}

service_start() {
    sudo systemctl start openvpn@server
    sudo systemctl enable openvpn@server
}


client_config() {
    mkdir -p ~/client-configs/files
    IP=$(hostname -I | awk '{print $1}')
    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
    sudo sed -i -e '/cipher AES-256-CBC/a auth SHA256' \
    -e 's/^;proto tcp$/proto tcp/' \
    -e 's/^proto udp$/;proto udp/' \
    -e 's/^remote my-server-1 1194$/remote '"$IP"' 443/' \
    -e 's/^dh dh2048.pem$/dh dh.pem/' \
    -e 's/^;user nobody$/user nobody/' \
    -e 's/^;group nogroup$/group nobody/' \
    -e 's/^ca ca.crt$/#ca ca.crt/' \
    -e 's/^cert client.crt$/#cert client.crt/' \
    -e 's/^key client.key$/#key client.key/' \
    -e 's/^tls-auth ta.key 1$/#tls-auth ta.key 1/' \
    -e '$ a\key-direction 1' ~/client-configs/base.conf
}

generate_ovpn() {
    KEY_DIR=/home/${1}/client-configs/keys
    OUTPUT_DIR=/home/${1}/client-configs/files
    BASE_CONFIG=/home/${1}/client-configs/base.conf

    cat ${BASE_CONFIG} \
        <(echo -e '<ca>') \
        ${KEY_DIR}/ca.crt \
        <(echo -e '</ca>\n<cert>') \
        ${KEY_DIR}/client1.crt \
        <(echo -e '</cert>\n<key>') \
        ${KEY_DIR}/client1.key \
        <(echo -e '</key>\n<tls-auth>') \
        ${KEY_DIR}/ta.key \
        <(echo -e '</tls-auth>') \
        > ${OUTPUT_DIR}/client1.ovpn
}

message_end() {
  width=$(tput cols)
  echo "$(printf '=%.0s' $(seq 1 $width))"
    center_text "OpenVPN installation complete"
    center_text "The client1.ovpn file is located in the ~/ folder"
    center_text "It may be required to configure or disable ufw in order to transfer the ovpn file"
  echo "$(printf '=%.0s' $(seq 1 $width))"
}