#!/bin/sh
# First-boot hotspot configuration for OpenWrt 19.07.9.
# OpenNDS remains enabled; pre-auth clients cannot reach router administration.
set -eu

uci -q set system.@system[0].hostname='SAMSUNG'
uci -q set system.@system[0].zonename='Asia/Jakarta'
uci -q set system.@system[0].timezone='WIB-7'

# Set the root password. The build explicitly includes shadow-chpasswd.
command -v chpasswd >/dev/null 2>&1 || {
    logger -t hotspot-firstboot "ERROR: chpasswd is missing"
    exit 1
}
printf '%s\n' 'root:enter' | chpasswd

# Configure the primary management LAN. Keep the voucher network separate.
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.100.1'
uci set network.lan.netmask='255.255.255.0'
uci set dhcp.lan.interface='lan'
uci set dhcp.lan.ignore='0'

# Keep the protected SSID on the existing LAN network.
uci show wireless | sed -n 's/^wireless\.\([^=]*\)=wifi-device$/\1/p' |
while read -r radio; do
    [ -n "$radio" ] && uci -q set "wireless.$radio.disabled=0"
done
uci show wireless | sed -n 's/^wireless\.\([^=]*\)=wifi-iface$/\1/p' |
while read -r section; do
    [ -n "$section" ] || continue
    uci -q set "wireless.$section.network=lan"
    uci -q set "wireless.$section.mode=ap"
    uci -q set "wireless.$section.ssid=SEGALA TEKNIK"
    uci -q set "wireless.$section.encryption=psk2"
    uci -q set "wireless.$section.key=takonobojoku"
    uci -q set "wireless.$section.disabled=0"
done

# Separate IPv4 bridge and DHCP scope for captive-portal guests.
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

# Guest SSID has no Wi-Fi key; isolation is provided by the firewall/captive portal.
radio="$(uci show wireless | sed -n 's/^wireless\.\([^=]*\)=wifi-device$/\1/p' | head -n 1)"
[ -n "$radio" ] || exit 1
uci -q delete wireless.hotspot || true
uci set wireless.hotspot='wifi-iface'
uci set wireless.hotspot.device="$radio"
uci set wireless.hotspot.mode='ap'
uci set wireless.hotspot.network='voucher'
uci set wireless.hotspot.ssid='HOTSPOT'
uci set wireless.hotspot.encryption='none'
uci set wireless.hotspot.isolate='1'
uci set wireless.hotspot.disabled='0'

# Default-deny access from guests to the router; allow only DNS, DHCP, and portal.
uci -q delete firewall.voucher || true
uci set firewall.voucher='zone'
uci set firewall.voucher.name='voucher'
uci set firewall.voucher.network='voucher'
uci set firewall.voucher.input='REJECT'
uci set firewall.voucher.output='ACCEPT'
uci set firewall.voucher.forward='REJECT'

for rule in voucher_dhcp voucher_dns_udp voucher_dns_tcp voucher_portal; do
    uci -q delete "firewall.$rule" || true
done
uci set firewall.voucher_dhcp='rule'
uci set firewall.voucher_dhcp.name='Allow-Voucher-DHCP'
uci set firewall.voucher_dhcp.src='voucher'
uci set firewall.voucher_dhcp.proto='udp'
uci set firewall.voucher_dhcp.dest_port='67'
uci set firewall.voucher_dhcp.target='ACCEPT'

uci set firewall.voucher_dns_udp='rule'
uci set firewall.voucher_dns_udp.name='Allow-Voucher-DNS-UDP'
uci set firewall.voucher_dns_udp.src='voucher'
uci set firewall.voucher_dns_udp.proto='udp'
uci set firewall.voucher_dns_udp.dest_port='53'
uci set firewall.voucher_dns_udp.target='ACCEPT'

uci set firewall.voucher_dns_tcp='rule'
uci set firewall.voucher_dns_tcp.name='Allow-Voucher-DNS-TCP'
uci set firewall.voucher_dns_tcp.src='voucher'
uci set firewall.voucher_dns_tcp.proto='tcp'
uci set firewall.voucher_dns_tcp.dest_port='53'
uci set firewall.voucher_dns_tcp.target='ACCEPT'

uci set firewall.voucher_portal='rule'
uci set firewall.voucher_portal.name='Allow-OpenNDS-Portal'
uci set firewall.voucher_portal.src='voucher'
uci set firewall.voucher_portal.proto='tcp'
uci set firewall.voucher_portal.dest_port='2050'
uci set firewall.voucher_portal.target='ACCEPT'

# Guests may forward only to WAN; no guest-to-LAN forwarding is created.
uci -q delete firewall.voucher_wan || true
uci set firewall.voucher_wan='forwarding'
uci set firewall.voucher_wan.src='voucher'
uci set firewall.voucher_wan.dest='wan'

# OpenNDS must listen only on the voucher bridge and stay enabled.
uci -q set opennds.@opennds[0].enabled='1'
uci -q set opennds.@opennds[0].gatewayinterface='br-voucher'

# Remove permissive defaults (SSH, Telnet, HTTP/HTTPS to router) for unauthenticated guests.
uci -q delete opennds.@opennds[0].users_to_router || true
uci -q add_list opennds.@opennds[0].users_to_router='allow udp port 53'
uci -q add_list opennds.@opennds[0].users_to_router='allow tcp port 53'
uci -q add_list opennds.@opennds[0].users_to_router='allow udp port 67'
uci -q add_list opennds.@opennds[0].users_to_router='allow tcp port 2050'

uci commit system
uci commit wireless
uci commit network
uci commit dhcp
uci commit firewall
uci commit opennds
exit 0
