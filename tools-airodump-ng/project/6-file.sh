#!/bin/bash

CSV_FILE="hasil_pindai-01.csv"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses file: $CSV_FILE"
echo ""

# Mencetak header tabel Markdown
printf "| %-2s | %-5s | %-17s | %-7s | %-30s |\n" "No" "Power" "BSSID" "Channel" "ESSID"
printf "|----|-------|-------------------|---------|--------------------------------|\n"

awk '
BEGIN { 
    FS=","; 
    start_processing = 0;
    ap_count = 0; # <-- Variabel penghitung AP baru, dimulai dari 0
}

# Lewati baris sebelum header
/BSSID, First time seen/ {
    start_processing = 1
    next
}

# Proses baris data AP
start_processing == 1 && $1 != "" {
    # Hentikan pemrosesan saat masuk ke bagian Clients (baris kosong di CSV)
    if ($1 ~ /^[[:space:]]*$/) {
        printf "|----|-------|-------------------|---------|--------------------------------|\n";
        exit; 
    }
    
    # --- Membersihkan Spasi di Awal/Akhir Semua Kolom ---
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);   # BSSID
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4);   # channel
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $9);   # Power
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $14);  # ESSID

    # --- PENTING: Menambah penghitung setelah validasi ---
    ap_count++; 

    # Mencetak baris data menggunakan ap_count:
    printf "| %-2s | %-5s | %-17s | %-7s | %-30s |\n", ap_count, $9, $1, $4, $14
}

# Jika file berakhir tanpa menemukan bagian clients, tutup tabel di sini juga
END {
    if (start_processing == 1 && ap_count > 0) {
    # printf "|----|-------|-------------------|---------|--------------------------------|\n";
    }
}

' "$CSV_FILE"


echo ""
echo ""
echo "#===============================#"
echo "#-------- Klien/Station --------#"
echo "#===============================#"
#!/bin/bash

#----------------------------------------------------
# Skrip untuk memproses file CSV Airodump-ng (bagian Clients)
# menjadi tabel Markdown yang rapi dengan lebar tetap.
#----------------------------------------------------

CSV_FILE="hasil_pindai-01.csv"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' tidak ditemukan."
    exit 1
fi

echo "Memproses data Klien/Station dari file: $CSV_FILE"
echo ""

# Mencetak header tabel Markdown
printf "| %-2s | %-5s | %-17s | %-17s | %-30s |\n" "No" "Power" "Station MAC" "BSSID" "Probed ESSIDs"
printf "|----|-------|-------------------|-------------------|--------------------------------|\n"

awk '
BEGIN { 
    FS=","; 
    start_clients = 0;
    client_count = 0; # Variabel penghitung klien, dimulai dari 0
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
    # Memastikan baris dimulai dengan MAC address yang valid sebelum diproses
    if ($1 ~ /^([0-9A-F]{2}:){5}[0-9A-F]{2}$/) {
        
        # $1 = Station MAC
        # $4 = Power
        # $6 = BSSID
        # $7 = Probed ESSIDs

        client_count++; # Menambah hitungan klien yang valid

        # Mencetak baris data dalam format lebar tetap
        printf "| %-2s | %-5s | %-17s | %-17s | %-30s |\n", client_count, $4, $1, $6, $7
    }
    # Baris yang tidak valid (sisa file, baris kosong) diabaikan di sini
}

# --- PENTING ---
# Menambahkan garis penutup tabel di akhir pemrosesan file (END)
END {
    if (client_count > 0) {
    printf "|----|-------|-------------------|-------------------|--------------------------------|\n";
    }
}

' "$CSV_FILE"

