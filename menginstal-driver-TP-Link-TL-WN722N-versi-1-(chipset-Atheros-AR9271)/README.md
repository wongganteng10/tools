Baik, berikut panduan **lengkap dan aman** untuk menginstal **driver TP-Link TL-WN722N versi 1 (chipset Atheros AR9271)** di **Ubuntu Server** (tanpa GUI).

---

## 🧩 1. Cek Versi dan Chipset Adapter

Pertama, pastikan adapter kamu **versi 1**, karena hanya **v1** yang menggunakan chipset **Atheros AR9271** (bisa langsung pakai driver `ath9k_htc` bawaan Linux).

Jalankan:

```bash
lsusb
```

Contoh output jika **v1**:

```
Bus 002 Device 004: ID 0cf3:9271 Atheros Communications, Inc. AR9271 802.11n
```

✅ Jika terlihat `0cf3:9271`, berarti benar **TL-WN722N v1**.
❌ Jika berbeda (misal `2357:010c`), berarti versi **v2/v3** — itu butuh driver berbeda.

---

## ⚙️ 2. Aktifkan Modul Driver Bawaan

Ubuntu Server biasanya sudah punya driver `ath9k_htc`.
Kita tinggal **aktifkan** dan **pastikan firmware tersedia**.

```bash
sudo apt update
sudo apt install linux-firmware wireless-tools wpasupplicant net-tools
```

Kemudian muat modul:

```bash
sudo modprobe ath9k_htc
```

Cek apakah terdeteksi:

```bash
iwconfig
```

Jika muncul seperti:

```
wlan0     IEEE 802.11  ESSID:off/any  Mode:Managed  Access Point: Not-Associated
```

✅ berarti driver sudah berfungsi.

---

## 🧰 3. Tambahkan agar Modul Aktif Otomatis Saat Boot

Supaya tidak perlu memuat manual setiap kali restart:

```bash
echo ath9k_htc | sudo tee -a /etc/modules
```

---

## 🌐 4. Hubungkan ke Wi-Fi (CLI)

Gunakan `nmcli` (NetworkManager CLI) atau `wpa_supplicant`.

### Opsi 1 — Menggunakan `nmcli` (lebih mudah)

Pastikan NetworkManager aktif:

```bash
sudo apt install network-manager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```

Kemudian hubungkan Wi-Fi:

```bash
nmcli device wifi list
nmcli device wifi connect "Nama_WiFi" password "KataSandiWiFi"
```

Cek status koneksi:

```bash
nmcli device status
```

---

### Opsi 2 — Menggunakan `wpa_supplicant` (lebih ringan)

Buat file konfigurasi:

```bash
sudo nano /etc/wpa_supplicant.conf
```

Isi dengan:

```bash
network={
    ssid="Nama_WiFi"
    psk="KataSandiWiFi"
}
```

Kemudian jalankan:

```bash
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
sudo dhclient wlan0
```

---

## 🧪 5. Cek Koneksi Internet

```bash
ping -c 4 google.com
```

Jika berhasil reply → ✅ koneksi sudah aktif.

---

## 🩺 6. Jika Tidak Terdeteksi

Jika `iwconfig` tidak menampilkan `wlan0`, coba langkah berikut:

```bash
sudo dmesg | grep ath9k_htc
```

Jika muncul pesan seperti:

```
firmware ath9k_htc/htc_9271.fw not found
```

→ berarti firmware belum ada.

Unduh manual:

```bash
sudo mkdir -p /lib/firmware/ath9k_htc/
sudo wget https://github.com/qca/open-ath9k-htc-firmware/raw/master/htc_9271.fw -O /lib/firmware/ath9k_htc/htc_9271.fw
sudo modprobe -r ath9k_htc
sudo modprobe ath9k_htc
```

---

## ✅ Ringkasan

| Langkah                  | Perintah                          |                           |
| ------------------------ | --------------------------------- | ------------------------- |
| Cek USB                  | `lsusb`                           |                           |
| Instal driver & firmware | `sudo apt install linux-firmware` |                           |
| Aktifkan modul           | `sudo modprobe ath9k_htc`         |                           |
| Cek koneksi              | `iwconfig` / `nmcli`              |                           |
| Auto load saat boot      | `echo ath9k_htc                   | sudo tee -a /etc/modules` |
| Jika firmware hilang     | Unduh `htc_9271.fw` dari GitHub   |                           |

---

Kalau kamu mau, saya bisa bantu buatkan **skrip otomatis** (`.sh`) agar semua langkah di atas bisa dijalankan satu kali (praktis untuk server tanpa GUI).
Apakah kamu mau saya buatkan skripnya juga?


