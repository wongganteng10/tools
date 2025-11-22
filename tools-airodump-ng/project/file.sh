#!/bin/bash

# Nama file CSV yang akan diproses
CSV_FILE="hasil_pindai-01.csv"

# Memeriksa apakah file ada
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses file: $CSV_FILE"
echo ""

# Skrip AWK yang ditingkatkan untuk menangani pemisah koma (CSV)
awk '
BEGIN {
    FS=",";  # Mengatur Field Separator menjadi koma
    OFS=" | "; # Mengatur Output Field Separator menjadi " | " untuk tabel Markdown
    
    # Header yang diinginkan
    print "| No | ESSID | BSSID | Channel | Power |"
    print "|----|-------|-------|---------|-------|"
}

# Melewati baris sebelum header BSSID yang sebenarnya
# Airodump-ng sering memiliki teks pengantar
/BSSID, First time seen, Last time seen, channel, Speed, Privacy, Cipher, Authentication, Power, # beacons, # IV, LAN IP, ID-length, ESSID, Key/ {
    start_processing = 1
    next
}

# Hanya memproses jika kita sudah melewati header yang sebenarnya
start_processing == 1 && $1 != "" {
    # Mengabaikan bagian "Client" dari output airodump-ng yang dimulai setelah baris kosong
    if ($1 ~ /^[[:space:]]*$/) {
        # Ini adalah pemisah antara AP dan Clients, berhenti di sini
        exit 
    }
    
    # Membersihkan nilai: menghapus spasi di awal/akhir ESSID
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $14); 

    # $1 = BSSID
    # $4 = channel
    # $9 = Power
    # $14 = ESSID
    
    # Mencetak data yang diformat
    printf "| %-2s | %-20s | %-17s | %-7s | %-5s |\n", NR, $14, $1, $4, $9
}
' "$CSV_FILE"

