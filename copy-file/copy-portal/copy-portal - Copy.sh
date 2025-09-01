#!/bin/bash

# Direktori skrip
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Cari semua check.htm dan index.htm secara rekursif
FILES=($(find "$SCRIPT_DIR" -type f \( -name "check.htm" -o -name "index.htm" \)))

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Tidak ada check.htm atau index.htm ditemukan di $SCRIPT_DIR"
    exit 1
fi

# --- Kelompokkan file berdasarkan folder ---
declare -A FOLDER_MAP
NUM=1
declare -A NUM_TO_FOLDER
echo "Daftar Folder yang berisi check.htm/index.htm:"
for F in "${FILES[@]}"; do
    DIR=$(dirname "$F")
    if [[ -z "${FOLDER_MAP[$DIR]}" ]]; then
        FOLDER_MAP[$DIR]=1
        echo "$NUM. $DIR"
        NUM_TO_FOLDER[$NUM]="$DIR"
        ((NUM++))
    fi
done

# --- Pilih nomor folder ---
read -p "Pilih nomor folder yang ingin diubah: " FOLDER_SEL
TARGET_DIR="${NUM_TO_FOLDER[$FOLDER_SEL]}"
if [ -z "$TARGET_DIR" ]; then
    echo "Nomor folder tidak valid!"
    exit 1
fi

TARGET_CP="/home/$USER/folder2/folder3/folder4/folder5"
echo "....."
echo "Sedang menyalin........."
echo "....."
# --- Ubah semua check.htm & index.htm di folder terpilih ---
for F in "$TARGET_DIR"/*; do

	# Menyalin semua file dari START_CP ke TARGET_CP dengan tampilan verbose
	cp -v "$F" "$TARGET_CP"

done

echo "Selesai."