---
---
---

Pertanyaan yang sangat bagus 👍

Nama **`wlxc4e98408f268`** yang kamu lihat **bukan kesalahan**, tetapi hasil dari **aturan penamaan perangkat jaringan baru (predictable network interface names)** yang diterapkan di Ubuntu sejak versi 16.04 ke atas.

Mari saya jelaskan secara singkat dan jelas 👇

---

## 🧠 Mengapa Bukan `wlan0`?

Dulu (versi lama Linux), nama antarmuka Wi-Fi **selalu** berupa `wlan0`, `wlan1`, dst.
Namun, sekarang Ubuntu menggunakan **"Predictable Network Interface Names"** dari sistem **`systemd/udev`**, yang menamai perangkat berdasarkan:

* Jenis antarmuka (wl = wireless LAN),
* MAC address perangkat (`c4:e9:84:08:f2:68` pada contohmu).

Sehingga jadilah:

```
wlx + [alamat MAC tanpa titik dua]
→ wlxc4e98408f268
```

Jadi sebenarnya nama itu berarti:

> **wlan** (Wi-Fi) dengan **MAC address c4:e9:84:08:f2:68**

---

## ⚙️ Apakah Bisa Dikembalikan ke `wlan0`?

Bisa. Ada dua cara — tergantung kebutuhan kamu:

---

### **Opsi 1 — Ubah ke Nama Lama (`wlan0`)**

Jika kamu lebih suka nama klasik (lebih mudah untuk skrip dan konfigurasi):

1. Edit konfigurasi GRUB:

   ```bash
   sudo nano /etc/default/grub
   ```

2. Temukan baris:

   ```
   GRUB_CMDLINE_LINUX=""
   ```

   Ubah menjadi:

   ```
   GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
   ```

3. Simpan, lalu update GRUB:

   ```bash
   sudo update-grub
   ```

4. Reboot sistem:

   ```bash
   sudo reboot
   ```

Setelah itu, jalankan:

```bash
iwconfig
```

Maka perangkat akan bernama **`wlan0`** seperti dulu.

---

### **Opsi 2 — Biarkan Seperti Sekarang (Disarankan di Server)**

Tidak perlu diubah; kamu cukup gunakan nama `wlxc4e98408f268` di setiap perintah, misalnya:

```bash
sudo ip link set wlxc4e98408f268 up
sudo dhclient wlxc4e98408f268
```

Atau, jika ingin lebih ringkas tanpa mengubah GRUB, kamu bisa **buat alias manual** agar sistem mengenal `wlan0`:

```bash
sudo ln -s /sys/class/net/wlxc4e98408f268 /sys/class/net/wlan0
```

Namun ini hanya sementara (tidak permanen setelah reboot).

---

## ✅ Rekomendasi untuk Ubuntu Server

Jika kamu ingin konsistensi untuk skrip atau konfigurasi jaringan otomatis, **ubah ke `wlan0` via GRUB** (Opsi 1).
Tapi jika kamu hanya menggunakan koneksi Wi-Fi biasa dan tidak terganggu oleh nama panjang itu, **biarkan saja** — tidak ada masalah teknis sama sekali.

---

Apakah kamu ingin saya bantu buatkan **perintah otomatis (skrip `.sh`)** untuk mengubah nama antarmuka jadi `wlan0` permanen di Ubuntu Server?

---
---
---


Baik, Natia. Berdasarkan langkah-langkah yang kamu tulis, masalah yang kamu alami adalah **Wi-Fi tidak otomatis terhubung setelah reboot** di Ubuntu Server. Ini umum terjadi karena koneksi dibuat secara manual menggunakan `nmcli` atau `wpa_supplicant`, tetapi belum dikonfigurasi agar aktif otomatis saat sistem dinyalakan.

Mari kita perbaiki langkah demi langkah supaya koneksi Wi-Fi tersambung otomatis saat reboot.

---

## 🧩 1. Cek Nama Interface

Pastikan dulu nama interface Wi-Fi kamu benar, karena di Ubuntu Server kadang bukan `wlan0`, tapi `wlx...`.

```bash
nmcli device status
```

Contoh output:

```
DEVICE           TYPE      STATE         CONNECTION
wlxc4e98408f268  wifi      connected     Free-WIFI
eth0             ethernet  connected     Wired connection 1
lo               loopback  unmanaged     --
```

Berarti nama interface Wi-Fi kamu adalah `wlxc4e98408f268`.

---

## ⚙️ 2. Hapus Koneksi Lama (opsional)

Untuk memastikan tidak ada konfigurasi ganda, jalankan:

```bash
sudo nmcli connection delete id "Free-WIFI"
```

