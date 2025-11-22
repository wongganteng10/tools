#!/bin/bash

CSV_FILE="hasil_pindai-01.csv"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses data Klien/Station dari file: $CSV_FILE"
echo ""

# Mencetak header tabel Markdown
printf "| %-2s | %-5s | %-17s | %-17s | %-30s \n" "No" "Power" "Station MAC" "BSSID" "Probed ESSIDs"
printf "|----|-------|-------------------|-------------------|-------------------\n"

awk '
BEGIN { 
    FS=","; 
    start_clients = 0;
    client_count = 0;
}

/Station MAC, First time seen, Last time seen, Power, # packets, BSSID, Probed ESSIDs/ {
    start_clients = 1
    next
}

start_clients == 1 {
    
    # --- Membersihkan Spasi di Awal/Akhir Semua Kolom ---
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);  # Station MAC
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);  # Power
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6);  # BSSID
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $7);  # Probed ESSIDs

    # --- Validasi Data Penting ---
    if ($1 ~ /^([0-9A-F]{2}:){5}[0-9A-F]{2}$/) {
        
        # $1 = Station MAC
        # $4 = Power
        # $6 = BSSID
        # $7 = Probed ESSIDs

        client_count++;

        # Mencetak baris data dalam format lebar tetap
        printf "| %-2s | %-5s | %-17s | %-17s | %-30s \n", client_count, $4, $1, $6, $7
    }
}
' "$CSV_FILE"
