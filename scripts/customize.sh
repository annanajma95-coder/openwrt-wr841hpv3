#!/bin/bash
set -euo pipefail

# Harus dijalankan dari direktori source OpenWrt.
cd "$(dirname "$0")"

# OpenWrt 19.07 tidak menyediakan executable ./scripts/config (path tersebut
# adalah direktori). Ubah simbol .config secara langsung, lalu jalankan defconfig.
config_enable() {
    local symbol="$1"
    sed -i "/^${symbol}=/d; /^# ${symbol} is not set$/d" .config
    printf '%s=y\n' "$symbol" >> .config
}

config_disable() {
    local symbol="$1"
    sed -i "/^${symbol}=/d; /^# ${symbol} is not set$/d" .config
    printf '# %s is not set\n' "$symbol" >> .config
}

# Target perangkat
config_enable CONFIG_TARGET_ath79
config_enable CONFIG_TARGET_ath79_generic
config_enable CONFIG_TARGET_ath79_generic_DEVICE_tplink_tl-wr841hp-v3

# LuCI minimal
config_enable CONFIG_PACKAGE_luci
config_enable CONFIG_PACKAGE_luci-base
config_enable CONFIG_PACKAGE_luci-mod-admin-full
config_enable CONFIG_PACKAGE_luci-theme-bootstrap

# Wi-Fi QCA9533 / ath9k
config_enable CONFIG_PACKAGE_kmod-ath9k
config_enable CONFIG_PACKAGE_iw
config_enable CONFIG_PACKAGE_wireless-regdb

# OpenNDS terpasang, tetapi dinonaktifkan saat boot oleh uci-defaults.
config_enable CONFIG_PACKAGE_opennds

# Buang PPPoE
config_disable CONFIG_PACKAGE_ppp
config_disable CONFIG_PACKAGE_ppp-mod-pppoe
config_disable CONFIG_PACKAGE_kmod-pppoe

# Buang IPv6 dan DHCPv6
config_disable CONFIG_PACKAGE_odhcp6c
config_disable CONFIG_PACKAGE_odhcpd-ipv6only
config_disable CONFIG_PACKAGE_kmod-ipv6
config_disable CONFIG_PACKAGE_ip6tables
config_disable CONFIG_PACKAGE_ip6tables-extra

# Tidak perlu dukungan USB, diagnostik tambahan, atau tool berat
config_disable CONFIG_PACKAGE_usbutils
config_disable CONFIG_PACKAGE_tcpdump

# LuCI protocol/kernel extras excluded from this lightweight image.
config_disable CONFIG_PACKAGE_luci-proto-ipv6
config_disable CONFIG_PACKAGE_luci-proto-ppp
config_disable CONFIG_PACKAGE_kmod-ip6tables
config_disable CONFIG_PACKAGE_kmod-ip6tables-extra

# Terapkan dependensi pilihan paket.
make defconfig

# Pastikan profil perangkat tidak terhapus oleh resolusi dependensi.
grep -qx 'CONFIG_TARGET_ath79_generic_DEVICE_tplink_tl-wr841hp-v3=y' .config || {
    echo "ERROR: profil TL-WR841HP v3 tidak aktif setelah make defconfig" >&2
    exit 1
}

