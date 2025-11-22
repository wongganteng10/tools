#!/bin/bash
echo "#===============================#"
echo "#--------- ACESS POINT ---------#"
echo "#===============================#"
#----------------------------------------------------
# Skrip gabungan untuk memproses bagian AP dan Klien
# dari file CSV Airodump-ng.
#----------------------------------------------------

CSV_FILE="hasil_pindai-01.csv"

# Memeriksa apakah file ada
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses file: $CSV_FILE"
echo "================================================================"

# --- FUNGSI UNTUK MENAMPILKAN DATA ACCESS POINT (AP) ---
display_aps() {
    echo "### Tabel Access Points (AP)"
    
    # Mencetak header tabel Markdown AP
    printf "|----|-------|-------------------|---------|-------------------\n"
    printf "| %-2s | %-5s | %-17s | %-7s | %-30s \n" "No" "Power" "BSSID" "Channel" "ESSID"
    printf "|----|-------|-------------------|---------|-------------------\n"

    awk '
    BEGIN { 
        FS=","; 
        start_processing = 0;
        ap_count = 0;
    }

    /BSSID, First time seen/ {
        start_processing = 1
        next
    }

    start_processing == 1 && $1 != "" {
        # Hentikan pemrosesan saat masuk ke bagian Clients (baris kosong di CSV)
        if ($1 ~ /^[[:space:]]*$/) {
            printf "|----|-------|-------------------|---------|-------------------\n";
            exit; 
        }
        
        # Membersihkan Spasi di Awal/Akhir Semua Kolom AP
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);   # BSSID
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);   # channel
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $9);   # Power
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $14);  # ESSID

        ap_count++; 
        printf "| %-2s | %-5s | %-17s | %-7s | %-30s \n", ap_count, $9, $1, $4, $14
    }

    END {
        if (start_processing == 1 && ap_count > 0 && $1 !~ /^[[:space:]]*$/) {
           printf "|----|-------|-------------------|---------|-------------------\n";
        }
    }
    ' "$CSV_FILE"
}

# --- FUNGSI UNTUK MENAMPILKAN DATA KLIEN (STATION) ---
display_clients() {
    echo ""
    echo "#===============================#"
    echo "#-------- Klien/Station --------#"
    echo "#===============================#"
    echo "### Tabel Klien/Stations"

    # Mencetak header tabel Markdown Klien
    printf "|----|-------|-------------------|-------------------|-------------------\n"
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
        
        # Membersihkan Spasi di Awal/Akhir Semua Kolom Klien
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);   # Station MAC
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);   # Power
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6);   # BSSID
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $7);   # Probed ESSIDs

        # Validasi: Memastikan baris dimulai dengan MAC address yang valid
        if ($1 ~ /^([0-9A-F]{2}:){5}[0-9A-F]{2}$/) {
            client_count++; 
            printf "| %-2s | %-5s | %-17s | %-17s | %-30s \n", client_count, $4, $1, $6, $7
        }
    }

    END {
        if (client_count > 0) {
           printf "|----|-------|-------------------|-------------------|-------------------\n";
        }
    }
    ' "$CSV_FILE"
}

# --- Jalankan Fungsi ---
display_aps
display_clients
