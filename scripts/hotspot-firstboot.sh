#!/bin/sh
# One-shot owner of runtime network/device settings, installed as /etc/uci-defaults/99-custom-config.
# OpenWrt removes this script after a successful exit. OpenNDS settings belong only in /etc/config/opennds.
set -eu

wlan_name="SEGALA TEKNIK"
wlan_password="takonobojoku"
root_password="enter"
host_name="SAMSUNG"
time_zone="WIB-7"
zone_name="Asia/Jakarta"
lan_ip_address="192.168.100.1"

# Resolve the generated radio/interface once; do not create a duplicate primary AP.
wireless_config="$(uci show wireless)"
radio="$(printf '%s\n' "$wireless_config" | sed -n 's/^wireless\.\([^=]*\)=wifi-device$/\1/p' | head -n 1)"
iface="$(printf '%s\n' "$wireless_config" | sed -n 's/^wireless\.\([^=]*\)=wifi-iface$/\1/p' | head -n 1)"
[ -n "$radio" ] || { logger -t 99-custom-config "No Wi-Fi radio found"; exit 1; }
if [ -z "$iface" ]; then
    iface="main_ap"
    uci -q set "wireless.$iface=wifi-iface"
fi

# Remove only sections that this script owns, then recreate them once in a batch.
for section in network.voucher dhcp.voucher wireless.hotspot firewall.voucher firewall.voucher_dhcp firewall.voucher_dns_udp firewall.voucher_dns_tcp firewall.voucher_wan network.wan6 dhcp.wan6; do
    uci -q delete "$section" || true
done

# Remove IPv6-only firewall rules by name; re-read after each delete because @rule indices shift.
while :; do
    section="$(uci show firewall | sed -n "/\\.name='Allow-DHCPv6[^']*'\\|\\.name='Allow-MLD'\\|\\.name='Allow-ICMPv6[^']*'/s/^\\(firewall\\.[^.]*\\)\\..*/\\1/p" | head -n 1)"
    [ -n "$section" ] || break
    uci -q delete "$section" || break
done

# Remove inherited IPv6 assignments and global ULA configuration.
uci -q delete network.lan.ip6assign || true
uci -q delete network.lan.ip6hint || true
uci -q delete network.lan.ip6ifaceid || true
uci -q delete network.globals.ula_prefix || true

uci -q batch <<EOF
set system.@system[0].hostname='$host_name'
set system.@system[0].timezone='$time_zone'
set system.@system[0].zonename='$zone_name'
set network.lan.proto='static'
set network.lan.ipaddr='$lan_ip_address'
set network.lan.netmask='255.255.255.0'
set network.wan.proto='dhcp'
set dhcp.lan.interface='lan'
set dhcp.lan.ignore='0'
set dhcp.lan.dhcpv6='disabled'
set dhcp.lan.ra='disabled'
set dhcp.lan.ndp='disabled'
set wireless.$radio.disabled='0'
set wireless.$radio.country='ID'
set wireless.$iface.device='$radio'
set wireless.$iface.mode='ap'
set wireless.$iface.network='lan'
set wireless.$iface.disabled='0'
set wireless.$iface.encryption='psk2'
set wireless.$iface.ssid='$wlan_name'
set wireless.$iface.key='$wlan_password'
set network.voucher='interface'
set network.voucher.type='bridge'
set network.voucher.proto='static'
set network.voucher.ipaddr='192.168.20.1'
set network.voucher.netmask='255.255.255.0'
set network.voucher.delegate='0'
set dhcp.voucher='dhcp'
set dhcp.voucher.interface='voucher'
set dhcp.voucher.start='100'
set dhcp.voucher.limit='150'
set dhcp.voucher.leasetime='1h'
set dhcp.voucher.dhcpv6='disabled'
set dhcp.voucher.ra='disabled'
set wireless.hotspot='wifi-iface'
set wireless.hotspot.device='$radio'
set wireless.hotspot.mode='ap'
set wireless.hotspot.network='voucher'
set wireless.hotspot.ssid='HOTSPOT'
set wireless.hotspot.encryption='none'
set wireless.hotspot.isolate='1'
set wireless.hotspot.disabled='0'
set firewall.voucher='zone'
set firewall.voucher.name='voucher'
set firewall.voucher.network='voucher'
set firewall.voucher.input='REJECT'
set firewall.voucher.output='ACCEPT'
set firewall.voucher.forward='REJECT'
set firewall.voucher_dhcp='rule'
set firewall.voucher_dhcp.name='Allow-Voucher-DHCP'
set firewall.voucher_dhcp.src='voucher'
set firewall.voucher_dhcp.proto='udp'
set firewall.voucher_dhcp.dest_port='67'
set firewall.voucher_dhcp.target='ACCEPT'
set firewall.voucher_dns_udp='rule'
set firewall.voucher_dns_udp.name='Allow-Voucher-DNS-UDP'
set firewall.voucher_dns_udp.src='voucher'
set firewall.voucher_dns_udp.proto='udp'
set firewall.voucher_dns_udp.dest_port='53'
set firewall.voucher_dns_udp.target='ACCEPT'
set firewall.voucher_dns_tcp='rule'
set firewall.voucher_dns_tcp.name='Allow-Voucher-DNS-TCP'
set firewall.voucher_dns_tcp.src='voucher'
set firewall.voucher_dns_tcp.proto='tcp'
set firewall.voucher_dns_tcp.dest_port='53'
set firewall.voucher_dns_tcp.target='ACCEPT'
set firewall.voucher_wan='forwarding'
set firewall.voucher_wan.src='voucher'
set firewall.voucher_wan.dest='wan'
EOF

# Keep the WAN firewall zone compatible with the active DHCP uplink and remove wan6 membership.
wan_zone="$(uci show firewall | sed -n "s/^\\(firewall\\.[^.]*\\)\\.name='wan'$/\\1/p" | head -n 1)"
if [ -n "$wan_zone" ]; then
    uci set "$wan_zone.network=wan wwan"
fi

# Set the root password once; the UCI defaults runner removes this script on success.
printf '%s\n%s\n' "$root_password" "$root_password" | passwd >/dev/null

# Persist all UCI changes in one commit.
uci commit
exit 0
