#!/bin/bash

deviceName=$1;
ipv4=$2;
host=$3;

if [ -z "$deviceName" ]; then
  echo "Device name is required!"
  exit 0
fi

if [ -z "$ipv4" ]; then
  echo "IP is required!"
  exit 0
fi

if [ -z "$host" ]; then
  echo "Host IP is required!"
  exit 0
fi

cd /etc/wireguard
umask 077

mkdir ${deviceName}

[ ! -d "./configs/" ] && mkdir configs

wg genkey | tee "./${deviceName}/${deviceName}.key" | wg pubkey > "./${deviceName}/${deviceName}.pub"
wg genpsk > "./${deviceName}/${deviceName}.psk"

echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $(cat "./${deviceName}/${deviceName}.pub")" >> /etc/wireguard/wg0.conf
echo "PresharedKey = $(cat "./${deviceName}/${deviceName}.psk")" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = ${ipv4}/32" >> /etc/wireguard/wg0.conf

sudo systemctl restart wg-quick@wg0

echo "[Interface]" > "./configs/${deviceName}.conf"
echo "Address = ${ipv4}/32" >> "./configs/${deviceName}.conf"
echo "DNS = 1.1.1.1" >> "./configs/${deviceName}.conf"
echo "PrivateKey = $(cat "./${deviceName}/${deviceName}.key")" >> "./configs/${deviceName}.conf"

echo "[Peer]" >> "./configs/${deviceName}.conf"
echo "AllowedIPs = 0.0.0.0/0" >> "./configs/${deviceName}.conf"
echo "Endpoint = ${host}:47111" >> "./configs/${deviceName}.conf"
echo "PersistentKeepalive = 25" >> "./configs/${deviceName}.conf"
echo "PublicKey = $(cat server.pub)" >> "./configs/${deviceName}.conf"
echo "PresharedKey = $(cat "./${deviceName}/${deviceName}.psk")" >> "./configs/${deviceName}.conf"

qrencode -t ansiutf8 -r "./configs/${deviceName}.conf"