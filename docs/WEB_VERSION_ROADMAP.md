# Web Version Roadmap: QR Code dengan URL Hosting

**Tujuan:** Customer tidak perlu download app, cukup scan QR → buka web browser → langsung pesan.

**Status:** 📋 PLANNING (untuk future implementation)  
**Target:** Setelah Sprint 4 selesai  
**Estimasi:** 2-3 minggu development

---

## 🎯 Vision

### Current (Mobile App Only)
```
Customer → Scan QR → Detect tenant code → App lookup → Menu
```
**Limitation:** Customer harus install app dulu

### Future (Web + Mobile)
```
Customer → Scan QR → Open browser → Web menu → Order langsung
```
**Benefit:** No installation needed, instant access

---

## 📱 URL Structure Design

### QR Code Format (Production)

**Master QR (di entrance kantin):**
```
https://kantin.yourdomain.com/o/OWNER123
```
→ Landing page dengan list semua tenant

**Tenant QR (di stand tenant):**
```
https://kantin.yourdomain.com/t/Q8L2PH
```
→ Direct ke menu tenant (by tenant code)

### URL Routing Mapping

| URL Pattern | Destination | Notes |
|-------------|-------------|-------|
| `/o/{ownerId}` | Owner's tenant list | Show all tenants |
| `/t/{tenantCode}` | Tenant menu (by code) | 6-char code lookup |
| `/menu/{tenantId}` | Tenant menu (by ID) | Direct access |
| `/order/{orderNumber}` | Order tracking | Guest order status |

---

## 🛠️ Technical Architecture

### Stack Recommendation

#### Option A: Flutter Web ⭐ **RECOMMENDED**
**Pros:**
- ✅ Reuse 90% existing code
- ✅ Same codebase (mobile + web)
- ✅ Consistent UI/UX
- ✅ Already know Flutter

**Cons:**
- ⚠️ Bundle size ~2-3 MB (first load)
- ⚠️ SEO limitations

**Steps:**
1. Enable web in Flutter project
2. Build for web: `flutter build web`
3. Deploy to hosting
4. Update QR code URLs

#### Option B: Next.js (Separate Web App)
**Pros:**
- ✅ Excellent SEO
- ✅ Faster initial load
- ✅ Better web performance

**Cons:**
- ❌ Need rewrite UI in React
- ❌ Duplicate logic
- ❌ Maintenance overhead

---

## 📋 Implementation Roadmap

### Phase 1: Flutter Web Setup (Week 1)

**Tasks:**
1. ✅ Enable Flutter web support
   ```bash
   flutter config --enable-web
   flutter create . --platforms=web
   ```

2. ✅ Test local web build
   ```bash
   flutter run -d chrome
   ```

3. ✅ Configure web-specific settings
   - `web/index.html` - Meta tags, title
   - `web/manifest.json` - PWA config
   - `web/icons/` - Favicon, app icons

4. ✅ Handle platform differences
   ```dart
   if (kIsWeb) {
     // Web-specific code
   } else {
     // Mobile-specific code
   }
   ```

**Testing:**
- ✅ Verify all pages render correctly
- ✅ Test responsiveness (desktop, tablet, mobile)
- ✅ Check Appwrite SDK compatibility on web

### Phase 2: Routing & Deep Links (Week 1)

**Tasks:**
1. ✅ Update GoRouter for web URLs
   ```dart
   GoRoute(
     path: '/t/:code',
     builder: (context, state) {
       final code = state.pathParameters['code']!;
       return TenantMenuFromCodePage(code: code);
     },
   ),
   ```

2. ✅ Add tenant code redirect page
   ```dart
   class TenantMenuFromCodePage extends ConsumerWidget {
     final String code;
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       // Lookup tenant by code
       // Navigate to menu with tenantId
     }
   }
   ```

3. ✅ Test URL patterns
   - `/t/Q8L2PH` → Menu
   - `/order/ORD-20251201-143022-789` → Order tracking

**Testing:**
- ✅ Direct URL access works
- ✅ Browser back button works
- ✅ URL sharing works

### Phase 3: Production Build (Week 2)

**Tasks:**
1. ✅ Optimize web build
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. ✅ Configure environment variables
   ```dart
   // Use production domain
   static const String baseUrl = 'https://kantin.yourdomain.com';
   ```

3. ✅ Update QR code generation
   ```dart
   // Generate web URL for production
   final qrData = kIsWeb || isProduction
       ? '$baseUrl/t/${tenant.getCode()}'
       : tenant.getCode(); // Just code for mobile app
   ```

