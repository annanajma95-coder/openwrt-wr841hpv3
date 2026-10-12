#!/bin/sh

VOUCHER_FILE="/etc/opennds/vouchers"
COOLDOWN_FILE="/tmp/mac_cooldown"
LOG_FILE="/tmp/voucher.log"
LOCK="/tmp/opennds-voucher.lock"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
}

show_form() {
    cat <<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Cache-Control" content="no-cache,no-store,must-revalidate">
<title>Segala Teknik - Hotspot Voucher</title>
<style>
body {
    background: #111827;
    color: #1e293b;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    margin: 0;
    padding: 20px;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    box-sizing: border-box;
}
.card {
    background: #ffffff;
    width: 100%;
    max-width: 420px;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 15px 35px rgba(0,0,0,0.4);
    position: relative;
}
.accent-bar {
    background: #f97316;
    height: 10px;
    width: 100%;
}
.card-body {
    padding: 25px 30px 30px 30px;
    text-align: center;
}
.header-icon {
    font-size: 36px;
    margin-bottom: 5px;
}
.title {
    font-size: 22px;
    font-weight: 800;
    color: #1e293b;
    margin: 0 0 5px 0;
    letter-spacing: 0.5px;
}
.subtitle {
    font-size: 12px;
    font-weight: 700;
    color: #f97316;
    letter-spacing: 1.2px;
    margin-bottom: 20px;
    text-transform: uppercase;
}
.services-box {
    border: 1px dashed #cbd5e1;
    border-radius: 12px;
    padding: 12px 15px;
    margin-bottom: 20px;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 6px 10px;
    text-align: left;
    font-size: 12px;
    color: #334155;
    background: #f8fafc;
}
input[type="text"] {
    width: 100%;
    padding: 14px;
    margin-bottom: 12px;
    border-radius: 10px;
    border: 1px solid #cbd5e1;
    font-size: 15px;
    text-align: center;
    box-sizing: border-box;
    background: #f8fafc;
    color: #1e293b;
    font-weight: 700;
    outline: none;
    transition: all 0.2s;
}
input[type="text"]:focus {
    border-color: #2563eb;
    background: #ffffff;
    box-shadow: 0 0 0 3px rgba(37,99,235,0.1);
}
input[type="text"]::placeholder {
    color: #94a3b8;
    font-weight: 600;
}
.btn-login {
    width: 100%;
    padding: 14px;
    border: 0;
    border-radius: 10px;
    background: #2b3748;
    color: white;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    margin-bottom: 12px;
    transition: background 0.2s;
    box-sizing: border-box;
}
.btn-login:hover {
    background: #1e293b;
}
.btn-wa {
    display: block;
    width: 100%;
    padding: 14px;
    background: #22c55e;
    color: #ffffff;
    text-decoration: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 700;
    box-sizing: border-box;
    margin-bottom: 20px;
    transition: background 0.2s;
    text-align: center;
}
.btn-wa:hover {
    background: #16a34a;
}
.divider {
    border: 0;
    border-top: 1px solid #e2e8f0;
    margin: 20px 0 15px 0;
}
.footer-title {
    font-size: 13px;
    font-weight: 700;
    color: #475569;
    margin-bottom: 2px;
}
.footer-desc {
    font-size: 11px;
    color: #64748b;
}
</style>
</head>
<body>
<div class="card">
<div class="accent-bar"></div>
<div class="card-body">
<div class="header-icon">🛠️</div>
<h1 class="title">SEGALA TEKNIK</h1>
<div class="subtitle">ALL IN ONE SERVICE SOLUTIONS</div>

<div class="services-box">
    <div>✓ Laptop / Notebook</div>
    <div>✓ Komputer / PC</div>
    <div>✓ TV / LED</div>
    <div>✓ Mesin Cuci</div>
    <div>✓ Kipas Angin</div>
    <div>✓ Magiccom / Rice Cooker</div>
    <div>✓ Dispenser</div>
    <div>✓ Setrika / Mixer</div>
    <div>✓ Blender / Oven</div>
    <div>✓ Elektronik Lainnya</div>
</div>

<form method="get">
<input type="hidden" name="clientip" value="$1">
<input type="text" name="voucher" placeholder="MASUKKAN VOUCHER" autocomplete="off" required>
<button type="submit" class="btn-login">HUBUNGKAN WIFI</button>
</form>

<a href="https://wa.me/628970000120" class="btn-wa" target="_blank">💬 HUBUNGI KAMI (WA)</a>

<hr class="divider">
<div class="footer-title">SEGALA TEKNIK</div>
<div class="footer-desc">Servis IT & Peralatan Rumah Tangga</div>
</div>
</div>
</body>
</html>
HTML
}

