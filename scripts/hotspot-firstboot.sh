#!/bin/sh
# Installed by the workflow as /etc/uci-defaults/99-custom-config.
set -eu
wlan_name="SEGALA TEKNIK"
wlan_password="takonobojoku"
root_password="enter"
host_name="SAMSUNG"
time_zone="WIB-7"
zone_name="Asia/Jakarta"
lan_ip_address="192.168.100.1"

# OpenNDS is installed but deliberately disabled.
if [ -f /etc/config/opennds ]; then
    uci -q set opennds.@opennds[0].enabled='0'
    uci commit opennds
fi
if [ -x /etc/init.d/opennds ]; then
    /etc/init.d/opennds disable 2>/dev/null || true
    /etc/init.d/opennds stop 2>/dev/null || true
fi

# Set root password using BusyBox passwd.
if [ -n "$root_password" ]; then
    (echo "$root_password"; sleep 1; echo "$root_password") | passwd >/dev/null
fi

# Hostname and time.
uci set system.@system[0].hostname="$host_name"
uci set system.@system[0].timezone="$time_zone"
uci set system.@system[0].zonename="$zone_name"

# Management LAN.
uci set network.lan.proto='static'
uci set network.lan.ipaddr="$lan_ip_address"
uci set network.lan.netmask='255.255.255.0'
uci set dhcp.lan.interface='lan'
uci set dhcp.lan.ignore='0'

# LEDs; these names are retained from the requested configuration.
uci -q set system.led_power=led
uci -q set system.led_power.name='Power'
uci -q set system.led_power.sysfs='green:power'
uci -q set system.led_power.trigger='timer'
uci -q set system.led_power.delayon='500'
uci -q set system.led_power.delayoff='5000'
uci -q set system.led_wifi=led
uci -q set system.led_wifi.name='Wifi'
uci -q set system.led_wifi.sysfs='green:wifi'
uci -q set system.led_wifi.trigger='none'
uci -q set system.led_wifi.default='0'

# Primary protected WLAN.
radio="$(uci show wireless | sed -n 's/^wireless\.\([^=]*\)=wifi-device$/\1/p' | head -n 1)"
iface="$(uci show wireless | sed -n 's/^wireless\.\([^=]*\)=wifi-iface$/\1/p' | head -n 1)"
[ -n "$radio" ] || { logger -t 99-custom-config "No Wi-Fi radio found"; exit 1; }
if [ -z "$iface" ]; then
    uci set wireless.main_ap='wifi-iface'
    iface='main_ap'
fi
uci set "wireless.$radio.disabled=0"
uci set "wireless.$radio.country=ID"
uci set "wireless.$iface.device=$radio"
uci set "wireless.$iface.mode=ap"
uci set "wireless.$iface.network=lan"
uci set "wireless.$iface.disabled=0"
uci set "wireless.$iface.encryption=psk2"
uci set "wireless.$iface.ssid=$wlan_name"
uci set "wireless.$iface.key=$wlan_password"

# Separate guest WLAN / DHCP network. OpenNDS remains OFF, so vouchers are not enforced.
uci -q delete network.voucher || true
uci set network.voucher='interface'
uci set network.voucher.type='bridge'
uci set network.voucher.proto='static'
uci set network.voucher.ipaddr='192.168.20.1'
uci set network.voucher.netmask='255.255.255.0'
uci set network.voucher.delegate='0'
uci -q delete dhcp.voucher || true
uci set dhcp.voucher='dhcp'
uci set dhcp.voucher.interface='voucher'
uci set dhcp.voucher.start='100'
uci set dhcp.voucher.limit='150'
uci set dhcp.voucher.leasetime='1h'
uci set dhcp.voucher.dhcpv6='disabled'
uci set dhcp.voucher.ra='disabled'

uci -q delete wireless.hotspot || true
uci set wireless.hotspot='wifi-iface'
uci set wireless.hotspot.device="$radio"
uci set wireless.hotspot.mode='ap'
uci set wireless.hotspot.network='voucher'
uci set wireless.hotspot.ssid='HOTSPOT'
uci set wireless.hotspot.encryption='none'
uci set wireless.hotspot.isolate='1'
uci set wireless.hotspot.disabled='0'

# Restrict guests from router/LAN; allow DHCP/DNS and WAN forwarding.
uci -q delete firewall.voucher || true
uci set firewall.voucher='zone'
uci set firewall.voucher.name='voucher'
uci set firewall.voucher.network='voucher'
uci set firewall.voucher.input='REJECT'
uci set firewall.voucher.output='ACCEPT'
uci set firewall.voucher.forward='REJECT'
uci -q delete firewall.voucher_dhcp || true
uci set firewall.voucher_dhcp='rule'
uci set firewall.voucher_dhcp.name='Allow-Voucher-DHCP'
uci set firewall.voucher_dhcp.src='voucher'
uci set firewall.voucher_dhcp.proto='udp'
uci set firewall.voucher_dhcp.dest_port='67'
uci set firewall.voucher_dhcp.target='ACCEPT'
uci -q delete firewall.voucher_dns_udp || true
uci set firewall.voucher_dns_udp='rule'
uci set firewall.voucher_dns_udp.name='Allow-Voucher-DNS-UDP'
uci set firewall.voucher_dns_udp.src='voucher'
uci set firewall.voucher_dns_udp.proto='udp'
uci set firewall.voucher_dns_udp.dest_port='53'
uci set firewall.voucher_dns_udp.target='ACCEPT'
uci -q delete firewall.voucher_dns_tcp || true
uci set firewall.voucher_dns_tcp='rule'
uci set firewall.voucher_dns_tcp.name='Allow-Voucher-DNS-TCP'
uci set firewall.voucher_dns_tcp.src='voucher'
uci set firewall.voucher_dns_tcp.proto='tcp'
uci set firewall.voucher_dns_tcp.dest_port='53'
uci set firewall.voucher_dns_tcp.target='ACCEPT'
uci -q delete firewall.voucher_wan || true
uci set firewall.voucher_wan='forwarding'
uci set firewall.voucher_wan.src='voucher'
uci set firewall.voucher_wan.dest='wan'

# Remove WAN6 if it exists.
if uci -q get network.wan6 >/dev/null 2>&1; then
    uci delete network.wan6
fi

uci commit system
uci commit wireless
uci commit network
uci commit dhcp
uci commit firewall
uci commit opennds
exit 0
