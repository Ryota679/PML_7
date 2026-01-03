# Git Push Commands for Midtrans Review

## Upload APK to GitHub

Follow these steps to upload your production APK to GitHub for Midtrans review:

---

## Step 1: Initialize & Add Remote (if first time)

```bash
cd C:\kantin_app

# Initialize git (if not done)
git init

# Add remote repository
git remote add origin https://github.com/Ryota679/Demo_apk.git
```

---

## Step 2: Commit All Files

```bash
# Add all files (source code + APK)
git add .

# Commit with message
git commit -m "Production build v1.0.0-beta for Midtrans review"
```

---

## Step 3: Push to GitHub

```bash
# Push to main branch
git push -u origin main
```

**If error (remote already exists):**
```bash
git remote remove origin
git remote add origin https://github.com/Ryota679/Demo_apk.git
git push -u origin main
```

**If error (divergent branches):**
```bash
git pull origin main --rebase
git push -u origin main
```

---

## Step 4: Create GitHub Release (IMPORTANT!)

### Via GitHub Website:
1. Go to: https://github.com/Ryota679/Demo_apk
2. Click **"Releases"** (right sidebar)
3. Click **"Create a new release"**
4. Tag version: `v1.0.0-beta`
5. Release title: `Production Build for Midtrans Review`
6. Description:
```
Production-ready APK for Midtrans payment gateway integration review.

**Features:**
- Multi-tenant canteen management
- Web ordering system (live at https://kantin-web-ordering.vercel.app/)
- Payment page ready for Midtrans integration
- Clean production build (no debug logs)

**APK Details:**
- Size: 76.7 MB
- Target: Android 5.0+ (API 21+)
- Build: Release (optimized)

**For Midtrans Reviewers:**
See README.md for testing guide and demo credentials.
```
7. Upload file: **`build/app/outputs/flutter-apk/app-release.apk`**
8. Click **"Publish release"**

---

## APK Download Link

After creating release, share this link with Midtrans:

```
https://github.com/Ryota679/Demo_apk/releases/latest
```

Or direct APK link:
```
https://github.com/Ryota679/Demo_apk/releases/download/v1.0.0-beta/app-release.apk
```

---

## Quick Commands Summary

```bash
# All in one
cd C:\kantin_app
git add .
git commit -m "Production build v1.0.0-beta for Midtrans review"  
git push -u origin main
```

Then create GitHub Release with APK attached!

---

## ✅ Checklist Before Push

- [ ] APK built successfully (`app-release.apk` exists)
- [ ] README.md updated
- [ ] Documentation complete (APK_TESTING_GUIDE.md, log_cleanup_complete.md)
- [ ] .gitignore configured (sensitive data excluded)
- [ ] Ready to create GitHub Release

---

## 📝 Notes

- APK file is **76.7 MB** - GitHub allows files up to 100MB
- Use **GitHub Releases** for APK distribution (not main repo)
- Keep source code and APK separate for clean repo
- Update version tag for each new build
