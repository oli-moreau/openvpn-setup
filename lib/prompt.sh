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

message_end() {
  width=$(tput cols)
  echo "$(printf '=%.0s' $(seq 1 $width))"
    center_text "OpenVPN installation complete"
    center_text "The client1.ovpn file is located in the ~/ folder"
    center_text "It may be required to configure or disable ufw in order to transfer the ovpn file"
  echo "$(printf '=%.0s' $(seq 1 $width))"
}