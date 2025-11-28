#!/bin/bash
# ============================================================
# Script: setup-wifi.sh
# Deskripsi: Instalasi dan konfigurasi Wi-Fi di Ubuntu Server
# Penulis: Natia
# Lokasi: Balai Latihan Kerja Kabupaten Tasikmalaya
# ============================================================

# --- Validasi Root ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Jalankan script ini sebagai root (gunakan sudo)!"
  exit 1
fi

echo "✅ Script dijalankan dengan hak akses root."
echo

# --- Update dan install paket ---
echo "📦 Memperbarui daftar paket..."
apt update -y || { echo "❌ Gagal melakukan update paket."; exit 1; }

echo "📦 Menginstal dependensi Wi-Fi..."
apt install -y wireless-tools wpasupplicant net-tools usbutils iw network-manager macchanger || {
  echo "❌ Gagal menginstal paket yang diperlukan."; exit 1;
}

# --- Aktifkan NetworkManager ---
echo "⚙️  Mengaktifkan layanan NetworkManager..."
systemctl enable NetworkManager
systemctl start NetworkManager
systemctl status NetworkManager --no-pager | grep "active (running)" >/dev/null
if [ $? -eq 0 ]; then
  echo "✅ NetworkManager aktif."
else
  echo "❌ Gagal mengaktifkan NetworkManager."
  exit 1
fi

# --- Muat modul driver Wi-Fi ---
echo "🔧 Memuat modul Wi-Fi (ath9k_htc)..."
modprobe ath9k_htc || { echo "❌ Modul ath9k_htc tidak ditemukan."; exit 1; }

# --- Edit konfigurasi GRUB secara otomatis ---
echo "⚙️  Mengatur konfigurasi GRUB..."
GRUB_FILE="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.bak-$(date +%Y-%m-%d-%H-%M-%S)"

# Backup file GRUB sebelum diubah
if [ -f "$GRUB_FILE" ]; then
  cp "$GRUB_FILE" "$BACKUP_FILE"
  echo "🗄️  Backup GRUB disimpan di: $BACKUP_FILE"
else
  echo "⚠️  File GRUB tidak ditemukan, akan dibuat baru."
fi

# Lakukan pengeditan GRUB
if grep -q '^GRUB_CMDLINE_LINUX=' "$GRUB_FILE"; then
  sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' "$GRUB_FILE"
else
  echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' >> "$GRUB_FILE"
fi

# Update GRUB
update-grub || { echo "❌ Gagal memperbarui GRUB."; exit 1; }
echo "✅ GRUB berhasil diperbarui."


# --- Membuat file konfigurasi Netplan ---
echo "📡 Membuat konfigurasi Netplan..."
NETPLAN_FILE="/etc/netplan/netcfg-eternet-dan-wifi.yaml.txt"
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd

  ethernets:
    enp0s3:
      dhcp4: true
      dhcp6: true
    enp0s8:
      dhcp4: true
      dhcp6: true
    enp0s9:
      dhcp4: true
      dhcp6: true
    enp0s10:
      addresses:
      - "20.20.20.5/24"
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
        search: []
      routes:
      - to: "default"
        via: "20.20.20.1"

  wifis:
    wlan0:
      dhcp4: true
      dhcp6: true
      access-points:
        "Nama-Wifi":
          password: "Pass-wifi"

    wlan1:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.0.21/24]
      nameservers:
        addresses: [192.168.0.1, 8.8.8.8]
      access-points:
        "network_ssid_name":
          password: "**********"
      routes:
        - to: default
          via: 192.168.0.1
EOF

chmod 600 "$NETPLAN_FILE"
echo "✅ File Netplan telah dibuat di $NETPLAN_FILE"

# --- Validasi file Netplan ---
echo "🔍 Memvalidasi konfigurasi Netplan..."
netplan try --timeout 10 || {
  echo "❌ Validasi Netplan gagal. Periksa konfigurasi Anda."
  exit 1
}

# --- Konfirmasi Reboot ---
echo
read -p "⚠️  Apakah Anda ingin reboot sekarang? (y/n): " choice
case "$choice" in
  y|Y ) echo "🔄 Rebooting..."; reboot ;;
  n|N ) echo "✅ Selesai tanpa reboot."; exit 0 ;;
  * ) echo "❌ Pilihan tidak valid."; exit 1 ;;
esac
