#!/bin/bash

# Meminta pengguna untuk memasukkan nama file
echo "Masukkan nama file (termasuk path jika tidak di direktori saat ini):"
read nama_file

# Memeriksa apakah file ada
if [[ ! -f "$nama_file" ]]; then
    echo "File tidak ditemukan!"
    exit 1
fi

# Meminta pengguna untuk memasukkan teks yang akan diganti
echo "Masukkan teks yang akan diganti:"
read teks_lama

# Meminta pengguna untuk memasukkan teks pengganti
echo "Masukkan teks pengganti:"
read teks_baru

# Melakukan penggantian menggunakan sed
sed -i "s/$teks_lama/$teks_baru/g" "$nama_file"

# Menampilkan hasil
echo "Penggantian selesai. Isi file setelah penggantian:"
cat "$nama_file"
