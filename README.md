# 🍽️ Tenant QR-Order App

Aplikasi pemesanan makanan/minuman berbasis QR Code untuk area kuliner multi-tenant (kantin, ruko kuliner, rest area, burjo).

## 📱 Tentang Aplikasi

**Tenant QR-Order** adalah sistem pemesanan digital yang memungkinkan:
- **Pelanggan**: Memesan tanpa login, cukup scan QR code
- **Tenant**: Mengelola menu dan menerima pesanan real-time
- **Business Owner**: Mengelola tenant dan melihat laporan penjualan

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Drift (SQLite)
- **Backend**: Appwrite (BaaS)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- Appwrite Cloud account (atau self-hosted)
- IDE (VS Code, Android Studio, atau IntelliJ IDEA)

### Installation

1. Clone repository:
   ```bash
   git clone <repository-url>
   cd kantin_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup Appwrite:
   - Lihat panduan lengkap di [SETUP_APPWRITE.md](SETUP_APPWRITE.md)
   - Update kredensial di `lib/core/config/appwrite_config.dart`

4. Run aplikasi:
   ```bash
   flutter run
   ```

## 📁 Struktur Folder

```
lib/
├── core/                    # Core application files
│   ├── config/             # App configuration
│   ├── constants/          # App constants
│   ├── router/             # GoRouter configuration
│   ├── theme/              # App theme
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── business_owner/    # Business Owner features
│   ├── tenant/            # Tenant features
│   └── guest/             # Guest/Customer features
└── shared/                # Shared resources
    ├── models/            # Data models
    ├── providers/         # Global providers
    └── widgets/           # Reusable widgets
```

## 🔐 Default Login (Testing)

Setelah setup Appwrite selesai:

**Business Owner**:
- Email: `owner@test.com`
- Password: `password123`

**Tenant**:
- Email: `tenant@test.com`
- Password: `password123`

## 📋 Sprint Progress

### ✅ Sprint 1: Fondasi & Autentikasi (Current)
- [x] Setup proyek Flutter
- [x] Struktur folder arsitektur
- [x] Konfigurasi Appwrite
- [x] UI Login
- [x] Integrasi Authentication
- [x] Routing berdasarkan role
- [x] Business Owner & Tenant Dashboard (placeholder)

### 🔄 Sprint 2: Manajemen Konten (Next)
- [ ] CRUD Tenant (Business Owner)
- [ ] CRUD User Tenant (Business Owner)
- [ ] CRUD Products (Tenant)
- [ ] Appwrite Functions

### ⏳ Sprint 3: Alur Pembeli
- [ ] Halaman menu publik (Guest)
- [ ] Keranjang belanja
- [ ] Checkout & pelacakan pesanan

### ⏳ Sprint 4: Siklus Pesanan & Stabilisasi
- [ ] Dashboard pesanan real-time (Tenant)
- [ ] Update status pesanan
- [ ] Testing & bug fixing

## 📚 Dokumentasi

Dokumentasi lengkap tersedia di folder `Iterasi/`:
- **PRD.md**: Product Requirements Document
- **SRS.md**: Software Requirements Specification
- **SDD.md**: Software Design Document
- **erd.md**: Entity Relationship Diagram & Database Schema
- **Ceklist iterasi.md**: Roadmap & Timeline MVP

## 🤝 Contributing

Untuk kontribusi, silakan ikuti guidelines:
1. Fork repository
2. Buat branch untuk feature (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 License

Project ini dibuat untuk keperluan akademik (Semester 6 - PML).

## 📞 Support

Jika ada pertanyaan atau issue, silakan buat issue di repository atau hubungi tim development.