show_msg() {
    icon="$1"
    title_class="$2"
    title_text="$3"
    msg1="$4"
    msg2="$5"
    msg3="$6"
    action_btn="$7"
    cat <<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Cache-Control" content="no-cache,no-store,must-revalidate">
<title>Segala Teknik - Hotspot Voucher</title>
<style>
body {
    background: #111827;
    color: #1e293b;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    margin: 0;
    padding: 20px;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    box-sizing: border-box;
}
.card {
    background: #ffffff;
    width: 100%;
    max-width: 420px;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 15px 35px rgba(0,0,0,0.4);
    position: relative;
}
.accent-bar {
    background: #f97316;
    height: 10px;
    width: 100%;
}
.card-body {
    padding: 25px 30px 30px 30px;
    text-align: center;
}
.header-icon {
    font-size: 36px;
    margin-bottom: 5px;
}
.ok {
    color: #22c55e;
    font-size: 20px;
    font-weight: bold;
    margin: 10px 0;
}
.err {
    color: #ef4444;
    font-size: 18px;
    font-weight: bold;
    margin: 10px 0;
}
p {
    color: #475569;
    font-size: 14px;
    line-height: 1.5;
}
.btn-back {
    display: block;
    width: 100%;
    padding: 14px;
    background: #2b3748;
    color: #ffffff;
    text-decoration: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 700;
    box-sizing: border-box;
    margin-top: 20px;
    text-align: center;
    transition: background 0.2s;
    border: none;
    cursor: pointer;
}
.btn-back:hover {
    background: #1e293b;
}
.btn-wa {
    display: block;
    width: 100%;
    padding: 14px;
    background: #22c55e;
    color: #ffffff;
    text-decoration: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 700;
    box-sizing: border-box;
    margin-top: 20px;
    transition: background 0.2s;
    text-align: center;
}
.btn-wa:hover {
    background: #16a34a;
}
</style>
</head>
<body>
<div class="card">
<div class="accent-bar"></div>
<div class="card-body">
<div class="header-icon">$icon</div>
<h2 class="$title_class">$title_text</h2>
<p>$msg1</p>
<p>$msg2</p>
<p>$msg3</p>
$action_btn
</div>
</div>
</body>
</html>
HTML
}

# =========================================================
# INPUT DARI OPENNDS
# =========================================================

RAW="$1"

log "RAW=$RAW"

# ---------------------------------------------------------
# URL DECODE
# ---------------------------------------------------------

urldecode() {
    printf '%s' "$1" |
    sed 's/+/ /g; s/%3[Ff]/?/g; s/%3[Dd]/=/g; s/%2[Cc]/,/g; s/%20/ /g; s/%3[Aa]/:/g; s/%2[Ff]/\//g; s/%25/%/g'
}

DATA="$(urldecode "$RAW")"

log "DECODED=$DATA"

# =========================================================
# PARSER FORMAT OPENNDS
# =========================================================

clientip="$(echo "$DATA" |
    sed -n 's/.*[? ]clientip=\([^,]*\).*/\1/p' |
    head -n 1)"

gatewayname="$(echo "$DATA" |
    sed -n 's/.*gatewayname=\([^,]*\).*/\1/p' |
    head -n 1)"

redir="$(echo "$DATA" |
    sed -n 's/.*redir=\([^,]*\).*/\1/p' |
    head -n 1)"

voucher="$(echo "$DATA" |
    sed -n 's/.*voucher=\([^,]*\).*/\1/p' |
    head -n 1)"

