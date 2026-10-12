
#!/bin/bash
set -euo pipefail

# Harus dijalankan dari direktori source OpenWrt.
cd "$(dirname "$0")"

# Target perangkat
./scripts/config -e TARGET_ath79
./scripts/config -e TARGET_ath79_generic
./scripts/config -e TARGET_ath79_generic_DEVICE_tplink_tl-wr841hp-v3

# LuCI minimal
./scripts/config -e PACKAGE_luci
./scripts/config -e PACKAGE_luci-base
./scripts/config -e PACKAGE_luci-mod-admin-full
./scripts/config -e PACKAGE_luci-theme-bootstrap

# Wi-Fi QCA9533 / ath9k
./scripts/config -e PACKAGE_kmod-ath9k
./scripts/config -e PACKAGE_iw
./scripts/config -e PACKAGE_wireless-regdb

# OpenNDS: pilih paket jika tersedia pada feeds
./scripts/config -e PACKAGE_opennds

# Buang PPPoE
./scripts/config -d PACKAGE_ppp
./scripts/config -d PACKAGE_ppp-mod-pppoe
./scripts/config -d PACKAGE_kmod-pppoe

# Buang IPv6 dan DHCPv6
./scripts/config -d PACKAGE_odhcp6c
./scripts/config -d PACKAGE_odhcpd-ipv6only
./scripts/config -d PACKAGE_kmod-ipv6
./scripts/config -d PACKAGE_ip6tables
./scripts/config -d PACKAGE_ip6tables-extra

# Tidak perlu dukungan USB, diagnostik tambahan, atau tool berat
./scripts/config -d PACKAGE_usbutils
./scripts/config -d PACKAGE_tcpdump

# Terapkan dependensi pilihan paket.
make defconfig

# Konfigurasi default router: Wi-Fi aktif dan OpenNDS mati.
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom-config <<'EOF'
#!/bin/sh

# Aktifkan semua radio Wi-Fi yang tersedia.
uci -q show wireless | \
  sed -n 's/^\(wireless\.[^.]*\)=wifi-device$/\1/p' | \
  while read -r radio; do
    uci set "${radio}.disabled=0"
  done

# OpenNDS terpasang, tetapi tidak aktif saat boot.
if [ -x /etc/init.d/opennds ]; then
    /etc/init.d/opennds disable
    /etc/init.d/opennds stop || true
fi

uci commit wireless
exit 0
EOF

chmod 0755 files/etc/uci-defaults/99-custom-config
