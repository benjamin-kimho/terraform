#!/bin/bash

read -p "Network Interface: " netIface

if [ -z "$netIface"]; then
  echo "Network Interface is required!"
  exit 0
fi

printf "\n\nInstalling Wireguard...\n";
sudo apt-get -y update &&
sudo apt-get -y install wireguard wireguard-tools wireguard-dkms qrencode\
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release &&

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&

sudo apt-get -y update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io && sudo usermod -aG docker $USER &&
sudo systemctl enable docker.service && sudo systemctl enable containerd.service &&

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
sudo chmod +x /usr/local/bin/docker-compose &&



printf "\n\nEnabling IP forwarding...\n" &&
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf &&
sudo sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf &&
sudo sysctl -p &&



printf "\n\nCreating server key...\n" &&
sudo chown $USER /etc/wireguard &&
rm -rf /etc/wireguard/* &&
cd /etc/wireguard &&
umask 077 &&

wg genkey | tee server.key | wg pubkey > server.pub &&
touch /etc/wireguard/wg0.conf &&

echo "[Interface]" >> wg0.conf &&
echo "Address = 10.100.0.1/24" >> wg0.conf &&
echo "ListenPort = 47111" >> wg0.conf &&
echo "PrivateKey = $(cat server.key)" >> wg0.conf &&
echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${netIface} -j MASQUERADE" >> wg0.conf &&
echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${netIface} -j MASQUERADE" >> wg0.conf &&



printf "\n\nStarting Wireguard service...\n" &&
sudo systemctl enable wg-quick@wg0.service &&
sudo systemctl daemon-reload &&
sudo systemctl start wg-quick@wg0 &&



printf "\n\nConfiguring firewall...\n" &&
sudo ufw allow ssh &&
sudo ufw allow 80/tcp &&
sudo ufw allow 53/tcp &&
sudo ufw allow 53/udp &&
sudo ufw allow 67/udp &&
sudo ufw allow 47111/udp &&



printf "\n\nEnabling Firewall...\n" &&
sudo ufw --force enable &&

printf "\n\nRebooting...\n" &&
sudo reboot