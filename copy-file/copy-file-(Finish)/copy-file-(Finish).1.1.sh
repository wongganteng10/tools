#!/bin/bash
# =====================================================================================
# Script  : copy-file.sh
# Fungsi  : Menyalin file dari folder yang dipilih user ke folder tujuan.
#           - Menampilkan daftar folder (nama saja, bukan path)
#           - Menampilkan detail spesifikasi folder sebelum copy
#           - Konfirmasi ulang sebelum menyalin
#           - Jika salah folder, kembali ke daftar folder
# =====================================================================================

set -o pipefail

# -----------------------------#
#  Warna Terminal
# -----------------------------#
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

SOURCE_DIR="$(pwd)"
TARGET_DIR=""
AUTO_CREATE=0

# -----------------------------#
#  Fungsi bantuan
# -----------------------------#
show_help() {
  cat <<'EOF'
Penggunaan:
  ./copy-file.sh [TARGET_DIR] [--buat|-b]

Contoh:
  ./copy-file.sh                       # interaktif, target=./target
  ./copy-file.sh ~/backup              # interaktif, target=~/backup
  ./copy-file.sh ~/backup --buat       # buat target kalau belum ada, lalu interaktif

EOF
}

# -----------------------------#
#  Parsing argumen fleksibel
# -----------------------------#
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help; exit 0
fi

for arg in "$@"; do
  case "$arg" in
    --buat|-b)
      AUTO_CREATE=1 ;;
    *)
      TARGET_DIR="$arg" ;;
  esac
done

# -----------------------------#
# Default TARGET_DIR bila tidak diberikan
# -----------------------------#
if [[ -z "$TARGET_DIR" ]]; then
  TARGET_DIR="/var/cache/www"
fi

# -----------------------------#
# Ekspansi ~ menjadi $HOME
# -----------------------------#
[[ "$TARGET_DIR" == "~"* ]] && TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# -----------------------------#
# Pastikan path absolut
# -----------------------------#
if ! TARGET_DIR=$(realpath -m -- "$TARGET_DIR" 2>/dev/null); then
  echo "❌ ${RED}Gagal memproses path TARGET_DIR.${RESET}"
  exit 1
fi

# -----------------------------#
#  Cek kepemilikan TARGET_DIR
# -----------------------------#
if [[ -d "$TARGET_DIR" ]]; then
  OWNER=$(stat -c "%U" "$TARGET_DIR")
  if [[ "$OWNER" == "root" && "$EUID" -ne 0 ]]; then
    echo -e "\n❌ ${RED}Folder tujuan dimiliki root:${RESET}"
    echo -e "   ${CYAN}$TARGET_DIR${RESET}"
    echo -e "\n⚠️  ${YELLOW}Tidak bisa melanjutkan tanpa sudo.${RESET}"
    echo -e "   Jalankan ulang perintah dengan:\n"
    echo -e "     ${GREEN}sudo ./copy-file.sh \"$TARGET_DIR\"${RESET}\n"
    exit 1
  fi
fi

# -----------------------------#
#  Validasi / Buat folder target
# -----------------------------#
if [[ ! -d "$TARGET_DIR" ]]; then
  if [[ "$AUTO_CREATE" -eq 1 ]]; then
    echo "📂 Folder \"$TARGET_DIR\" belum ada. Membuat otomatis..."
    if ! mkdir -p -- "$TARGET_DIR"; then
      echo "❌ ${RED}Gagal membuat folder \"$TARGET_DIR\".${RESET}"
      exit 1
    fi
  else
    echo -e "\n❌ ${RED}Folder tujuan tidak ditemukan:${RESET}"
    echo -e "   ${CYAN}$TARGET_DIR${RESET}"
    echo -e "\n⚠️  ${YELLOW}Solusi:${RESET}"
    echo -e "   • Buat folder secara manual, atau"
    echo -e "   • Jalankan perintah berikut untuk membuat otomatis:"
    echo -e "   • ${GREEN}-b${RESET} atau ${GREEN}--buat${RESET}\n"
    echo -e "     ${GREEN}./copy-file.sh \"$TARGET_DIR\" -b${RESET}\n"
    exit 1
  fi