clientip="$(echo "$clientip" | sed 's/^ *//;s/ *$//')"
voucher="$(echo "$voucher" | sed 's/^ *//;s/ *$//')"
voucher="$(echo "$voucher" | tr 'a-z' 'A-Z')"

log "PARSED clientip=[$clientip] voucher=[$voucher] redir=[$redir]"

# =========================================================
# CLIENT IP WAJIB ADA
# =========================================================

if [ -z "$clientip" ]; then
    log "ERROR clientip kosong"
    show_msg "⚠️" "err" "Client tidak ditemukan" "Parameter client dari openNDS tidak diterima." "Silakan tutup halaman captive portal lalu sambungkan kembali WiFi." "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
    exit 0
fi

# =========================================================
# TAMPILKAN FORM
# =========================================================

if [ -z "$voucher" ]; then
    show_form "$clientip"
    exit 0
fi

# =========================================================
# VALIDASI VOUCHER
# =========================================================

case "$voucher" in
    *[!A-Z0-9-]*|"")
        log "INVALID FORMAT voucher=[$voucher]"
        show_msg "❌" "err" "Kode voucher tidak valid" "Gunakan kode voucher yang benar." "" "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
        exit 0
        ;;
esac

# =========================================================
# FILE VOUCHER
# =========================================================

if [ ! -f "$VOUCHER_FILE" ]; then
    log "ERROR file voucher tidak ada"
    show_msg "❌" "err" "Voucher tidak tersedia" "File voucher tidak ditemukan." "" "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
    exit 0
fi

# =========================================================
# CARI VOUCHER
# =========================================================

line="$(grep "^${voucher}|" "$VOUCHER_FILE" | head -n 1)"

if [ -z "$line" ]; then
    log "VOUCHER NOT FOUND voucher=$voucher"
    show_msg "❌" "err" "Voucher tidak ditemukan" "Kode voucher salah atau tidak tersedia." "" "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
    exit 0
fi

# =========================================================
# AMBIL DURASI DAN RATE LIMIT
# =========================================================

duration="$(echo "$line" | cut -d'|' -f2)"
upload_rate="$(echo "$line" | cut -d'|' -f3)"
download_rate="$(echo "$line" | cut -d'|' -f4)"

case "$duration" in
    ''|*[!0-9]*)
        log "INVALID DURATION voucher=$voucher duration=$duration"
        show_msg "❌" "err" "Durasi voucher tidak valid" "" "" "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
        exit 0
        ;;
esac

case "$upload_rate" in
    ''|*[!0-9]*) upload_rate=0 ;;
esac

case "$download_rate" in
    ''|*[!0-9]*) download_rate=0 ;;
esac

minutes=$((duration / 60))

if [ "$minutes" -lt 1 ]; then
    minutes=1
fi

log "VOUCHER OK voucher=$voucher client=$clientip duration=$duration minutes=$minutes"

# =========================================================
# LOCK & AMBIL MAC ADDRESS CLIENT
# =========================================================

while ! mkdir "$LOCK" 2>/dev/null
do
    sleep 1
done

trap 'rmdir "$LOCK" 2>/dev/null' 0 1 2 3 15

CLIENT_JSON="$(ndsctl json "$clientip" 2>/dev/null)"
log "CLIENT_JSON=$CLIENT_JSON"

if [ -z "$CLIENT_JSON" ]; then
    log "ERROR client tidak ditemukan ip=$clientip"
    rmdir "$LOCK" 2>/dev/null
    show_msg "⚠️" "err" "Client tidak ditemukan" "Client belum terdaftar di openNDS." "Silakan tutup captive portal dan buka kembali." "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
    exit 0
fi

client_mac="$(echo "$CLIENT_JSON" | sed -n 's/.*"mac"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr 'A-Z' 'a-z')"
log "CLIENT_MAC=$client_mac"

# =========================================================
# CEK MASA TUNGGU (COOLDOWN) MAC ADDRESS DI /tmp
# =========================================================

now_epoch=$(date +%s)