4. ✅ Test build output
   - Check `build/web/` folder
   - Verify file sizes
   - Test locally: `python -m http.server -d build/web 8000`

---

## 🌐 Hosting Options

### Option 1: Firebase Hosting ⭐ **RECOMMENDED**

**Why Firebase:**
- ✅ Free tier generous (10 GB storage, 360 MB/day transfer)
- ✅ Global CDN
- ✅ Auto SSL certificate
- ✅ Easy deployment
- ✅ Custom domain support

**Setup Steps:**

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize Firebase in project**
   ```bash
   cd kantin_app
   firebase init hosting
   ```
   
   Configuration:
   - Public directory: `build/web`
   - Configure as single-page app: **Yes**
   - Overwrite index.html: **No**

3. **Deploy**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

4. **Custom Domain Setup**
   - Go to Firebase Console → Hosting
   - Click "Add custom domain"
   - Enter: `kantin.yourdomain.com`
   - Follow DNS configuration steps
   - Wait for SSL certificate (auto-provisioned)

**Cost:** FREE (up to 10GB storage, 360MB/day bandwidth)

---

### Option 2: Vercel

**Why Vercel:**
- ✅ Excellent performance
- ✅ Auto deployments from GitHub
- ✅ Free tier available

**Setup:**
1. Push code to GitHub
2. Link repository to Vercel
3. Configure build:
   - Build command: `flutter build web --release`
   - Output directory: `build/web`
4. Deploy

**Cost:** FREE for personal projects

---

### Option 3: Netlify

**Why Netlify:**
- ✅ Simple drag-and-drop deployment
- ✅ Form handling built-in
- ✅ Generous free tier

**Setup:**
1. Build locally: `flutter build web --release`
2. Drag `build/web` folder to Netlify dashboard
3. Configure custom domain
4. Auto SSL enabled

**Cost:** FREE (100 GB bandwidth/month)

---

### Option 4: Self-Hosted (VPS)

**Providers:**
- DigitalOcean Droplet ($5/month)
- AWS Lightsail ($3.50/month)
- Vultr ($2.50/month)

**Setup (Nginx):**
```nginx
server {
    listen 80;
    server_name kantin.yourdomain.com;
    root /var/www/kantin/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**SSL (Let's Encrypt):**
```bash
sudo certbot --nginx -d kantin.yourdomain.com
```

**Cost:** $2.50-$5/month

---

## 🔄 Deployment Workflow

### Development Flow
```bash
# 1. Make changes in Flutter
# 2. Test on web
flutter run -d chrome

# 3. Test on mobile
flutter run -d android
flutter run -d ios

# 4. Build for production
flutter build web --release

# 5. Deploy to hosting
firebase deploy
```

### CI/CD with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Install dependencies
        run: flutter pub get
        working-directory: ./kantin_app
      
      - name: Build web
        run: flutter build web --release
        working-directory: ./kantin_app
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-firebase-project-id
```

---

## 🎨 Web-Specific Optimizations

### 1. Responsive Design

Update layouts for desktop:

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return desktop ?? tablet ?? mobile;
          } else if (constraints.maxWidth > 800) {
            return tablet ?? mobile;
          }
          return mobile;
        },
      );
    }
    return mobile;
  }
}
```

### 2. SEO Optimization

Update `web/index.html`:

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- SEO Meta Tags -->
  <title>Kantin App - Order Makanan & Minuman</title>
  <meta name="description" content="Pesan makanan dan minuman dari tenant favorit Anda dengan mudah">
  <meta name="keywords" content="kantin, food ordering, delivery">
  
  <!-- Open Graph (Facebook, WhatsApp) -->
  <meta property="og:title" content="Kantin App">
  <meta property="og:description" content="Pesan makanan & minuman mudah">
  <meta property="og:image" content="https://kantin.yourdomain.com/og-image.png">
  <meta property="og:url" content="https://kantin.yourdomain.com">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Kantin App">
  <meta name="twitter:description" content="Pesan makanan & minuman mudah">
  <meta name="twitter:image" content="https://kantin.yourdomain.com/twitter-image.png">
</head>
```

### 3. PWA Configuration

Update `web/manifest.json`:

