#!/bin/bash

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