# optimize_vps

# VPS Tunnel Optimizer

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/Version-1.0-green.svg)

Script optimasi kernel Linux untuk menurunkan latensi dan meningkatkan kecepatan koneksi pada VPS tunneling. Dioptimalkan untuk OpenVPN, WireGuard, Shadowsocks, V2Ray, Trojan dan protokol tunneling lainnya.

## Fitur

- ✅ Optimasi Kernel TCP/IP untuk throughput maksimal
- ✅ Implementasi TCP BBR untuk peningkatan kecepatan koneksi
- ✅ Pengurangan latensi dengan prioritisasi paket
- ✅ Quality of Service (QoS) untuk meningkatkan responsivitas
- ✅ Optimasi Network Interface Card
- ✅ Konfigurasi buffer TCP/IP yang optimal
- ✅ Peningkatan stabilitas koneksi jarak jauh
- ✅ Pengurangan packet loss dan bufferbloat

## Cara Penggunaan


# Clone repository
```
git clone https://github.com/username/vps-tunnel-optimizer.git
```
# Masuk ke direktori
```
cd vps-tunnel-optimizer
```
# Berikan izin eksekusi
```
chmod +x optimize_vps.sh
```
# Jalankan script (memerlukan akses root)
```
sudo ./optimize_vps.sh
```


## Persyaratan Sistem

- Sistem operasi: Ubuntu 18.04+/Debian 9+/CentOS 7+
- Kernel Linux 4.9+ (untuk fitur BBR)
- Akses root

## Optimasi Yang Diterapkan

Script ini menerapkan pengoptimalan berikut:
- Konfigurasi sysctl untuk performa TCP/IP yang optimal
- Aktivasi dan konfigurasi Google BBR congestion control
- Optimasi ukuran buffer TCP
- Pengaturan QoS dengan fq_codel untuk mengurangi bufferbloat
- Pengoptimalan Network Interface untuk performa terbaik
- Penyesuaian TCP FastOpen, TCP timestamps dan window scaling
- Konfigurasi parameter kernel yang relevan untuk tunneling

## Kompatibilitas Tunneling

Dioptimalkan untuk protokol tunneling seperti:
- OpenVPN
- WireGuard
- Shadowsocks
- V2Ray
- Trojan
- SSH Tunnel
- Dan protokol tunneling lainnya

## Perhatian

Script ini melakukan perubahan pada konfigurasi sistem. Meskipun telah diuji dengan baik, disarankan untuk:
1. Mencadangkan konfigurasi penting Anda
2. Menjalankan pada lingkungan uji terlebih dahulu
3. Memiliki akses cadangan (seperti konsol VPS) jika terjadi masalah

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT - lihat file LICENSE untuk detailnya.

## Kontribusi

Kontribusi, laporan bug, dan permintaan fitur sangat diterima. Silakan buka issue atau kirim pull request.

---

**Disclaimer**: Script ini disediakan "apa adanya", tanpa jaminan apa pun. Penggunaan script ini merupakan tanggung jawab pengguna sepenuhnya. Hasil optimasi dapat bervariasi tergantung pada konfigurasi server, jenis VPS, dan kondisi jaringan.
