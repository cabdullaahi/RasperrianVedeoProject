#!/bin/bash
### met en place le point d'accès WiFi
sudo apt-get update 
#sudo apt-get upgrade 
sudo apt-get install alsa pulseaudio ssvnc vlc sm unclutter 
# configuration statique de l'interface WiFi

echo ">>> Configuration statique de l'interface WiFi..."
echo "
auto wlan0
iface wlan0 inet static
address 192.168.3.1
netmask 255.255.255.0
network 192.168.3.0
broadcast 192.168.3.255

pre-up iptables-restore < /home/pi/.iptables.txt" >> /etc/network/interfaces


# installation des paquets
echo ">>> Installation des paquets..."
apt-get install hostapd isc-dhcp-server dnsmasq iptables 


# remplacement des binaires de hostapd par ceux qu'on a compilés
#echo ">>> Remplacement des binaires de hostapd..."
#apt-get remove -y hostapd
#cp sbin/hostapd /usr/sbin/
#cp sbin/hostapd_cli /usr/sbin/


# copie des fichiers de configurations de dhcpd
echo ">>> Configuration de dhcpd..."
cp etc/dhcpd.conf /etc/dhcp/
cp etc/isc-dhcp-server /etc/default


# copie des fichiers de configurations de hostapd avec le bon hostname
HOSTNAME="$(hostname)"
echo ">>> Configuration de hostapd avec le ssid $HOSTNAME..."
#sed -i "s/\(ssid=\).*/\1$HOSTNAME/" etc/hostapd.conf
cp etc/hostapd.conf /etc/hostapd/
cp etc/hostapd /etc/default


# activation de l'ip forwarding
echo ">>> Activation de l'ip_forwarding..."
FORWARD="net.ipv4.ip_forward=1"
sed -i "s/\(#$FORWARD\).*/$FORWARD/" /etc/sysctl.conf


# activation du module Mascarade (NAT) et configuration de iptables
echo ">>> Configuration de iptables..."
modprobe ipt_MASQUERADE
iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
iptables -A FORWARD --match state --state RELATED,ESTABLISHED --jump ACCEPT
iptables -A FORWARD -i wlan0 --destination 192.168.1.0/24 --match state --state NEW --jump ACCEPT
iptables -A INPUT -s 192.168.3.0/24 --jump ACCEPT
iptables-save > /home/pi/.iptables.txt


# copie du script de restart de l'AP
echo ">>> Copie du script de restart de l'AP..."
cp restart_ap.sh /home/pi/.restart_ap.sh

