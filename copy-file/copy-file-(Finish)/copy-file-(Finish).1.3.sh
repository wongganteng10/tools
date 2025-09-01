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
#  Warna ANSI Cerah
# -----------------------------#
RED='\033[1;31m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
MAGENTA='\033[1;95m'
CYAN='\033[1;96m'
WHITE='\033[1;97m'
RESET='\033[0m'
BOLD='\033[1m'

# Deteksi lebar terminal untuk auto-wrap
COLUMNS=$(tput cols)

SOURCE_DIR="$(pwd)"
TARGET_DIR=""
AUTO_CREATE=0

# -----------------------------#
#  Fungsi bantuan
# -----------------------------#
show_help() {
  echo -e "${CYAN}${BOLD}Penggunaan:${RESET}"
  echo -e "  ${GREEN}./copy-file.sh${RESET} ${YELLOW}[TARGET_DIR]${RESET} ${MAGENTA}[--buat|-b]${RESET}\n"
  echo -e "${CYAN}Contoh:${RESET}"
  echo -e "  ${GREEN}./copy-file.sh${RESET}                         ${WHITE}# interaktif, target=./target${RESET}"
  echo -e "  ${GREEN}./copy-file.sh ~/backup${RESET}                ${WHITE}# interaktif, target=~/backup${RESET}"
  echo -e "  ${GREEN}./copy-file.sh ~/backup --buat${RESET}         ${WHITE}# buat target kalau belum ada${RESET}"
  echo
}

# -----------------------------#
#  Parsing argumen fleksibel
# -----------------------------#
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help; exit 0
fi

for arg in "$@"; do
  case "$arg" in
    --buat|-b) AUTO_CREATE=1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

# -----------------------------#
# Default TARGET_DIR bila tidak diberikan
# -----------------------------#
[[ -z "$TARGET_DIR" ]] && TARGET_DIR="./target"

# -----------------------------#
# Ekspansi ~ menjadi $HOME
# -----------------------------#
[[ "$TARGET_DIR" == "~"* ]] && TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# -----------------------------#
# Pastikan path absolut
# -----------------------------#
if ! TARGET_DIR=$(realpath -m -- "$TARGET_DIR" 2>/dev/null); then
  echo -e "❌ ${RED}Gagal memproses path TARGET_DIR.${RESET}"
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
    echo -e "   ${GREEN}sudo ./copy-file.sh \"$TARGET_DIR\"${RESET}\n"
    exit 1
  fi
fi

# -----------------------------#
#  Validasi / Buat folder target
# -----------------------------#
if [[ ! -d "$TARGET_DIR" ]]; then
  if [[ "$AUTO_CREATE" -eq 1 ]]; then
    echo -e "📂 ${CYAN}Folder \"$TARGET_DIR\" belum ada. Membuat otomatis...${RESET}"
    if ! mkdir -p -- "$TARGET_DIR"; then
      echo -e "❌ ${RED}Gagal membuat folder \"$TARGET_DIR\".${RESET}"
      exit 1
    fi
  else
    echo -e "\n❌ ${RED}Folder tujuan tidak ditemukan:${RESET}"
    echo -e "   ${CYAN}$TARGET_DIR${RESET}"
    echo -e "\n⚠️  ${YELLOW}Solusi:${RESET}"
    echo -e "   • Buat folder secara manual, atau"
    echo -e "   • Jalankan perintah berikut untuk membuat otomatis:"
    echo -e "     ${GREEN}./copy-file.sh \"$TARGET_DIR\" -b${RESET}\n"
    exit 1
  fi
fi

