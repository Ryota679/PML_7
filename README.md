# 📱 Kantin App

**Multi-Tenant Canteen Management System with Digital Ordering**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Release](https://img.shields.io/badge/Release-v1.0.0--beta-green.svg)](https://github.com/Ryota679/PML_7/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 About

Kantin App is a comprehensive multi-tenant canteen management system designed for food courts, campus cafeterias, rest areas, and similar multi-vendor food establishments. The platform enables business owners to manage multiple tenants, tenants to manage their products and orders, and customers to place orders seamlessly via QR code scanning.

### Key Capabilities

- **Multi-tenant Architecture** - Manage multiple food vendors from a single platform
- **Digital Menu Management** - Easy-to-use product and category management
- **QR Code Ordering** - Contactless ordering system for customers
- **Real-time Order Tracking** - Live order status updates
- **Role-based Access Control** - Separate dashboards for Business Owners, Tenants, and Staff
- **Web-based Customer Interface** - No app installation required for customers

---

## 🎯 Target Users

| Role | Description |
|------|-------------|
| **Business Owner** | Manages multiple tenants, contracts, and subscriptions |
| **Tenant** | Manages their own products, staff, and receives orders |
| **Staff** | Assists tenants with order management |
| **Customer** | Places orders via QR code (web interface) |

---

## ✨ Features

### 🏢 Business Owner Dashboard
- Multi-tenant management system
- Contract and subscription tracking
- User assignment and permissions
- Performance analytics per tenant
- Tenant activation/deactivation controls

### 🏪 Tenant Dashboard
- Product and category management
- Staff management system
- Unique QR code generation for ordering
- Real-time order dashboard
- Order status management
- Sales analytics

### 👥 Staff Interface
- Order management support
- Product inventory access
- Limited administrative functions

### 🌐 Customer Web Ordering
- QR code access (no login required)
- Browse products by category
- Shopping cart functionality
- Order placement and tracking
- Real-time order status updates
- Order history

---

## 🚀 Quick Start

### Installation

1. Download the latest APK from [Releases](https://github.com/Ryota679/PML_7/releases)
2. Transfer to your Android device
3. Enable "Install from Unknown Sources" in device settings
4. Install the APK

### First Run

1. Open the app
2. Sign in with Google OAuth or create an account
3. Select your role:
   - Business Owner (for establishment managers)
   - Tenant (for food vendors)
   - Staff (for vendor employees)
4. Complete your profile setup
5. Start using the platform!

---

## 📋 System Requirements

**Mobile App (Android):**
- Android 5.0 (API 21) or higher
- Minimum 2GB RAM recommended
- ~80 MB storage space
- Internet connection required

**Customer Web Interface:**
- Any modern web browser
- Internet connection
- Camera access for QR scanning (optional)

---

## 🏗️ Technical Stack

**Frontend:**
- Flutter 3.x (Mobile app)
- Dart programming language
- Material Design 3

**Backend:**
- Appwrite (Cloud BaaS)
- Real-time database with subscriptions
- Serverless functions for business logic

**Web Ordering:**
- Next.js / Vercel deployment
- RESTful API integration
- Responsive design

---

## 🔐 Security Features

- ✅ OAuth 2.0 authentication (Google Sign-In)
- ✅ Role-based access control (RBAC)
- ✅ Collection-level permissions
- ✅ Token-based authentication
- ✅ HTTPS/TLS encryption
- ✅ Secure session management
- ✅ Single-device login enforcement

---

## 📦 Project Structure

```
kantin_app/
├── lib/
│   ├── core/              # Core utilities, configs
│   ├── features/          # Feature modules
│   │   ├── auth/          # Authentication
│   │   ├── business_owner/# Business owner features
│   │   ├── tenant/        # Tenant features
│   │   ├── guest/         # Customer features
│   │   └── staff/         # Staff features
│   └── shared/            # Shared models, widgets
├── functions/             # Appwrite serverless functions
├── docs/                  # Documentation
└── web/                   # Web configurations
```

---

## 🧪 Development

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK
- Android Studio / VS Code
- Appwrite account (for backend)
- Node.js (for functions)

### Setup

```bash
# Clone repository
git clone https://github.com/Ryota679/PML_7.git
cd PML_7

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📚 Documentation

- **[Setup Guide](docs/SETUP_GUIDE.md)** - Installation and configuration
- **[User Manual](docs/USER_MANUAL.md)** - How to use the app
- **[API Documentation](docs/API_DOCS.md)** - Backend API reference
- **[Architecture](docs/ARCHITECTURE.md)** - System design overview

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact & Support

**Developer:** Ryan  
**Repository:** [https://github.com/Ryota679/PML_7](https://github.com/Ryota679/PML_7)  
**Issues:** [Report a bug](https://github.com/Ryota679/PML_7/issues)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Appwrite for the backend infrastructure
- All contributors and testers

---

**Built with ❤️ using Flutter**
