Berikut adalah file README.md yang lengkap untuk repositori yang berisi skrip Bash (`gabung_hasil.sh`) yang baru saja kita buat. README ini menjelaskan tujuan repositori, cara penggunaan, dan dependensi yang diperlukan.

## Proyek Airodump-ng CSV Analyzer

Repositori ini berisi skrip Bash (gabung_hasil.sh) yang dirancang untuk membaca dan memformat file output `.csv` yang dihasilkan oleh alat airodump-ng (bagian dari paket Aircrack-ng).
Skrip ini mengonversi data mentah Access Point (AP) dan Klien (Stations) menjadi dua tabel Markdown yang rapi dan mudah dibaca di terminal Anda.

### Prasyarat

Untuk menjalankan skrip ini, Anda membutuhkan lingkungan Bash (Linux, macOS, WSL di Windows) dan utilitas dasar berikut yang biasanya sudah tersedia secara default:
`bash`
`awk`
`printf` (shell builtin)
Anda juga harus memiliki file output dari `airodump-ng`.
Penggunaan
1. Menghasilkan File Data
Pertama, pastikan Anda telah menjalankan `airodump-ng` dan menyimpannya ke file CSV bernama `hasil_pindai-01.csv`.
```bash
# Pastikan adaptor nirkabel Anda dalam mode monitor (misal: wlan0mon)
sudo airodump-ng -w hasil_pindai --output-format csv wlan0mon
```
Gunakan kode dengan hati-hati.

Perintah di atas akan menghasilkan beberapa file, salah satunya `hasil_pindai-01.csv`.

2. Menyiapkan Skrip
Pastikan skrip `gabung_hasil.sh` berada di direktori yang sama dengan file CSV Anda.

4. Menjalankan Analisis
Beri izin eksekusi pada skrip, lalu jalankan:
```bash
chmod +x gabung_hasil.sh
./gabung_hasil.sh
```
Gunakan kode dengan hati-hati.

Hasil Output
Skrip akan menampilkan dua tabel terpisah di terminal Anda: satu untuk Access Points (AP) dan satu lagi untuk Klien/Stations.

Contoh Output
```
Memproses file: `hasil_pindai-01.csv`
================================================================
### Tabel Access Points (AP)
No	Power	BSSID	Channel	ESSID
1	-108	32:0A:9D:CF:57:E9	11	WIFI_KELAS_INFORMATIKA 1
2	-85	F2:41:A2:D5:4A:B2	6	WIFI_KELAS_INFORMATIKA 5
----	-------	-------------------	---------	--------------------------------
Tabel Klien/Stations
No	Power	Station MAC	BSSID	Probed ESSIDs
1	-55	AA:BB:CC:DD:EE:FF	32:0A:9D:CF:57:E9	WIFI_KELAS_INFORMATIKA 1
2	-72	11:22:33:44:55:66	(not associated)	SomeOtherNetwork, Test_AP
----	-------	-------------------	-------------------	--------------------------------
```
```
## Struktur Skrip (`gabung_hasil.sh`)

Skrip ini menggunakan `awk` untuk mem-parsing file CSV. Beberapa fitur utama meliputi:

*   **Pemisah Koma:** Menggunakan koma (`,`) sebagai pemisah field untuk membaca file CSV dengan benar.
*   **Pembersihan Spasi:** Fungsi `gsub` digunakan untuk menghapus spasi di awal dan akhir setiap kolom, memastikan perataan tabel yang rapi.
*   **Validasi Data:** Hanya memproses baris yang memiliki format MAC Address yang valid.
*   **Format Markdown:** Menggunakan `printf` dengan lebar tetap untuk menghasilkan tabel yang konsisten dalam format Markdown.

```
