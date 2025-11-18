### **Roadmap & Prioritas MVP: Aplikasi Kantin Multi-Tenant (8 Minggu)**

**Total Estimasi Durasi MVP:** 4 Sprints (8 Minggu)
**Backend Platform:** Appwrite

Roadmap ini dipecah menjadi 4 Sprint, masing-masing berisi daftar tugas yang diurutkan berdasarkan prioritas pengerjaan (misal: 1.1, 1.2) untuk memastikan dependensi fitur terpenuhi.

---

#### **Sprint 1: Fondasi & Autentikasi (Minggu 1-2)**
**Tujuan Sprint:** Menyiapkan infrastruktur Appwrite dan mengimplementasikan alur login yang fungsional untuk peran `owner_business` dan `tenant`.

* **[1.1] [Appwrite]** Setup proyek di Appwrite Cloud.
* **[1.2] [Appwrite]** Buat koleksi database inti: `users`, `tenants`, `categories`, `products`, `orders` (sesuai `data_collections.md`).
* **[1.3] [Appwrite]** Konfigurasi Appwrite Authentication.
* **[1.4] [Appwrite]** Definisikan alur onboarding untuk `owner_business` (MVP: Pembuatan akun manual oleh System Admin via Appwrite Console).
* **[1.5] [Front-end]** Setup proyek Flutter, arsitektur, dependensi, dan integrasikan **Appwrite SDK**.
* **[1.6] [Front-end]** Buat UI untuk halaman Login.
* **[1.7] [Front-end]** Integrasikan UI dengan **Appwrite Authentication** (login, logout, session management).
* **[1.8] [Front-end]** Implementasikan pengalihan rute (Routing) berdasarkan status login dan `role` dari koleksi `users`.

---

#### **Sprint 2: Manajemen Konten (Business Owner & Tenant) (Minggu 3-4)**
**Tujuan Sprint:** Memberikan kemampuan kepada `owner_business` untuk membuat tenant dan akun admin tenant (`users`), dan `tenant` untuk mengisi menu mereka.

* **[2.1] [Appwrite]** Buat **Appwrite Function** `createTenant` (membuat dokumen di koleksi `tenants`).
* **[2.2] [Appwrite]** Buat **Appwrite Function** `createTenantUser` (membuat user di Auth dan dokumen di `users` dengan peran `tenant`).
* **[2.3] [Front-end]** Buat UI Dasbor `Business Owner` untuk mengelola `tenants` (Form Tambah/Edit: Nama, Jenis, Deskripsi).
* **[2.4] [Front-end]** Integrasikan UI `Business Owner` (Manajemen Tenant) untuk memanggil *function* `createTenant`.
* **[2.5] [Front-end]** Buat UI `Business Owner` untuk membuat akun `users` (Form: Email, Username, Password, `tenant_id` dropdown, `contract_end_date`).
* **[2.6] [Front-end]** Integrasikan UI `Business Owner` (Manajemen User) untuk memanggil *function* `createTenantUser`.
* **[2.7] [Appwrite]** Atur izin (document-level) pada koleksi `products` dan `categories` agar hanya bisa di-CRUD oleh `tenant` yang bersangkutan.
* **[2.8] [Front-end]** Buat UI Dasbor `Tenant` untuk mengelola `products` (CRUD & toggle ketersediaan).
* **[2.9] [Front-end]** Integrasikan UI `Tenant` (Manajemen Products) langsung ke Appwrite Database.

---

#### **Sprint 3: Alur Inti Pembeli (End-to-End) (Minggu 5-6)**
**Tujuan Sprint:** Pembeli (Guest Anonim) dapat melakukan alur pemesanan tanpa login, mulai dari scan QR hingga berhasil membuat pesanan.

* **[3.1] [Appwrite]** Atur izin koleksi `tenants` dan `products` agar dapat dibaca oleh **pengguna anonim (publik)**.
* **[3.2] [Front-end]** Buat UI Halaman Menu Tenant Publik (diakses via QR code/`tenant_id`).
* **[3.3] [Front-end]** Implementasikan fungsi "Tambah ke Keranjang" (Manajemen State Lokal, misal: Riverpod/Drift).
* **[3.4] [Front-end]** Buat UI Halaman Keranjang Belanja dan Halaman Checkout (Form Nama Pelanggan).
* **[3.5] [Appwrite]** Buat **Appwrite Function** `createOrder` untuk memvalidasi keranjang dan membuat dokumen pesanan baru.
* **[3.6] [Front-end]** Integrasikan alur checkout (Tombol "Pesan Sekarang") untuk memanggil Appwrite Function `createOrder`.
* **[3.7] [Front-end]** Arahkan ke halaman "Pelacakan Pesanan" (statis untuk saat ini, hanya menunjukkan status "pending").

---

#### **Sprint 4: Siklus Pesanan & Stabilisasi (Minggu 7-8)**
**Tujuan Sprint:** Menutup siklus pesanan, memastikan Tenant dapat memprosesnya, dan Pembeli mendapat update status secara *real-time*.

* **[4.1] [Appwrite]** Buat **Appwrite Function** `updateOrderStatus` (untuk digunakan oleh Tenant mengganti status: `preparing`, `ready_for_pickup`, dll.).
* **[4.2] [Appwrite]** Konfigurasi **Appwrite Realtime** pada koleksi `orders` (untuk *listen* perubahan status).
* **[4.3] [Appwrite]** Atur izin baca pada koleksi `orders` (Tenant hanya melihat pesanan miliknya, Pembeli anonim melacak via ID pesanan).
* **[4.4] [Front-end]** Buat UI "Manajemen Pesanan" untuk `Tenant`, yang *listen* ke update **realtime** untuk pesanan baru.
* **[4.5] [Front-end]** Integrasikan tombol di UI Tenant (misal: "Siapkan Pesanan", "Siap Diambil") untuk memanggil *function* `updateOrderStatus`.
* **[4.6] [Front-end]** Sempurnakan UI "Lacak Pesanan" untuk `Guest` agar *listen* ke update **realtime** dari Appwrite.
* **[4.7] [Umum]** Lakukan **smoke testing** menyeluruh (Alur Owner, Tenant, dan Guest).
* **[4.8] [Umum]** Prioritaskan dan perbaiki **bug pemblokir (blocker bugs)**.
* **[4.9] [Umum]** Siapkan build aplikasi untuk demonstrasi.
```eof