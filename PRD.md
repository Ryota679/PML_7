### **Dokumen Persyaratan Produk (PRD): Aplikasi Kantin Multi-Tenant**

*   **Versi:** 1.0
*   **Tanggal:** 17 September 2025
*   **Status:** Draft Final
*   **Penulis:** Karima

---

### **1. Tinjauan & Visi Produk**

**1.1. Masalah yang Diselesaikan**
Kantin tradisional, terutama di lingkungan perkantoran atau kampus yang padat, sering mengalami inefisiensi: antrean panjang saat jam sibuk, kesulitan bagi pembeli untuk mengetahui menu yang tersedia tanpa mengunjungi setiap tenant, dan kesulitan bagi pemilik tenant untuk mengelola pesanan yang menumpuk. Pemilik kantin (owner) juga tidak memiliki data terpusat mengenai kinerja penjualan.

**1.2. Visi Produk**
Menciptakan sebuah platform digital kantin yang terintegrasi untuk menyederhanakan proses pemesanan makanan. Aplikasi ini akan menghubungkan Pembeli, Pemilik Tenant, dan Owner Kantin dalam satu ekosistem yang mulus, meningkatkan efisiensi operasional, meningkatkan penjualan tenant, dan memberikan pengalaman yang nyaman bagi pembeli.

**1.3. Lingkup Awal (Versi 1.0)**
Versi awal ini akan berfokus pada fungsionalitas inti pemesanan dan pengelolaan. Fitur-fitur canggih seperti pembayaran digital terintegrasi, layanan pengantaran, dan sistem rating akan dipertimbangkan untuk rilis mendatang. Pembayaran pada V1 diasumsikan dilakukan secara tunai saat pengambilan pesanan.

---

### **2. Tujuan & Sasaran**

| Kategori | Tujuan | Metrik Keberhasilan Utama |
| :--- | :--- | :--- |
| **Bisnis** | Meningkatkan efisiensi operasional kantin dan total transaksi. | Peningkatan jumlah total pesanan harian sebesar 20% dalam 3 bulan pasca-peluncuran. |
| | Memberikan alat kontrol dan pemantauan terpusat bagi Owner. | Owner login ke dasbor analitik setidaknya 3 kali seminggu. |
| **Pengguna (Tenant)** | Meningkatkan penjualan dan mengurangi kesalahan pemrosesan pesanan. | Peningkatan jumlah pesanan per tenant. Waktu rata-rata dari pesanan masuk hingga siap diambil < 15 menit. |
| **Pengguna (Pembeli)** | Memberikan pengalaman memesan yang cepat, mudah, dan bebas antre. | Tingkat retensi pengguna bulanan > 40%. Waktu rata-rata dari membuka aplikasi hingga pesanan terkonfirmasi < 3 menit. |

---

### **3. Persona Pengguna**

**3.1. Owner (Pak Budi - Administrator)**
*   **Deskripsi:** Manajer pengelola gedung/kantin, usia 45+. Cukup paham bisnis tetapi tidak terlalu teknis.
*   **Tujuan:** Ingin kantin berjalan lebih modern dan efisien. Membutuhkan kontrol penuh atas siapa saja yang berjualan dan ingin melihat data penjualan secara keseluruhan untuk mengambil keputusan bisnis.
*   **Frustrasi:** Sulit melacak performa masing-masing tenant. Proses pendaftaran tenant baru tidak terstandarisasi.

**3.2. Pemilik Tenant (Ibu Wati - Penjual)**
*   **Deskripsi:** Pemilik warung soto, usia 35+. Sangat sibuk, terutama saat jam makan siang.
*   **Tujuan:** Ingin pesanan terus datang tanpa harus berteriak-teriak. Perlu cara mudah untuk memberitahu pelanggan jika sotonya habis.
*   **Frustrasi:** Sering salah mencatat pesanan saat ramai. Kehilangan pelanggan karena antrean yang terlalu panjang.

**3.3. Pembeli (Rian - Pelanggan)**
*   **Deskripsi:** Karyawan kantor/mahasiswa, usia 25+. Melek teknologi, memiliki waktu istirahat yang terbatas.
*   **Tujuan:** Ingin memesan makan siang dengan cepat tanpa membuang waktu untuk antre. Ingin tahu menu apa saja yang tersedia hari ini sebelum berjalan ke kantin.
*   **Frustrasi:** Waktu istirahat habis hanya untuk antre makanan. Sudah antre lama, ternyata makanan yang diinginkan sudah habis.

---

### **4. Rincian Fitur Fungsional**

Ini adalah daftar fitur yang akan diimplementasikan, diorganisir berdasarkan peran pengguna.

#### **4.1. Fungsionalitas Umum**
*   **Autentikasi:**
    *   Pengguna dapat login menggunakan email dan password.
    *   Sistem dapat membedakan peran (Owner, Tenant, Pembeli) saat login dan mengarahkan ke antarmuka yang sesuai.
    *   Pengguna dapat menggunakan fitur "Lupa Password" untuk mereset password melalui email.
*   **Pendaftaran:**
    *   Pembeli dapat mendaftar akun baru melalui form pendaftaran di aplikasi.
    *   Tenant **tidak dapat** mendaftar sendiri. Akun tenant dibuat secara eksklusif oleh Owner melalui dasbornya.
*   **Notifikasi:**
    *   Sistem akan mengirimkan notifikasi *push* untuk pembaruan status pesanan yang krusial.