---

## 🌐 3. Buat Koneksi Wi-Fi yang Permanen

Gunakan perintah berikut (ganti `wlxc4e98408f268` dengan nama interface kamu):

```bash
sudo nmcli dev wifi connect "Free-WIFI" password "MasterPotato" ifname wlxc4e98408f268 name Free-WIFI
```

Perintah ini akan membuat profil koneksi baru bernama **Free-WIFI** yang disimpan secara permanen oleh NetworkManager.

---

## 🔁 4. Atur Koneksi agar Otomatis Aktif Saat Boot

Pastikan koneksi diset agar otomatis aktif:

```bash
sudo nmcli connection modify "Free-WIFI" connection.autoconnect yes
```

Cek hasilnya:

```bash
nmcli connection show "Free-WIFI" | grep autoconnect
```

Harus muncul:

```
connection.autoconnect: yes
```

---

## 🧠 5. Nonaktifkan Konfigurasi Manual `wpa_supplicant` (jika ada)

Jika kamu sebelumnya menambahkan konfigurasi manual di `/etc/wpa_supplicant.conf` dan memanggilnya di `/etc/rc.local` atau systemd, **hapus atau nonaktifkan** agar tidak konflik dengan NetworkManager.

---

## 🔧 6. Restart NetworkManager

```bash
sudo systemctl restart NetworkManager
```

---

## 🧪 7. Uji Coba Reboot

Sekarang reboot server:

```bash
sudo reboot
```

Setelah sistem menyala, cek koneksi:

```bash
nmcli device status
```

Pastikan status Wi-Fi menjadi:

```
wifi      connected  Free-WIFI
```

---

## 💡 Alternatif (Jika NetworkManager Tidak Aktif)

Kalau kamu **tidak menggunakan NetworkManager** (misalnya karena sistem minimal), maka gunakan konfigurasi `netplan`.

Edit file di:

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Isi (contoh):

```yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlxc4e98408f268:
      dhcp4: true
      access-points:
        "Free-WIFI":
          password: "MasterPotato"
```

Lalu simpan dan terapkan:

```bash
sudo netplan apply
```

Sekarang Wi-Fi akan otomatis tersambung setiap kali reboot.

---

Kalau kamu kirimkan hasil dari:

```bash
nmcli device status
```

dan

```bash
systemctl status NetworkManager
```

saya bisa bantu pastikan apakah sistem kamu pakai **NetworkManager** atau **netplan/networkd**, supaya langkah selanjutnya bisa lebih akurat. Mau saya bantu cek itu juga?


---
---
---


Bagus, Natia 👍
Kalau kamu ingin **mengubah Wi-Fi di Ubuntu Server menjadi IP statis** (bukan DHCP otomatis), kamu bisa ubah sedikit konfigurasi `netplan` milikmu.

Berikut panduannya yang rapi dan sesuai kaidah sistem Ubuntu Server 22.04 ke atas 👇

---

## 🧭 1. Buka file konfigurasi netplan

Biasanya di `/etc/netplan/`:

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

---

## ⚙️ 2. Ubah isinya seperti contoh berikut

Misalnya kamu ingin IP statis **192.168.1.50**, gateway **192.168.1.1**, dan DNS **8.8.8.8**:

```yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlxc4e98408f268:
      access-points:
        "Free-WIFI":
          password: "MasterPotato"
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

---

## 🧩 3. Terapkan konfigurasi

```bash
sudo netplan apply
```

Jika ingin memastikan tidak ada error:

```bash
sudo netplan try
```

*(Akan menunggu konfirmasi selama 120 detik sebelum menyimpan perubahan secara permanen — cocok untuk menghindari salah konfigurasi.)*

---

## 🧪 4. Cek hasilnya

```bash
ip a
```

atau

```bash
ip addr show wlxc4e98408f268
```

Kamu harus melihat IP `192.168.1.50` sudah terpasang.

---

## 💡 Catatan tambahan

* Jika koneksi Wi-Fi masih tidak otomatis aktif saat reboot, pastikan kamu sudah **menonaktifkan konfigurasi manual `wpa_supplicant`** dan hanya pakai `netplan`.
* Pastikan juga `renderer` sesuai sistem kamu:

  * Jika pakai **NetworkManager**, ubah menjadi:

    ```yaml
    renderer: NetworkManager
    ```
  * Jika server headless (tanpa GUI), biarkan `networkd`.

---

Apakah kamu ingin saya bantu buatkan contoh versi **dua koneksi (LAN + Wi-Fi)** dengan LAN statis dan Wi-Fi DHCP juga? Itu sering dipakai untuk server seperti milikmu.
