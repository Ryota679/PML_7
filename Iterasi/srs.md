### **Spesifikasi Kebutuhan Perangkat Lunak (SRS): Aplikasi Tenant QR-Order**

*   **Versi:** 1.1
*   **Tanggal:** 31 Oktober 2025
*   **Status:** Revisi
*   **Penyusun:** Gemini

---

### **1. Pendahuluan**

#### **1.1 Tujuan**
Dokumen ini bertujuan untuk memberikan spesifikasi yang detail dan komprehensif mengenai kebutuhan fungsional dan non-fungsional untuk pengembangan Aplikasi Tenant QR-Order. Dokumen ini akan menjadi acuan utama bagi tim pengembang, penguji, dan manajer proyek, dengan fokus pada implementasi menggunakan platform **Appwrite** sebagai backend.

#### **1.2 Ruang Lingkup Produk**
Perangkat lunak ini adalah aplikasi seluler (Android & iOS) yang berfungsi sebagai platform pemesanan makanan siap pakai. Sistem akan melayani empat peran pengguna utama:
1.  **Guest/Public (Pelanggan Akhir):** Pengunjung yang memesan makanan secara anonim melalui pemindaian QR code.
2.  **Tenant (Penyewa/Staf):** Pengguna operasional yang mengelola menu dan pesanan harian.
3.  **Business Owner (Klien/Pemilik Bisnis):** Klien yang berlangganan sistem. Bisa berupa pemilik area multi-tenant (ruko, kantin) atau pemilik bisnis tunggal (kafe, restoran).
4.  **System Admin (Pemilik Aplikasi):** Administrator platform (Anda) yang mengelola sistem secara keseluruhan melalui konsol Appwrite.

**Di luar ruang lingkup (Out of Scope) untuk Versi 1.0 adalah:**
*   Integrasi gateway pembayaran online.
*   Sistem rating dan ulasan.
*   Layanan pengantaran (delivery).
*   Fitur promosi dan diskon.

#### **1.3 Definisi, Akronim, dan Singkatan**
*   **SRS:** Software Requirements Specification.
*   **PRD:** Product Requirements Document.
*   **SDD:** Software Design Document.
*   **BaaS:** Backend as a Service.
*   **SDK:** Software Development Kit.
*   **CRUD:** Create, Read, Update, Delete.

#### **1.4 Referensi**
*   Product Requirements Document (PRD) v1.0
*   Software Design Document (SDD) v1.1
*   Ceklist Iterasi v1.1

#### **1.5 Tinjauan Dokumen**
Dokumen ini terdiri dari tiga bagian utama: Pendahuluan, Deskripsi Umum, dan Kebutuhan Spesifik yang telah disesuaikan dengan arsitektur BaaS.

---

### **2. Deskripsi Umum**

#### **2.1 Perspektif Produk**
Aplikasi ini adalah sistem mandiri yang terdiri dari aplikasi seluler (front-end) dan platform **Backend as a Service (Appwrite)**. Aplikasi seluler akan dikembangkan menggunakan Flutter, sementara semua logika sisi server, database, dan autentikasi akan dikelola oleh Appwrite.

#### **2.2 Fungsi Produk**
*   **Untuk Guest/Public:** Memfasilitasi pemesanan menu tanpa perlu login, hanya dengan memindai QR code, dan melacak status pesanan secara real-time.
*   **Untuk Tenant:** Menyediakan dasbor untuk mengelola produk (menu), memproses pesanan masuk, dan melihat riwayat transaksi harian.
*   **Untuk Business Owner:** Memberikan dasbor untuk mengelola akun tenant, mengontrol kategori produk, dan memantau performa penjualan di semua tenant miliknya.

#### **2.3 Karakteristik Pengguna**
*   **Business Owner:** Membutuhkan kontrol atas bisnisnya dan data penjualan. Tidak harus sangat melek teknologi.
*   **Tenant:** Membutuhkan alur kerja yang cepat dan efisien untuk mengelola pesanan di jam sibuk.
*   **Guest/Public:** Mengharapkan pengalaman pemesanan yang instan, tanpa hambatan registrasi.

#### **2.4 Batasan**
1.  Aplikasi klien harus dikembangkan menggunakan Flutter, Riverpod, GoRouter, dan Drift.
2.  Sistem backend **harus** menggunakan **Appwrite** sebagai platform BaaS.
3.  Database lokal pada klien (untuk keranjang belanja) menggunakan SQLite via Drift.
4.  Sistem pembayaran untuk V1.0 terbatas pada **Bayar Tunai di Tempat (Cash on Pickup)**.

#### **2.5 Asumsi dan Ketergantungan**
1.  Diasumsikan semua pengguna memiliki akses ke smartphone dan koneksi internet.
2.  Keberhasilan notifikasi real-time bergantung sepenuhnya pada layanan **Appwrite Realtime**.

