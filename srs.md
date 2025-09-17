### **Spesifikasi Kebutuhan Perangkat Lunak (SRS): Aplikasi Kantin Multi-Tenant**

*   **Versi:** 1.0
*   **Tanggal:** 17 September 2025
*   **Status:** Final
*   **Penyusun:** Karima

---

### **1. Pendahuluan**

#### **1.1 Tujuan**
Dokumen ini bertujuan untuk memberikan spesifikasi yang detail dan komprehensif mengenai kebutuhan fungsional dan non-fungsional untuk pengembangan Aplikasi Kantin Multi-Tenant Versi 1.0. Dokumen ini akan menjadi acuan utama bagi tim pengembang, penguji (tester), dan manajer proyek selama siklus hidup pengembangan perangkat lunak.

#### **1.2 Ruang Lingkup Produk**
Perangkat lunak ini adalah aplikasi seluler (Android & iOS) yang berfungsi sebagai platform pemesanan makanan untuk sebuah kantin dengan banyak penjual (tenant). Sistem akan melayani tiga peran pengguna utama:
1.  **Pembeli:** Pelanggan yang memesan makanan.
2.  **Pemilik Tenant:** Penjual makanan yang mengelola menu dan pesanan.
3.  **Owner:** Administrator kantin yang mengelola tenant dan memantau keseluruhan sistem.

**Di luar ruang lingkup (Out of Scope) untuk Versi 1.0 adalah:**
*   Integrasi gateway pembayaran online.
*   Sistem rating dan ulasan.
*   Layanan pengantaran (delivery).
*   Fitur promosi dan diskon.

#### **1.3 Definisi, Akronim, dan Singkatan**
*   **SRS:** Software Requirements Specification (Dokumen ini).
*   **PRD:** Product Requirements Document.
*   **ERD:** Entity-Relationship Diagram.
*   **ORM:** Object-Relational Mapper.
*   **API:** Application Programming Interface.
*   **CRUD:** Create, Read, Update, Delete.
*   **UI/UX:** User Interface / User Experience.

#### **1.4 Referensi**
*   Dokumen Visi & PRD Aplikasi Kantin Multi-Tenant v1.0
*   Dokumen Desain Skema Database v1.2

#### **1.5 Tinjauan Dokumen**
Dokumen ini terdiri dari tiga bagian utama: Pendahuluan, Deskripsi Umum, dan Kebutuhan Spesifik. Bagian Kebutuhan Spesifik akan merinci semua kebutuhan fungsional, non-fungsional, antarmuka, dan database yang diperlukan untuk membangun aplikasi.

---

### **2. Deskripsi Umum**

#### **2.1 Perspektif Produk**
Aplikasi ini adalah sistem mandiri yang terdiri dari aplikasi seluler (front-end) untuk pengguna dan server (back-end) yang menyediakan API. Aplikasi seluler akan dikembangkan menggunakan Flutter untuk menargetkan platform Android dan iOS dari satu basis kode.

#### **2.2 Fungsi Produk**
Fungsi utama perangkat lunak ini adalah:
*   **Untuk Pembeli:** Memfasilitasi penemuan menu, pemesanan, pembayaran (secara tunai), dan pelacakan status pesanan.
*   **Untuk Tenant:** Menyediakan alat untuk mengelola etalase digital (menu), memproses pesanan masuk secara real-time, dan melacak riwayat penjualan.
*   **Untuk Owner:** Memberikan dasbor untuk mengelola tenant, mengontrol kategori makanan, dan memantau aktivitas penjualan di seluruh kantin.

#### **2.3 Karakteristik Pengguna**
*   **Owner:** Memiliki pemahaman bisnis, membutuhkan kontrol dan data. Tidak harus sangat melek teknologi.
*   **Pemilik Tenant:** Sibuk, membutuhkan alur kerja yang sangat cepat dan efisien untuk mengelola pesanan, terutama saat jam sibuk.
*   **Pembeli:** Melek teknologi, memiliki waktu terbatas, dan mengharapkan pengalaman aplikasi yang cepat dan mulus.

#### **2.4 Batasan**
1.  Aplikasi harus dikembangkan menggunakan tumpukan teknologi yang telah ditentukan: Flutter, Riverpod, Freezed, GoRouter, Drift.
2.  Sistem back-end harus menyediakan RESTful API dengan format data JSON.
3.  Database lokal pada aplikasi seluler harus menggunakan SQLite yang dikelola oleh Drift.
4.  Sistem pembayaran untuk V1.0 terbatas pada **Bayar Tunai di Tempat (Cash on Pickup)**.

#### **2.5 Asumsi dan Ketergantungan**
1.  Diasumsikan semua pengguna memiliki akses ke smartphone dan koneksi internet yang stabil di area kantin.
2.  Keberhasilan notifikasi real-time bergantung pada layanan pihak ketiga (misalnya, Firebase Cloud Messaging) dan izin notifikasi dari pengguna.

---

### **3. Kebutuhan Spesifik**

#### **3.1 Kebutuhan Fungsional**

