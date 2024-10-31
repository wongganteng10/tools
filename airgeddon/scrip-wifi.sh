#!/bin/bash

# Memeriksa apakah aircrack-ng terinstal
if ! command -v airodump-ng &> /dev/null; then
    echo "aircrack-ng tidak terinstal. Silakan instal terlebih dahulu."
    exit 1
fi

# Menentukan nama antarmuka jaringan
INTERFACE="wlan0" # Gantilah dengan nama antarmuka jaringan Anda

# Menjalankan airodump-ng untuk mencari jaringan
echo "Mencari jaringan WiFi..."
airodump-ng $INTERFACE --write networks &

# Menunggu beberapa detik untuk mengumpulkan informasi jaringan
sleep 10

# Menghentikan airodump-ng
killall airodump-ng

# Menampilkan daftar jaringan yang terdeteksi
echo "Daftar jaringan yang terdeteksi:"
cat networks-01.csv | grep -v "Station" | awk -F',' '{print $1 " " $2 " " $3}' | nl

# Meminta pengguna untuk memilih jaringan
read -p "Masukkan nomor jaringan yang ingin dipilih: " network_choice

# Mengambil BSSID dan channel dari pilihan pengguna
BSSID=$(awk -F',' "NR==$network_choice+1 {print \$1}" networks-01.csv)
CHANNEL=$(awk -F',' "NR==$network_choice+1 {print \$3}" networks-01.csv)

# Mencatat jaringan dan klien
echo "Mencatat jaringan dan klien..."
airodump-ng --bssid $BSSID -c $CHANNEL -w output $INTERFACE &

# Mendapatkan paket WPA/WPA2
read -p "Tekan [Enter] untuk menghentikan pencatatan dan mendapatkan paket WPA/WPA2..."

# Menghentikan airodump-ng
killall airodump-ng

echo "Proses selesai. File output disimpan sebagai output*.cap"
