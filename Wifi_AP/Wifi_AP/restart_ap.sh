#!/bin/bash

killall hostapd
rm /var/lib/dhcp/dhcpd.leases
touch /var/lib/dhcp/dhcpd.leases
sleep 1
sudo hostapd /etc/hostapd/hostapd.conf -B
sleep 1
service dnsmasq restart
sleep 1
service isc-dhcp-server restart

