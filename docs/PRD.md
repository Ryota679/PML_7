# 📄 Product Requirements Document (PRD)
## Aplikasi Tenant QR-Order

---

## 🧭 1. Latar Belakang

Di era digital saat ini, semakin banyak pelaku usaha kuliner yang mencari cara untuk meningkatkan efisiensi operasional dan pengalaman pelanggan. Namun pada kenyataannya, **banyak tenant kecil di area seperti burjo, kantin kampus, ruko kuliner, hingga rest area** masih mengandalkan sistem manual dalam melayani pesanan. Pelanggan harus memanggil pelayan, mencatat pesanan di kertas, dan menunggu lama tanpa kepastian status pesanannya.  
Kondisi ini tidak hanya menurunkan efisiensi, tetapi juga mempengaruhi kepuasan pelanggan — terutama di jam makan siang atau saat tenant ramai.

Selain itu, para **Business Owner atau pengelola area** (misalnya pemilik rest area atau ruko kuliner) sering menghadapi kesulitan dalam:
- Memantau performa tiap penyewa.
- Melakukan rekap penjualan secara real-time.
- Memberikan sistem digital seragam untuk semua tenant di bawah pengelolaannya.

Dari sisi penyewa (tenant), banyak dari mereka belum memiliki kemampuan teknis atau sumber daya untuk membuat sistem pemesanan online sendiri. Oleh karena itu, dibutuhkan sebuah **aplikasi siap pakai yang bisa langsung digunakan tanpa login pelanggan**, tetapi tetap memberikan sistem manajemen pesanan yang lengkap bagi tenant.

Aplikasi **Tenant QR-Order** dikembangkan untuk menjawab tantangan ini dengan pendekatan sederhana:  
➡️ *“Cukup tempel QR di meja, pelanggan scan, pilih menu, dan tenant langsung terima pesanan di dashboard.”* Dengan sistem ini, seluruh pihak — pelanggan, penyewa, dan pemilik area — dapat merasakan kemudahan digitalisasi tanpa perlu proses yang rumit atau mahal.

---

## 🎯 2. Tujuan Produk

Aplikasi **Tenant QR-Order** dirancang untuk menghadirkan solusi digital yang menyeluruh bagi ekosistem kuliner multi-tenant (seperti ruko, kantin, atau rest area). Tujuan utama dari pengembangan aplikasi ini meliputi:

1. **Meningkatkan efisiensi proses pemesanan:**
   - Pelanggan dapat memesan makanan/minuman langsung dari smartphone hanya dengan memindai QR code, tanpa perlu login atau aplikasi tambahan.
   - Tenant tidak perlu mencatat pesanan secara manual; semua data otomatis masuk ke dashboard admin.

2. **Mendukung digitalisasi usaha kecil dan menengah (UMKM) di sektor kuliner:**
   - Memberikan akses teknologi kepada pemilik warung atau tenant tanpa memerlukan biaya tinggi atau kemampuan teknis khusus.
   - Mendorong adaptasi teknologi di sektor kuliner lokal.

3. **Memudahkan pengelola area (Business Owner) dalam manajemen penyewa:**
   - Owner dapat menambahkan akun penyewa secara otomatis dari satu dashboard.
   - Setiap penyewa mendapat QR unik yang langsung terhubung ke menunya masing-masing.
   - Owner dapat melihat laporan global penjualan di semua tenant secara real-time.

4. **Meningkatkan pengalaman pelanggan:**
   - Proses pemesanan menjadi lebih cepat, praktis, dan higienis (tanpa kertas menu fisik).
   - Pelanggan mendapatkan notifikasi otomatis saat pesanan siap diambil.

5. **Menciptakan ekosistem aplikasi yang berkelanjutan dan dapat dimonetisasi:**
   - Melalui model berlangganan, komisi transaksi, dan fitur premium.
   - Memberikan keuntungan finansial bagi pengembang dan Business Owner yang menyewakan sistem.

---

## 👥 3. Target Pengguna

| Tipe Pengguna | Deskripsi |
|----------------|------------|
| **Pelanggan** | Pengunjung yang memesan makanan/minuman dari tenant menggunakan QR Code |
| **Tenant/Penyewa** | Pemilik warung/burjo/kantin yang mengelola menu dan menerima pesanan |
| **Business Owner / Pengelola Area** | Pemilik rest area, ruko, atau kantin yang menyewakan sistem ke tenant dan memantau seluruh aktivitas |

---

## ⚙️ 4. Fitur Utama

| Kategori | Fitur | Deskripsi |
|-----------|--------|------------|
| **A. Pelanggan** | Scan QR tanpa login | Pelanggan langsung masuk ke halaman menu tenant |
|  | Pesan makanan/minuman | Pilih menu, tambah catatan, dan kirim pesanan |
|  | Notifikasi status pesanan | Pelanggan tahu kapan pesanan siap diambil |
| **B. Tenant / Admin** | Manajemen menu | Tambah, ubah, dan hapus menu |
|  | Dashboard pesanan | Melihat pesanan masuk, status, dan total transaksi |
|  | QR unik otomatis | Setiap tenant mendapat QR berbeda otomatis saat akun dibuat |
| **C. Business Owner** | Manajemen penyewa | Menambahkan dan mengelola tenant dari dashboard pusat |
|  | Laporan global | Melihat performa penjualan tiap tenant |
|  | Kontrol langganan | Mengatur paket berlangganan dan status aktif tenant |

---

## 🔁 5. Alur Logika Sistem (Logic Flow)

```mermaid
flowchart TD
    A[Business Owner] -->|Membuat akun Tenant baru| B[Generate QR unik otomatis]
    B --> C[QR dicetak & ditempel di meja Tenant]
    C --> D[Pelanggan scan QR]
    D --> E[Masuk ke halaman menu tanpa login]
    E --> F[Pilih menu & kirim pesanan]
    F --> G[Pesanan masuk ke dashboard Tenant]
    G --> H[Tenant proses & ubah status pesanan]
    H --> I[Pelanggan mendapat notifikasi pesanan siap]
    I --> J[Data transaksi tersimpan ke sistem]