if [ -n "$client_mac" ] && [ -f "$COOLDOWN_FILE" ]; then
    blocked_until="$(grep "^${client_mac}|" "$COOLDOWN_FILE" | head -n 1 | cut -d'|' -f2)"
    if [ -n "$blocked_until" ] && [ "$now_epoch" -lt "$blocked_until" ]; then
        rem_sec=$((blocked_until - now_epoch))
        rem_min=$((rem_sec / 60))
        rem_h=$((rem_min / 60))
        rem_m=$((rem_min % 60))
        
        log "MAC COOLDOWN ACTIVE mac=$client_mac remaining_sec=$rem_sec"
        rmdir "$LOCK" 2>/dev/null
        
        show_msg "⏳" "err" "Masa Tunggu Aktif" "Perangkat Anda masih dalam masa cooldown setelah jatah akses habis." "Sisa waktu tunggu: <b>$rem_h Jam $rem_m Menit</b> lagi." "Silakan coba kembali setelah waktu habis." '<button onclick="history.back()" class="btn-back">KEMBALI</button>'
        exit 0
    fi
fi

# =========================================================
# AUTHENTICATE DENGAN SPEED LIMIT
# =========================================================

log "AUTH START ip=$clientip minutes=$minutes up=$upload_rate down=$download_rate"

AUTH_OUTPUT="$(ndsctl auth "$clientip" "$minutes" "$upload_rate" "$download_rate" 0 0 2>&1)"
AUTH_EXIT=$?

log "AUTH EXIT=$AUTH_EXIT"
log "AUTH OUTPUT=$AUTH_OUTPUT"

# =========================================================
# AUTH BERHASIL
# =========================================================

if [ "$AUTH_EXIT" -eq 0 ]; then
    sleep 1
    STATUS="$(ndsctl json "$clientip" 2>/dev/null)"
    log "POST AUTH STATUS=$STATUS"

    if echo "$STATUS" | grep -q '"state":"Authenticated"'; then
        log "AUTH SUCCESS ip=$clientip voucher=$voucher mac=$client_mac"

        # CATAT / PERBARUI COOLDOWN MAC KE /tmp
        if [ -n "$client_mac" ]; then
            tmp_cooldown="/tmp/cooldown.tmp"
            cooldown_expiry=$((now_epoch + duration + 7200))
            touch "$COOLDOWN_FILE" 2>/dev/null
            if [ -f "$COOLDOWN_FILE" ]; then
                awk -F'|' -v mac="$client_mac" -v now="$now_epoch" '$1 != mac && $2 > now' "$COOLDOWN_FILE" > "$tmp_cooldown" 2>/dev/null
                echo "${client_mac}|${cooldown_expiry}" >> "$tmp_cooldown"
                mv "$tmp_cooldown" "$COOLDOWN_FILE" 2>/dev/null
            fi
        fi

        rmdir "$LOCK" 2>/dev/null

        if [ "$minutes" -ge 60 ]; then
            h=$((minutes / 60))
            m=$((minutes % 60))
            if [ "$m" -gt 0 ]; then
                dur_str="$h Jam $m Menit"
            else
                dur_str="$h Jam"
            fi
        else
            dur_str="$minutes Menit"
        fi

        if [ "$download_rate" -gt 0 ]; then
            dl_str="$((download_rate)) Kbps"
        else
            dl_str="Unlimited"
        fi

        # PADA SAAT BERHASIL, TOMBOL KEMBALI DIGANTI DENGAN TOMBOL WHATSAPP
        show_msg "✅" "ok" "✓ LOGIN BERHASIL" "Voucher: <b>$voucher</b>" "Masa Aktif: <b style=\"color: #2563eb;\">$dur_str</b> (Speed: $dl_str)" "Internet sudah dapat digunakan." '<a href="https://wa.me/628970000120" class="btn-wa" target="_blank">💬 HUBUNGI KAMI (WA)</a>'
        exit 0
    fi
fi

# =========================================================
# AUTH GAGAL
# =========================================================

log "AUTH FAILED ip=$clientip voucher=$voucher"
rmdir "$LOCK" 2>/dev/null
show_msg "❌" "err" "✕ LOGIN GAGAL" "openNDS tidak berhasil mengautentikasi client." "Silakan coba lagi." "" '<button onclick="history.back()" class="btn-back">KEMBALI</button>'

exit 0