**FR-AUTH: Modul Autentikasi**
*   **FR-AUTH-01:** Sistem harus menyediakan halaman login untuk semua pengguna menggunakan email dan password.
*   **FR-AUTH-02:** Sistem harus dapat mengidentifikasi peran pengguna setelah login berhasil dan mengarahkannya ke antarmuka yang sesuai.
*   **FR-AUTH-03:** Sistem harus menyediakan fitur "Lupa Password" yang mengirimkan tautan reset ke email pengguna terdaftar.
*   **FR-AUTH-04:** Pengguna dengan peran **Pembeli** harus dapat mendaftarkan akun baru melalui form registrasi.

**FR-OWN: Modul Owner**
*   **FR-OWN-01:** Owner harus dapat melihat dasbor yang menampilkan statistik penjualan total, jumlah pesanan, dan tenant aktif.
*   **FR-OWN-02:** Owner harus dapat **membuat** akun Tenant baru melalui form di dasbornya.
*   **FR-OWN-03:** Owner harus dapat melihat daftar semua tenant dan mengubah status mereka (`active`/`inactive`).
*   **FR-OWN-04:** Owner harus dapat melakukan operasi CRUD pada tabel **Kategori Makanan Global**.

**FR-TEN: Modul Tenant**
*   **FR-TEN-01:** Tenant harus dapat melihat dasbor yang menampilkan ringkasan pesanan (baru, diproses, selesai) dan pendapatan harian.
*   **FR-TEN-02:** Tenant harus menerima notifikasi real-time untuk setiap pesanan baru yang masuk.
*   **FR-TEN-03:** Tenant harus dapat mengubah status pesanan menjadi: `preparing`, `ready_for_pickup`, `completed`, atau `cancelled`.
*   **FR-TEN-04:** Tenant harus dapat melakukan operasi CRUD pada **Produk** miliknya.
*   **FR-TEN-05:** Tenant harus dapat mengubah status ketersediaan (`is_available`) untuk setiap produknya dengan cepat (misalnya, melalui toggle).

**FR-BUY: Modul Pembeli**
*   **FR-BUY-01:** Pembeli harus dapat melihat daftar semua tenant yang aktif beserta status buka/tutupnya.
*   **FR-BUY-02:** Pembeli harus dapat mencari produk atau tenant berdasarkan nama.
*   **FR-BUY-03:** Pembeli harus dapat memfilter produk berdasarkan kategori global.
*   **FR-BUY-04:** Pembeli harus dapat menambahkan, mengubah kuantitas, dan menghapus item dari keranjang belanja. Keranjang hanya untuk satu tenant per checkout.
*   **FR-BUY-05:** Pembeli harus dapat menyelesaikan pesanan (checkout).
*   **FR-BUY-06:** Pembeli harus dapat melihat halaman pelacakan pesanan aktif yang statusnya diperbarui secara real-time.
*   **FR-BUY-07:** Pembeli harus menerima notifikasi saat status pesanannya berubah menjadi `ready_for_pickup` atau `cancelled`.

#### **3.2 Kebutuhan Non-Fungsional**

**NFR-PERF: Kinerja**
*   **NFR-PERF-01:** Waktu muat aplikasi dari cold start hingga halaman utama tampil harus < 3 detik.
*   **NFR-PERF-02:** Transisi antar halaman harus terasa instan (< 500 ms).
*   **NFR-PERF-03:** Latensi pembaruan status pesanan (dari aksi Tenant hingga terlihat di layar Pembeli) harus < 5 detik.

**NFR-SEC: Keamanan**
*   **NFR-SEC-01:** Semua password pengguna harus di-hash menggunakan algoritma modern (misal: bcrypt) sebelum disimpan di database.
*   **NFR-SEC-02:** Semua komunikasi antara aplikasi klien dan server API harus dienkripsi menggunakan HTTPS/TLS.
*   **NFR-SEC-03:** Sistem harus menerapkan kontrol akses berbasis peran (Role-Based Access Control) untuk memastikan pengguna hanya bisa mengakses data dan fungsi yang sesuai dengan perannya.

**NFR-USAB: Usabilitas**
*   **NFR-USAB-01:** Antarmuka harus mengikuti pedoman desain platform (Material Design untuk Android, Cupertino untuk iOS) untuk memastikan keakraban pengguna.
*   **NFR-USAB-02:** Alur kerja utama (misal: pemesanan oleh Pembeli, proses pesanan oleh Tenant) harus dapat diselesaikan dengan jumlah klik/interaksi minimal.

**NFR-REL: Reliabilitas**
*   **NFR-REL-01:** Aplikasi harus dapat menangani kondisi offline atau koneksi internet yang tidak stabil dengan memberikan umpan balik yang jelas kepada pengguna dan menyimpan state lokal (misalnya, isi keranjang) jika memungkinkan.

#### **3.3 Kebutuhan Database**
Sistem akan menggunakan database relasional dengan skema yang telah didefinisikan. Tabel utama yang harus ada adalah sebagai berikut:
*   `users`: Menyimpan data semua pengguna dan perannya.
*   `tenants`: Menyimpan profil toko, terhubung ke `users`.
*   `categories`: Tabel master kategori yang dikelola Owner.
*   `products`: Daftar menu, terhubung ke `tenants` dan `catVegories`.
*   `orders`: Header transaksi, terhubung ke `users` (pembeli) dan `tenants`.
*   `order_items`: Detail item per transaksi, terhubung ke `orders` dan `products`.

(Detail lengkap skema dan relasi dapat dilihat pada Dokumen Desain Skema Database v1.2)