```json
{
  "name": "Kantin App",
  "short_name": "Kantin",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#6366F1",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 4. Loading Optimization

```dart
// Lazy load images
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => Icon(Icons.error),
);
```

---

## 🔐 Security Considerations

### 1. CORS Configuration (Appwrite)

Update Appwrite project settings:

```
Allowed Domains:
- https://kantin.yourdomain.com
- https://www.kantin.yourdomain.com
- http://localhost:8000 (for local testing)
```

### 2. API Key Protection

**DON'T** expose server API keys in web code:

```dart
// ❌ BAD (exposed in web bundle)
static const String serverApiKey = 'standard_xxx...';

// ✅ GOOD (use Appwrite Functions for privileged operations)
// Client SDK only (no API key)
```

### 3. Rate Limiting

Implement on Appwrite Functions side:
- Limit order creation per IP
- Prevent spam

---

## 📊 Analytics & Monitoring

### Google Analytics 4 Setup

1. **Add to `web/index.html`:**

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

2. **Track Events in Flutter:**

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// Track order creation
FirebaseAnalytics.instance.logEvent(
  name: 'order_created',
  parameters: {
    'tenant_id': tenantId,
    'order_total': totalAmount,
  },
);
```

---

## 🚀 Launch Checklist

### Pre-Launch
- [ ] Test all pages on web browser (Chrome, Safari, Firefox)
- [ ] Test responsive design (mobile, tablet, desktop)
- [ ] Verify all Appwrite operations work from web
- [ ] Update QR codes with production URLs
- [ ] Configure custom domain
- [ ] Setup SSL certificate
- [ ] Add analytics tracking
- [ ] Test order flow end-to-end on web

### Post-Launch
- [ ] Monitor error rates (Sentry, Firebase Crashlytics)
- [ ] Track user behavior (Google Analytics)
- [ ] Collect customer feedback
- [ ] Monitor hosting costs
- [ ] Plan mobile app updates (deep linking to web)

---

## 💰 Cost Estimation (Monthly)

### Scenario: Small Kantin (100 orders/day)

| Service | Tier | Cost |
|---------|------|------|
| **Hosting (Firebase)** | Free tier | $0 |
| **Appwrite Cloud** | Free tier | $0 |
| **Custom Domain** | Yearly (Namecheap) | ~$1/month |
| **Total** | | **$1/month** |

### Scenario: Medium Kantin (1000 orders/day)

| Service | Tier | Cost |
|---------|------|------|
| **Hosting (Firebase)** | Blaze (Pay-as-you-go) | ~$5-10 |
| **Appwrite Cloud** | Pro ($15/month) | $15 |
| **CDN (Cloudflare)** | Free | $0 |
| **Total** | | **$20-25/month** |

---

## 🔄 Migration Strategy (App → Web)

### Phase 1: Soft Launch
- Keep mobile app as primary
- Web as secondary option
- QR codes show **both** options:
  ```
  Scan QR:
  📱 Download app: [App Store / Play Store links]
  🌐 Or open in browser: kantin.app/t/Q8L2PH
  ```

### Phase 2: Hybrid
- Web for casual users
- App for regulars (push notifications, loyalty points)

### Phase 3: Future (Optional)
- Migrate fully to web (PWA)
- Remove native apps if web adoption is high

---

## 📝 Implementation Example

### QR Code Generation (Updated)

```dart
// lib/features/tenant/presentation/pages/qr_code_display_page.dart

class QrCodeDisplayPage extends ConsumerWidget {
  final TenantModel tenant;

  // Environment config
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String productionBaseUrl = 'https://kantin.yourdomain.com';

  String _getQrData() {
    final tenantCode = tenant.getCode();
    
    if (kIsWeb || isProduction) {
      // Web/Production: Use URL
      return '$productionBaseUrl/t/$tenantCode';
    } else {
      // Mobile App (dev): Use code only
      return tenantCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // QR Code
          QrImageView(
            data: _getQrData(),
            version: QrVersions.auto,
            size: 280,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          
          // Display code
          Text(
            tenant.getCode(),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          
          // Instructions
          if (kIsWeb || isProduction)
            Text('Scan untuk buka di browser')
          else
            Text('Scan untuk masuk ke menu'),
        ],
      ),
    );
  }
}
```

---

## ✅ Next Steps (When Ready)

1. **Finish Sprint 4** (Tenant order management)
2. **Test mobile app thoroughly**
3. **Enable Flutter web** (`flutter config --enable-web`)
4. **Build & test locally**
5. **Setup Firebase Hosting**
6. **Deploy to production**
7. **Update QR codes**
8. **Monitor & iterate**

---

**Document Version:** 1.0  
**Last Updated:** 1 December 2025  
**Status:** 📋 Ready for implementation after Sprint 4
