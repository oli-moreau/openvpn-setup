# OpenVPN Installation Script for Debian 11

This Bash script provides an almost automatic installation of OpenVPN on a Debian 11 (Bullseye) server. The script is quite straightforward, making it a quick way to have a VPN server up and running.

It is based on [this excellent guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-debian-11) written by [Mark Drake](https://www.digitalocean.com/community/users/mdrake), [Justin Ellingwood](https://www.digitalocean.com/community/users/jellingwood) and [Kent Shultz](https://www.digitalocean.com/community/users/kshultz).

![Screenshot from 2023-01-29 19-53-07](https://user-images.githubusercontent.com/123499791/215366778-619d7ded-9644-46ca-8642-877fbe7fd0d7.png)

## Limitations
The only intent of this script is to provide a quick way to have a VPN server up and running for *my personnal use case*, which is on a Debian 11 server and a Fedora 37 Workstation.
- Not recommended due to security concerns with the server being its own CA (Certificate Authority).
- The server side was only configured & tested on Debian 11 (Bullseye).
- The client side was only configured & tested on Fedora 37 Workstation.
- Additional configuration might be required for Debian based or Arch based clients.

## Server-side Configuration
Default configuration file, with the following modifications:
- TCP instead of UDP
- Port 443 instead of 1194
- Added auth SHA256
- dh dh2048.pem set to dh dh.pem
- User nobody & group nogroup
- explicit-exit-notify set to 0 due to TCP
- Using Google's DNS (both 8.8.8.8 and 8.8.4.4)
- Server acts as its own Certificate Authority (CA) server

## Client-side Configuration
Default configuration file, with the following modifications:
- TCP instead of UDP
- Port 443 instead of 1194
- Added auth SHA256
- dh dh2048.pem set to dh dh.pem
- User nobody & group nobody
- CA, cert and key files are commented
- Commented tls-auth ta.key
- Added key-direction 1

## Requirements
- Debian 11 (Bullseye) server
- Port 443 must not be used
- Have a user with sudo privileges

## How to use
Download the files
```bash
$ git clone https://github.com/oli-moreau/openvpn-setup.git
```
Change directory
```bash
$ cd openvpn-setup/
```
Make the installation script executable
```bash
$ chmod +x install.sh
```
Run the script
```bash
$ ./install.sh
```
