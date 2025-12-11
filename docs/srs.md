### 3. Spesifikasi Kebutuhan Perangkat Lunak (srs.md)
*(Peran diperbarui dan diklarifikasi)*

```markdown:Spesifikasi Kebutuhan Perangkat Lunak:srs.md
### **Spesifikasi Kebutuhan Perangkat Lunak (SRS): Aplikasi Tenant QR-Order**

* **Versi:** 1.3
* **Tanggal:** 18 November 2025
* **Status:** Revisi (Memperbarui Role Enum)
* **Penyusun:** Gemini

---

### **1. Pendahuluan**

#### **1.1 Tujuan**
Dokumen ini bertujuan untuk memberikan spesifikasi yang detail dan komprehensif mengenai kebutuhan fungsional dan non-fungsional untuk pengembangan Aplikasi Tenant QR-Order.

#### **1.2 Ruang Lingkup Produk**
Perangkat lunak ini adalah aplikasi seluler (Android & iOS). Sistem akan melayani peran pengguna utama:
1.  **Guest (Anonim):** Pelanggan akhir yang memesan tanpa login.
2.  **Guest (Terdaftar):** (Opsional/Masa Depan) Pelanggan yang memiliki akun (peran `guest` di koleksi `users`) untuk menyimpan riwayat pesanan.
3.  **Tenant:** Pengguna operasional yang mengelola menu dan pesanan (peran `tenant`).
4.  **Business Owner:** Klien yang berlangganan sistem (peran `owner_business`).
5.  **System Admin:** Administrator platform (via konsol Appwrite).

**Di luar ruang lingkup (Out of Scope) untuk Versi 1.0 adalah:**
* Integrasi gateway pembayaran online.
* Alur login penuh untuk peran `guest`.
* Sistem rating dan ulasan.
* Layanan pengantaran (delivery).
* Fitur promosi dan diskon.

#### **1.3 Definisi, Akronim, dan Singkatan**
* **SRS:** Software Requirements Specification.
* **PRD:** Product Requirements Document.
* **SDD:** Software Design Document.
* **BaaS:** Backend as a Service.

#### **1.4 Referensi**
* Product Requirements Document (PRD) v1.0
* Software Design Document (SDD) v1.6
* Ceklist Iterasi v1.2
* Spesifikasi Koleksi Data (data_collections.md)

---

### **2. Deskripsi Umum**

#### **2.1 Perspektif Produk**
Aplikasi ini adalah sistem mandiri yang terdiri dari aplikasi seluler (front-end) dan platform **Backend as a Service (Appwrite)**.

#### **2.2 Fungsi Produk**
* **Untuk Guest (Anonim):** Memfasilitasi pemesanan menu tanpa perlu login, hanya dengan memindai QR code, dan melacak status pesanan secara real-time.
* **Untuk Tenant:** Menyediakan dasbor untuk mengelola produk (menu), memproses pesanan masuk, dan melihat riwayat transaksi harian.
* **Untuk Business Owner:** Memberikan dasbor untuk mengelola akun tenant, mengelola akun staff tenant (users), dan memantau performa penjualan.

#### **2.3 Karakteristik Pengguna**
* **Business Owner:** Membutuhkan kontrol atas bisnisnya dan data penjualan.
* **Tenant:** Membutuhkan alur kerja yang cepat dan efisien.
* **Guest (Anonim):** Mengharapkan pengalaman pemesanan yang instan, tanpa hambatan registrasi.

#### **2.4 Batasan**
1.  Aplikasi klien harus dikembangkan menggunakan Flutter, Riverpod, GoRouter, dan Drift.
2.  Sistem backend **harus** menggunakan **Appwrite** sebagai platform BaaS.
3.  Pembayaran V1.0 terbatas pada **Bayar Tunai di Tempat (Cash on Pickup)**.

---

### **3. Kebutuhan Spesifik**

#### **3.1 Kebutuhan Fungsional**

**FR-AUTH: Modul Autentikasi**
* **FR-AUTH-01:** Sistem harus menyediakan halaman login untuk peran `owner_business` dan `tenant`.
* **FR-AUTH-02:** Sistem harus dapat mengidentifikasi peran pengguna (`role` di koleksi `users`) setelah login dan mengarahkannya ke dasbor yang sesuai.
* **FR-AUTH-03:** Sistem harus menyediakan fitur "Lupa Password".
* **FR-AUTH-04:** Sistem **tidak boleh** mengharuskan `Guest (Anonim)` untuk mendaftar atau login untuk melakukan pemesanan (Alur utama V1.0).

**FR-BIZ: Modul Business Owner (`owner_business`)**
* **FR-BIZ-01:** `Business Owner` harus dapat melihat dasbor statistik penjualan dari semua tenant miliknya.
* **FR-BIZ-02:** `Business Owner` harus dapat membuat, melihat, dan menonaktifkan akun `Tenant` (mengisi Nama, Jenis, Deskripsi).
* **FR-BIZ-03:** `Business Owner` harus dapat membuat akun `Tenant User` (Staf Admin) dengan Email, Username, Password, dan mengaitkannya dengan `tenant_id` tertentu (Admin Tenant/Dropdown).
* **FR-BIZ-04:** `Business Owner` harus dapat menetapkan dan melihat `contract_end_date` untuk setiap Tenant User.
* **FR-BIZ-05:** `Business Owner` harus dapat melakukan CRUD pada kategori produk.

**FR-TEN: Modul Tenant (`tenant`)**
* **FR-TEN-01:** `Tenant` harus dapat melihat dasbor ringkasan pesanan.
* **FR-TEN-02:** `Tenant` harus menerima pembaruan pesanan baru secara **real-time**.
* **FR-TEN-03:** `Tenant` harus dapat mengubah status pesanan (`preparing`, `ready_for_pickup`, `completed`, `cancelled`).
* **FR-TEN-04:** `Tenant` harus dapat melakukan CRUD pada produk miliknya.
* **FR-TEN-05:** `Tenant` harus dapat mengubah status ketersediaan produknya.

**FR-GUEST: Modul Guest (Anonim)**
* **FR-GUEST-01:** Setelah memindai QR code, pengguna harus langsung diarahkan ke halaman menu tenant yang bersangkutan.
* **FR-GUEST-02:** Pengguna harus dapat menambahkan/mengubah/menghapus item dari keranjang belanja.
* **FR-GUEST-03:** Pengguna harus dapat menyelesaikan pesanan (checkout) dengan mengisi informasi minimal (misal: nama).
* **FR-GUEST-04:** Pengguna harus dapat melihat halaman pelacakan pesanan yang statusnya diperbarui secara **real-time**.

#### **3.2 Kebutuhan Non-Fungsional**
(Tidak ada perubahan signifikan, NFR-SEC-01, NFR-PERF-01, dll tetap berlaku)

#### **3.3 Kebutuhan Database**
Sistem akan menggunakan **Appwrite Database (NoSQL)**. Detail koleksi tercantum dalam dokumen `data_collections.md`.
```eof

### 4. Checklist Iterasi (Ceklist iterasi.md)
*(Peran diperbarui menjadi `owner_business`)*

```markdown:Roadmap & Timeline MVP:Ceklist iterasi.md
### **Roadmap & Timeline MVP: Aplikasi Kantin Multi-Tenant (8 Minggu)**

**Total Estimasi Durasi MVP:** 4 Sprints (8 Minggu)
**Backend Platform:** Appwrite (atau BaaS sejenis)

#### **Gantt Chart Visualisasi Sprint**
```mermaid
gantt
    title Roadmap Pembangunan MVP (Versi Akselerasi 8 Minggu)
    dateFormat  YYYY-MM-DD
    section Sprint 1: Fondasi & Autentikasi
    Fondasi & Autentikasi      :done, 2025-09-22, 2w
    section Sprint 2: Manajemen Konten (Business Owner & Tenant)
    Manajemen Konten (Business Owner & Tenant)   :active, 2025-10-06, 2w
    section Sprint 3: Alur Inti Pembeli (End-to-End)
    Alur Inti Pembeli (End-to-End) : 2025-10-20, 2w
    section Sprint 4: Siklus Pesanan & Stabilisasi
    Siklus Pesanan & Stabilisasi : 2025-11-03, 2w