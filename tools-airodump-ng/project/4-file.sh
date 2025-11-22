#!/bin/bash

CSV_FILE="hasil_pindai-01.csv"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses file: $CSV_FILE"
echo ""

# Mencetak header tabel Markdown
printf "| %-2s | %-5s | %-17s | %-17s | %-30s \n" "No" "Power" "Station MAC" "BSSID" "Probed ESSIDs"
printf "|----|-------|-------------------|-------------------|------------------\n"

# Menggunakan AWK untuk memproses file dan mencetak langsung dalam format Markdown
awk '
BEGIN { FS=","; }

# Lewati baris sebelum header
/Station MAC, First time seen, Last time seen, Power, # packets, BSSID, Probed ESSIDs/ {
    start_processing = 1
    next
}

# Proses baris data AP
start_processing == 1 && $1 != "" {
    if ($1 ~ /^[[:space:]]*$/) {
        exit 
    }
    
    # $1 = BSSID
    # $4 = channel
    # $9 = Power
    # $14 = ESSID
    
    # Membersihkan spasi ekstra pada ESSID
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $7); 

    # Mencetak baris data dalam format lebar tetap:
    # %-2s = No (lebar 2)
    # %-5s = Power (lebar 5)
    # %-17s = BSSID (lebar 17)
    # %-7s = Channel (lebar 7)
    # %-30s = ESSID (lebar 30)
    printf "| %-2s | %-5s | %-17s |%-17s | %-30s \n", NR, $4, $1, $6, $7
}
' "$CSV_FILE"