# -----------------------------#
#  Fungsi untuk menampilkan daftar folder
# -----------------------------#
tampilkan_daftar_folder() {
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BLUE}${BOLD}                 DAFTAR FOLDER${RESET}"
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  mapfile -t folders < <(find "$SOURCE_DIR" -type d | sort)
  filtered_folders=()

  for folder in "${folders[@]}"; do
    [[ "$folder" == "$TARGET_DIR"* ]] && continue
    filtered_folders+=("$folder")
  done

  if [[ ${#filtered_folders[@]} -eq 0 ]]; then
    echo -e "❌ ${RED}Tidak ada folder yang bisa dipilih.${RESET}"
    exit 1
  fi

  for i in "${!filtered_folders[@]}"; do
    folder_name=$(basename "${filtered_folders[$i]}")
    printf " ${YELLOW}%2d${RESET}. ${CYAN}%-s${RESET}\n" "$((i + 1))" "$folder_name"
  done

  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# -----------------------------#
#  Fungsi untuk menampilkan spesifikasi folder
# -----------------------------#
tampilkan_info_folder() {
  local folder="$1"
  echo ""
  echo -e "📂 ${YELLOW}${BOLD}Informasi Folder Terpilih:${RESET}"
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "📍 Path Lengkap   : ${CYAN}$(echo "$folder" | fold -s -w $COLUMNS)${RESET}"
  echo -e "📦 Ukuran Total   : ${MAGENTA}$(du -sh "$folder" | cut -f1)${RESET}"
  echo -e "📄 Jumlah File    : ${WHITE}$(find "$folder" -type f | wc -l)${RESET}"
  echo -e "📁 Jumlah Subdir  : ${WHITE}$(find "$folder" -mindepth 1 -type d | wc -l)${RESET}"
  echo -e "🕒 Terakhir Ubah  : ${WHITE}$(stat -c '%y' "$folder" | cut -d'.' -f1)${RESET}"
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

# -----------------------------#
#  Proses pemilihan folder
# -----------------------------#
while true; do
  tampilkan_daftar_folder
  echo -ne "${CYAN}${BOLD}Pilih nomor folder yang ingin disalin:${RESET} "
  read pilihan

  [[ -z "$pilihan" ]] && { echo -e "⚠️  ${YELLOW}Input tidak boleh kosong.${RESET}"; continue; }
  [[ ! "$pilihan" =~ ^[0-9]+$ ]] && { echo -e "⚠️  ${YELLOW}Input harus berupa angka.${RESET}"; continue; }

  mapfile -t folders < <(find "$SOURCE_DIR" -type d | sort)
  filtered_folders=()
  for folder in "${folders[@]}"; do
    [[ "$folder" == "$TARGET_DIR"* ]] && continue
    filtered_folders+=("$folder")
  done

  if (( pilihan < 1 || pilihan > ${#filtered_folders[@]} )); then
    echo -e "⚠️  ${YELLOW}Pilihan tidak valid. Masukkan angka 1..${#filtered_folders[@]}.${RESET}"
    continue
  fi

  SELECTED_FOLDER="${filtered_folders[$((pilihan - 1))]}"
  tampilkan_info_folder "$SELECTED_FOLDER"

  echo -ne "${MAGENTA}${BOLD}Apakah pilihan ini sudah benar?${RESET} [y/n]: "
  read konfirmasi

  [[ "$konfirmasi" =~ ^[Yy]$ ]] && break

  echo -e "🔄 ${YELLOW}Kembali ke daftar folder...${RESET}\n"
  sleep 1
done

# -----------------------------#
#  Salin hanya file (bukan subfolder)
# -----------------------------#
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "📂 ${YELLOW}Menyalin semua file dari:${RESET} ${GREEN}\"$SELECTED_FOLDER\"${RESET}"
echo -e "📂 ${YELLOW}Ke folder tujuan       :${RESET} ${GREEN}\"$TARGET_DIR\"${RESET}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

shopt -s nullglob
files=("$SELECTED_FOLDER"/*)
count=0

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    filename=$(basename "$file")
    echo -e "📄 ${BLUE}Menyalin:${RESET} ${WHITE}\"$filename\"${RESET} ➜ ${GREEN}\"$TARGET_DIR\"${RESET}"
    if cp -fv -- "$file" "$TARGET_DIR"/ >/dev/null 2>&1; then
      echo -e "✅ ${GREEN}Berhasil:${RESET} \"$filename\""
    else
      echo -e "❌ ${RED}Gagal:${RESET} \"$filename\""
    fi
    ((count++))
  fi
done

if (( count == 0 )); then
  echo -e "⚠️  ${YELLOW}Tidak ada file di${RESET} ${CYAN}\"$SELECTED_FOLDER\"${RESET} ${YELLOW}untuk disalin.${RESET}"
else
  echo -e "✅ ${GREEN}${count} file berhasil disalin ke \"${TARGET_DIR}\".${RESET}"
fi

echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "📂 ${CYAN}${BOLD}Daftar isi di${RESET} ${GREEN}\"$TARGET_DIR\"${RESET}:"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if command -v tree &>/dev/null; then
  tree -C "$TARGET_DIR"
else
  ls --color=auto -lh "$TARGET_DIR"
fi