#### **4.2. Fitur Peran: Owner**
*   **Dasbor Analitik:**
    *   Menampilkan ringkasan pendapatan total, jumlah pesanan, dan tenant aktif.
    *   Menampilkan grafik penjualan dan daftar tenant terlaris.
*   **Manajemen Tenant:**
    *   Dapat membuat akun tenant baru dengan mengisi form (Nama Toko, Nama Pemilik, Email, dll.).
    *   Setelah dibuat, sistem akan mengirimkan email ke tenant untuk mengatur password awal.
    *   Dapat melihat daftar semua tenant dan menonaktifkan/mengaktifkan akun mereka.
*   **Manajemen Kategori Global:**
    *   Dapat membuat, mengedit, dan menghapus kategori makanan (misal: Makanan Berat, Minuman, Cemilan).

#### **4.3. Fitur Peran: Pemilik Tenant**
*   **Manajemen Pesanan Real-time:**
    *   Menerima notifikasi dan melihat pesanan baru masuk di dasbor secara real-time.
    *   Dapat mengubah status pesanan: Terima, Tolak, Sedang Disiapkan, Siap Diambil.
    *   Setiap perubahan status akan memicu notifikasi ke Pembeli.
*   **Manajemen Menu/Produk:**
    *   Dapat melakukan CRUD (Create, Read, Update, Delete) untuk produk di menu mereka.
    *   Setiap produk memiliki atribut: Nama, Foto, Harga, Deskripsi, dan Kategori (memilih dari daftar yang dibuat Owner).
    *   Terdapat tombol *toggle* untuk mengubah status ketersediaan produk (Tersedia/Habis) dengan cepat.
*   **Profil Toko:**
    *   Dapat mengatur jam operasional (buka/tutup) dan deskripsi toko.

#### **4.4. Fitur Peran: Pembeli**
*   **Penjelajahan Menu:**
    *   Dapat melihat daftar semua tenant yang aktif beserta status buka/tutupnya.
    *   Dapat mencari makanan atau tenant secara spesifik.
    *   Dapat memfilter menu berdasarkan kategori global.
*   **Keranjang Belanja & Checkout:**
    *   Dapat menambahkan beberapa item dari satu tenant ke dalam keranjang.
    *   Dapat meninjau pesanan dan total harga di halaman keranjang.
    *   Dapat menyelesaikan pesanan melalui alur checkout sederhana.
*   **Pelacakan Pesanan:**
    *   Setelah memesan, dapat melihat status pesanan secara real-time di halaman khusus.
    *   Menerima notifikasi saat pesanan siap diambil.
*   **Riwayat Pesanan:**
    *   Dapat melihat daftar pesanan yang telah selesai atau dibatalkan.
    *   Terdapat fitur "Pesan Lagi" untuk mengulang pesanan sebelumnya dengan cepat.

---

### **5. Persyaratan Non-Fungsional**

*   **Kinerja:** Aplikasi harus ringan dan responsif. Waktu muat halaman menu dan daftar tenant harus di bawah 2 detik pada koneksi 4G standar.
*   **Usabilitas:** Antarmuka harus intuitif dan mudah digunakan, bahkan oleh pengguna yang tidak terlalu akrab dengan teknologi (khususnya untuk peran Tenant). Alur pemesanan untuk Pembeli harus dapat diselesaikan dalam minimal klik.
*   **Keamanan:** Data pengguna (terutama password) harus di-hash dan disimpan dengan aman. Komunikasi antara aplikasi dan server harus melalui HTTPS.
*   **Reliabilitas:** Sistem harus memiliki uptime tinggi, terutama selama jam sibuk (11:00 - 14:00). Notifikasi pesanan harus terkirim secara instan (< 10 detik).
*   **Arsitektur:** Aplikasi akan dikembangkan menggunakan Flutter dengan Clean Architecture untuk memastikan kode yang terstruktur, mudah diuji, dan dapat dipelihara.

---

### **6. Asumsi & Batasan**

*   **Asumsi:**
    *   Semua pengguna memiliki smartphone (Android/iOS) dengan koneksi internet yang memadai di area kantin.
    *   Owner dan Tenant bersedia untuk dilatih dalam menggunakan aplikasi.
*   **Batasan:**
    *   Versi 1.0 tidak akan menyertakan integrasi gateway pembayaran. Semua transaksi bersifat tunai (Cash on Pickup).
    *   Aplikasi tidak menangani logistik pengantaran; fokus pada model "pesan-ambil" (order and pickup).
    *   Tumpukan teknologi telah ditentukan: Flutter, Riverpod Generator, Freezed, GoRouter, FPdart, Logger, Drift.

---

### **7. Di Luar Cakupan (Out of Scope untuk V1.0)**

Fitur-fitur berikut secara eksplisit **TIDAK AKAN** dibangun di versi awal, tetapi dapat dipertimbangkan untuk masa depan:

*   Sistem rating dan ulasan untuk tenant dan makanan.
*   Fitur promo, diskon, dan voucher.
*   Manajemen inventaris bahan baku untuk tenant.
*   Sistem dompet digital atau pembayaran online.
*   Fitur pesan langsung (chat) antara Pembeli dan Tenant.
*   Layanan pengantaran (delivery).

---

### **8. Lampiran (Placeholder)**

*   (Link ke Desain UI/UX di Figma/Sketch akan ditambahkan di sini)
*   (Link ke Dokumen Desain Arsitektur Teknis akan ditambahkan di sini)