---

### **3. Kebutuhan Spesifik**

#### **3.1 Kebutuhan Fungsional**

**FR-AUTH: Modul Autentikasi**
*   **FR-AUTH-01:** Sistem harus menyediakan halaman login untuk peran `Business Owner` dan `Tenant`.
*   **FR-AUTH-02:** Sistem harus dapat mengidentifikasi peran pengguna setelah login dan mengarahkannya ke dasbor yang sesuai.
*   **FR-AUTH-03:** Sistem harus menyediakan fitur "Lupa Password" untuk pengguna terdaftar.
*   **FR-AUTH-04:** Sistem **tidak boleh** mengharuskan `Guest/Public` (pelanggan) untuk mendaftar atau login untuk melakukan pemesanan.

**FR-BIZ: Modul Business Owner**
*   **FR-BIZ-01:** `Business Owner` harus dapat melihat dasbor statistik penjualan dari semua tenant miliknya.
*   **FR-BIZ-02:** `Business Owner` harus dapat membuat, melihat, dan menonaktifkan akun `Tenant`.
*   **FR-BIZ-03:** `Business Owner` harus dapat melakukan CRUD pada kategori produk untuk bisnisnya.

**FR-TEN: Modul Tenant**
*   **FR-TEN-01:** `Tenant` harus dapat melihat dasbor ringkasan pesanan (baru, diproses, selesai).
*   **FR-TEN-02:** `Tenant` harus menerima pembaruan pesanan baru secara **real-time**.
*   **FR-TEN-03:** `Tenant` harus dapat mengubah status pesanan menjadi: `preparing`, `ready_for_pickup`, `completed`, atau `cancelled`.
*   **FR-TEN-04:** `Tenant` harus dapat melakukan CRUD pada produk miliknya.
*   **FR-TEN-05:** `Tenant` harus dapat mengubah status ketersediaan produknya dengan cepat.

**FR-GUEST: Modul Guest/Public (Pelanggan)**
*   **FR-GUEST-01:** Setelah memindai QR code, pengguna harus langsung diarahkan ke halaman menu tenant yang bersangkutan.
*   **FR-GUEST-02:** Pengguna harus dapat menambahkan, mengubah kuantitas, dan menghapus item dari keranjang belanja.
*   **FR-GUEST-03:** Pengguna harus dapat menyelesaikan pesanan (checkout) dengan mengisi informasi minimal (misal: nama).
*   **FR-GUEST-04:** Pengguna harus dapat melihat halaman pelacakan pesanan yang statusnya diperbarui secara **real-time**.
*   **FR-GUEST-05:** Pengguna harus menerima notifikasi visual di dalam aplikasi saat status pesanannya berubah.

#### **3.2 Kebutuhan Non-Fungsional**

**NFR-PERF: Kinerja**
*   **NFR-PERF-01:** Waktu muat aplikasi (cold start) harus < 3 detik.
*   **NFR-PERF-02:** Latensi pembaruan status pesanan (via Appwrite Realtime) harus < 5 detik.

**NFR-SEC: Keamanan**
*   **NFR-SEC-01:** Keamanan password (hashing, salt) dikelola sepenuhnya oleh layanan **Appwrite Authentication**.
*   **NFR-SEC-02:** Semua komunikasi antara klien dan server Appwrite harus dienkripsi (HTTPS/WSS).
*   **NFR-SEC-03:** Kontrol akses harus diterapkan menggunakan sistem **Permissions** pada level koleksi dan dokumen di Appwrite.

**NFR-USAB: Usabilitas**
*   **NFR-USAB-01:** Alur pemesanan untuk `Guest/Public` harus dapat diselesaikan dalam langkah sesedikit mungkin untuk meminimalkan friksi.

**NFR-REL: Reliabilitas**
*   **NFR-REL-01:** Aplikasi harus dapat menangani koneksi internet yang tidak stabil dan memberikan umpan balik yang jelas kepada pengguna.

#### **3.3 Kebutuhan Database**
Sistem akan menggunakan **Appwrite Database (NoSQL)**. Data akan diorganisir dalam koleksi-koleksi berikut:
*   **Users (via Appwrite Auth):** Menyimpan data pengguna untuk peran `Business Owner` dan `Tenant`. Relasi dan peran dikelola melalui custom claims atau atribut.
*   **Collection `tenants`:** Menyimpan profil setiap tenant/warung, terhubung ke `Business Owner`.
*   **Collection `categories`:** Menyimpan kategori produk, terhubung ke `Business Owner`.
*   **Collection `products`:** Menyimpan item menu, terhubung ke `tenants` dan `categories`.
*   **Collection `orders`:** Menyimpan data transaksi, terhubung ke `tenants`.

(Struktur atribut dan izin detail mengacu pada Dokumen Desain Perangkat Lunak v1.1)