fi

# -----------------------------#
#  Fungsi untuk menampilkan daftar folder
# -----------------------------#
tampilkan_daftar_folder() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Daftar Folder"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  mapfile -t folders < <(find "$SOURCE_DIR" -type d | sort)

  filtered_folders=()
  for folder in "${folders[@]}"; do
    case "$folder/" in
      "$TARGET_DIR"/*) continue ;;
    esac
    filtered_folders+=("$folder")
  done

  if [[ ${#filtered_folders[@]} -eq 0 ]]; then
    echo "❌ Tidak ada folder yang bisa dipilih."
    exit 1
  fi

  for i in "${!filtered_folders[@]}"; do
    folder_name=$(basename "${filtered_folders[$i]}")
    echo " $((i + 1)). $folder_name"
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# -----------------------------#
#  Fungsi untuk menampilkan spesifikasi folder
# -----------------------------#
tampilkan_info_folder() {
  local folder="$1"
  echo ""
  echo -e "📂 Informasi Folder Terpilih:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "Path Lengkap   : ${CYAN}$folder${RESET}"
  echo -e "Ukuran Total   : $(du -sh "$folder" | cut -f1)"
  echo -e "Jumlah File    : $(find "$folder" -type f | wc -l)"
  echo -e "Jumlah Subdir  : $(find "$folder" -mindepth 1 -type d | wc -l)"
  echo -e "Terakhir Ubah  : $(stat -c '%y' "$folder" | cut -d'.' -f1)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}


# -----------------------------#
#  Proses pemilihan folder
# -----------------------------#
while true; do
  tampilkan_daftar_folder

  read -p "Pilih nomor folder yang ingin disalin semua filenya: " pilihan
  [[ -z "$pilihan" ]] && { echo "⚠️  Input tidak boleh kosong."; continue; }
  [[ ! "$pilihan" =~ ^[0-9]+$ ]] && { echo "⚠️  Input harus berupa angka."; continue; }

  mapfile -t folders < <(find "$SOURCE_DIR" -type d | sort)
  filtered_folders=()
  for folder in "${folders[@]}"; do
    case "$folder/" in
      "$TARGET_DIR"/*) continue ;;
    esac
    filtered_folders+=("$folder")
  done

  if (( pilihan < 1 || pilihan > ${#filtered_folders[@]} )); then
    echo "⚠️  Pilihan tidak valid. Masukkan angka 1..${#filtered_folders[@]}."
    continue
  fi

  SELECTED_FOLDER="${filtered_folders[$((pilihan - 1))]}"
  tampilkan_info_folder "$SELECTED_FOLDER"

  # Konfirmasi sebelum lanjut copy
  read -p "Apakah pilihan ini sudah benar? (y/n): " konfirmasi
  if [[ "$konfirmasi" =~ ^[Yy]$ ]]; then
    break
  else
    echo ""
    echo "🔄 Kembali ke daftar folder..."
    sleep 1
  fi
done

# -----------------------------#
#  Salin hanya file (bukan subfolder)
# -----------------------------#
echo ""
echo "📂 Menyalin semua file dari: \"$SELECTED_FOLDER\""
echo "📂 Ke folder tujuan        : \"$TARGET_DIR\""
echo ""

shopt -s nullglob
files=("$SELECTED_FOLDER"/*)
count=0

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    cp -fv -- "$file" "$TARGET_DIR"/
    ((count++))
  fi
done

if (( count == 0 )); then
  echo "⚠️  Tidak ada file di \"$SELECTED_FOLDER\" untuk disalin."
else
  echo "✅ $count file berhasil disalin ke \"$TARGET_DIR\"."
fi

echo ""
echo "📄 Daftar isi di \"$TARGET_DIR\":"
tree "$TARGET_DIR" 2>/dev/null || ls -R "$TARGET_DIR"
