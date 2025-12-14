# 💰 Freemium & Subscription Model - Kantin App

> **Version:** 1.4  
> **Last Updated:** 14 Desember 2025 (19:10 WIB)  
> **Status:** Phase 1-4 Complete | ✅ PRODUCTION READY  
> **Current Focus:** Sprint 4 - Order Status Management

---

## 📋 Table of Contents

1. [Implementation Progress](#implementation-progress) ⭐ **UPDATED**
2. [Overview](#overview)
3. [Pricing Structure](#pricing-structure)
4. [Feature Comparison](#feature-comparison)
5. [Subscription Scenarios](#subscription-scenarios)
6. [Trial & Grace Period](#trial--grace-period)
7. [Educational Downgrade Flow](#educational-downgrade-flow) ⭐ ACTIVE
8. [Auto-Selection Algorithm](#auto-selection-algorithm)
9. [Pause Mechanism](#pause-mechanism)
10. [Database Schema](#database-schema)
11. [Implementation Plan](#implementation-plan)

---

## Implementation Progress

> **Session Date:** 10-11 Desember 2025  
> **Total Work Time:** ~4 hours  
> **Phases Completed:** 2/4 (Phase 1 & 2)  

### ✅ Completed Features (Session 10-11 Des 2025)

#### **Phase 1: Auto-Selection Logic**
- ✅ Updated `NoSelectionNeededBanner` with clearer messaging
- ✅ Created `ConsolidatedTrialWarningBanner` (BO version)
  - Color-coded urgency: Purple (D-7 to D-5) → Orange (D-4 to D-3) → Red (D-2 to D-0)
  - "Apa penurunannya?" button links to educational page
  - Gradient design with modern aesthetics
- ✅ Integrated consolidated banner into `business_owner_dashboard.dart`
- ✅ Disabled old D7SelectionBanner to prevent duplication

#### **Phase 2: Educational Downgrade Pages**
- ✅ Created `DowngradeImpactPage` for Business Owners
  - Modern UI with gradients, shadows, glassmorphism
  - Trial countdown header card
  - Comprehensive feature comparison table (Premium vs Free)
  - Concrete usage examples with icons
  - Conditional tenant selection card (auto-skip for ≤2 tenants)
  - Upgrade CTA with pricing (Rp 149k/month)
- ✅ Created `TenantDowngradeImpactPage` for Tenants
  - Tenant-specific feature comparisons
  - Examples: product limits, edit restrictions, analytics
  - Simplified upgrade option (Rp 49k with pause explanation)
  - Removed "Minta BO Upgrade" option (user request)
- ✅ Created `TenantConsolidatedTrialBanner`
  - Integrated into `tenant_dashboard.dart`
  - Clarified text: "Trial Business Owner berakhir X hari lagi"
  - Links to tenant downgrade impact page

#### **UI/UX Improvements**
- ✅ Fixed text contrast issues (hardcoded `Colors.black87`)
- ✅ Enhanced visual hierarchy with icon badges
- ✅ Improved comparison table readability
- ✅ Modern color palette with gradients

#### **Bug Fixes**
- ✅ Fixed tenant selection save error (removed `swap_available_until` field)
- ✅ Fixed navigation to `TenantSelectionPage` (added missing `tenants` parameter)
- ✅ Fixed duplicate banner display (disabled old selection banner)

### 🚧 In Progress

### ✅ Phase 2.5: 1x Swap Limit (COMPLETE)
- ✅ **Backend Complete:**
  - Updated `tenant_swap_service.dart` with swap count tracking
  - Added `swap_used` field validation
  - Returns error `swap_limit_exceeded` when trying 2nd+ swap
  - Tracks first-time selection vs changes
- ✅ **UI Integration Complete:**
  - Swap warning dialog before first swap
  - SwapUsedBanner after swap is used
  - Upgrade dialog when swap limit exceeded
  - Comprehensive debug logging

**Status:** ✅ TESTED & WORKING (Session 11 Dec 2025)

---

### ✅ Phase 3: Enforcement (COMPLETE)

**Status:** Implementation & Test Data Setup Complete  
**Estimated Time:** 8 hours  
**Actual Time:** 7.5 hours  
**Updated:** 11 December 2025 (17:00 WIB)

**What Was Completed:**
- ✅ Business Owner enforcement (tenant/user management restrictions)
- ✅ Tenant enforcement (product/category management restrictions)
- ✅ Upgrade dialogs and banners
- ✅ Test data setup (12 categories + 20 products)
- ✅ Category filtering working correctly
- ✅ All features tested and verified

**Key Challenges Resolved:**
1. Auth-Database user_id mismatch (login failure)
2. Category ID mismatch after re-import (filtering broken)
3. Implemented comprehensive debug logging for diagnosis

**See:** [phase3_walkthrough.md](file:///C:/Users/Ryan/.gemini/antigravity/brain/d324aca3-e3d5-4122-8c39-2058258dc3e2/phase3_walkthrough.md) for detailed implementation notes.

### ✅ Phase 3.5: UI Polish & Standardization (Session 12 Dec 2025)

**Status:** ✅ COMPLETE  
**Focus:** Visual consistency & "Pitch Black" Theme

**Improvements:**
- ✅ **Unified Upgrade Dialog:** Created shared `UpgradeDialog` widget used by both Dashboard & Menu Management.
- ✅ **Pitch Black Theme:** Applied requested "Hitam Legam" (#101010) theme to dialogs.
- ✅ **Consistent Banners:** Dashboard banner matches dialog aesthetic (Teal/Cyan accents).
- ✅ **Modern Aesthetics:** All upgraded UI components use modern gradients and shadows.

### ✅ Path A: Polish & Ship (Session 14 Dec 2025) - COMPLETE

**Status:** ✅ ALL TESTS PASSED | APPROVED FOR PRODUCTION  
**Duration:** ~3 hours  
**Updated:** 14 December 2025 (19:10 WIB)

**Completed Tasks:**

**1. Production Code Cleanup** ✅
- Removed excessive debug logging from `ProductManagementPage` (30+ lines)
- Kept useful repository-level logs for production troubleshooting
- Kept TenantSubscriptionProvider logs for debugging subscription issues

**2. Critical Bug Fix** ✅
- **Issue Found:** Free tier tenants could bypass CREATE restriction and open "Tambah Produk" dialog
- **Root Cause:** Phase 4 only enforced limits (10 vs 15) but forgot Phase 3 policy (View + Delete Only)
- **Fix Applied:** Updated FAB to show UpgradeDialog instead of ProductDialog for all free tier users
- **Verification:** Tested with tenant "admin kafe" - enforcement working correctly

**3. Comprehensive E2E Testing** ✅
- Created detailed testing checklist (50+ test cases)
- Executed 6 test suites covering all freemium scenarios
- **Test Results:**
  - ✅ Business Owner Free Tier restrictions
  - ✅ Business Owner Premium/Trial full access
  - ✅ Tenant Selected (15 product enforcement)
  - ✅ Tenant Non-Selected (10 product + orange banner)
  - ✅ Tenant under Premium BO (unlimited)
  - ✅ UI/UX consistency across all dialogs

**Production Readiness Assessment:**
- ✅ All Free Tier restrictions enforced correctly
- ✅ All Premium users have unlimited access
- ✅ 10 vs 15 product limits work as designed
- ✅ Contact BO feature functional
- ✅ No crashes or console errors
- ✅ UI consistent and polished
- ✅ Edge cases handled gracefully

**Deployment Status:** ✅ **APPROVED FOR PRODUCTION**

**See:** [e2e_testing_checklist.md](file:///C:/Users/HP/.gemini/antigravity/brain/538ec06e-962b-479b-9fec-16f8b0abdcd5/e2e_testing_checklist.md) for complete test documentation.
- ✅ **Code Cleanup:** Removed duplicate dialog implementations in `tenant_dashboard.dart`.

#### **Finalized FREE Tier Limits:**

**Business Owner:**
```yaml
Tenants: 2 (must select from all owned tenants)
Users per Tenant: 1 (owner tenant only, no additional staff)
Contract Management: Full CRUD (no restrictions)
```

**Tenant (Selected):**
```yaml
Products: 15 (soft limit with toggle)
Categories: 10 (soft limit with toggle)  
Staff: 1 (owner only, no additional staff)
Orders: Unlimited (no restrictions)
```

**Tenant (Non-Selected):**
```yaml
Products: 10 (soft limit with toggle)
Categories: 10 (soft limit with toggle)
Staff: 1 (owner only)
Orders: Unlimited (no restrictions)
Access: Limited (Phase 4 - contact BO feature)
```

**Key Difference:**
- Selected tenants: 15 products
- Non-selected tenants: 10 products
- Incentive untuk BO pilih tenant terbaik

#### **Enforcement Approach: View + Delete Only**

| Action | Free Tier | Premium |
|--------|-----------|---------|
| **View** | ✅ Allowed | ✅ Allowed |
| **Create** | ❌ Blocked | ✅ Allowed |
| **Update/Edit** | ❌ Blocked | ✅ Allowed |
| **Delete** | ✅ Allowed | ✅ Allowed |

**Rationale:**
- Simpler than hard limits
- Clear upgrade incentive (can't edit = upgrade)
- Users can cleanup old data
- No complex counter management

#### **Soft Limit Logic (Products/Categories):**

**Scenario 1: Manual Toggle (User has time to prepare)**

**Problem:** User has 20 products during trial, manually downgrade to free (limit 15 for selected tenant).

**Solution:** Toggle Active/Inactive
```
1. User cannot ADD new products (reached limit)
2. User CAN toggle existing products:
   - Deactivate Product A → Activate Product B
   - Keeps within 15 active limit
   - No data loss
3. To add NEW product:
   - Must deactivate 1 existing product first
   - OR upgrade to premium
```

---

**Scenario 2: Auto-Select (Trial expires, user tidak pilih)**

**Problem:** User has 20 products, trial expires, user tidak sempat pilih products mana yang aktif.

**Solution:** Auto-select by Order Count (Data-Driven)
```
On downgrade (via cleanup function or manual downgrade):

1. Get all products for tenant
2. Sort by order count (DESC) - bestsellers first
3. Auto-activate top N products:
   - Selected tenant: Top 15 products
   - Non-selected tenant: Top 10 products
4. Set remaining products to inactive (is_available: false)
5. Send notification/email with summary
```

**Auto-Selection Priority:**
```sql
SELECT * FROM products 
WHERE tenant_id = 'XXX' 
ORDER BY order_count DESC, created_at DESC 
LIMIT 15  -- or 10 for non-selected
```

**Benefits:**
- ✅ Data-driven (bestsellers stay active)
- ✅ No data loss (inactive products retained)
- ✅ User can adjust later (toggle any product)
- ✅ Revenue-optimized (keep money-makers active)

**Edge Cases:**
- Products with 0 orders → Prioritize by `created_at` (newest first)
- Equal order count → Prioritize by revenue (if tracked)
- Categories → Auto-select categories that contain active products

**Implementation Note:**
- Add `order_count` field to products collection (track total orders)
- Update `order_count++` setiap ada order baru
- Run auto-selection in `cleanup-expired-contracts` function

---

**Manual Toggle Flow (Anytime):**

**Implementation:**
- Count only `is_available: true` products against limit
- "Add Product" button disabled if 15 active products
- Show message: "15/15 products active. Deactivate 1 to add new, or upgrade."
- User can toggle any product active/inactive
- Same logic for categories

**UI Flow:**
```
[User clicks "Add Product" with 15/15 active]
  ↓
Show Dialog:
┌─────────────────────────────────────────┐
│ 🔒 Limit Free Tier Tercapai             │
├─────────────────────────────────────────┤
│                                         │
│ Anda telah mencapai batas:             │
│ • 15 produk aktif                      │
│                                         │
│ Untuk menambah produk baru:            │
│ 1. Non-aktifkan 1 produk yang ada      │
│ 2. Atau upgrade ke Premium             │
│                                         │
│ [Kelola Produk] [Upgrade Premium]     │
└─────────────────────────────────────────┘
```

#### **Features to Implement:**

**Priority 1: Core Enforcement**
- [x] Business Owner dashboard:
  - ✅ Disable create tenant
  - ✅ Disable edit tenant  
  - ✅ Keep delete enabled
  - ✅ Show upgrade banner
- [x] Tenant Management:
  - ✅ Disable create user
  - ✅ Disable edit user
  - ✅ Keep delete enabled
- [x] Product/Category Management:
  - ✅ Disable create if BO free tier
  - ✅ Disable edit if BO free tier
  - ✅ Soft limit for active count
  - ✅ Toggle active/inactive always enabled
  - ✅ Keep delete enabled

**Priority 2: UI Components**
- [x] Create `UpgradeDialog` widget (reusable)
- [x] Create `UpgradeBanner` widget (persistent)
- [x] Create `SoftLimitDialog` (with active count)

**Priority 3: Testing**
- [x] Test all disable states
- [x] Test soft limit toggle flow
- [x] Test upgrade prompts
- [x] Test edge cases (downgrade mid-session)

**Affected Files:**
- `lib/features/business_owner/presentation/pages/tenant_management_page.dart`
- `lib/features/business_owner/presentation/pages/user_management_page.dart`
- `lib/features/tenant/presentation/pages/product_management_page.dart`
- `lib/features/tenant/presentation/pages/category_management_page.dart`
- `lib/core/utils/subscription_helper.dart` (new)
- `lib/shared/widgets/upgrade_dialog.dart` (new)
- `lib/shared/widgets/upgrade_banner.dart` (new)

---

### ⏳ Phase 4: Non-Selected Tenant Enforcement ✅ COMPLETE

**Status:** Implementation & Testing Complete  
**Estimated Time:** 3-4 hours  
**Actual Time:** 3.5 hours  
**Updated:** 13 December 2025 (13:00 WIB)

**For:** Non-selected tenants under free tier BO

**What Was Completed:**
- ✅ TenantSubscriptionProvider (centralized status detection)
- ✅ 10 vs 15 product limit enforcement
- ✅ Contact Business Owner banner for non-selected tenants
- ✅ Dynamic FAB with limit counter
- ✅ Selection-aware dialog messaging
- ✅ Tested with real tenant scenarios

**Key Achievements:**
1. **Smart Detection:** Automatically detects if tenant is in BO's `selected_tenants` array
2. **Fair Limits:** Selected tenants get 15 products, non-selected get 10 (50% difference)
3. **Clear Communication:** Orange banner explains status and provides BO contact
4. **Seamless UX:** FAB shows "Tambah Produk (5/15)" or "(8/10)" dynamically

**See:** [Phase 4 Walkthrough](file:///C:/Users/HP/.gemini/antigravity/brain/538ec06e-962b-479b-9fec-16f8b0abdcd5/walkthrough.md) for detailed implementation notes.

**Status:** Planned for future sprint

### 📝 Future Enhancements (Post-MVP)

#### **Full Dark Mode Support**
- [ ] Make all colors theme-aware
  - Update `downgrade_impact_page.dart`
  - Update `consolidated_trial_warning_banner.dart`
  - Update `tenant_downgrade_impact_page.dart`
  - Update `no_selection_needed_banner.dart`
- [ ] Replace hardcoded colors with `Theme.of(context)` colors
- [ ] Test in both light and dark system themes

**Rationale:** Deferred to post-MVP to prioritize core functionality. Current hardcoded colors ensure readability but don't follow system theme.

### 🧪 Testing Status

#### **Tested Scenarios:**
- ✅ Banner display for ≤2 tenants (auto-skip)
- ✅ Consolidated banner display for trial users
- ✅ Navigation to downgrade impact pages
- ✅ Tenant selection save (initial + change)
- ✅ Text contrast and readability
- ✅ Gradient and modern UI rendering

#### **Pending Tests:**
- ⏳ 1x swap limit enforcement (UI integration incomplete)
- ⏳ Swap warning dialog display
- ⏳ Upgrade dialog when limit exceeded
- ⏳ Auto-selection when trial expires (requires trial expiry)
- ⏳ Read-only grace period (Phase 3 not implemented)
- ⏳ User selection flow (Phase 4 not implemented)

#### **Testing Environment:**
- **User:** `opoyo` (Business Owner, trial extended to 2025-12-24)
- **Tenants:** 3 total (Joyo, Kafe, Bengkel)
- **Cleanup Function:** Scheduled 07:00 WIB daily (safe - BO excluded from deletion)

### 📊 Implementation Statistics

**Files Created:** 6
- `consolidated_trial_warning_banner.dart`
- `downgrade_impact_page.dart`
- `tenant_downgrade_impact_page.dart`
- `tenant_consolidated_trial_banner.dart`

**Files Modified:** 4
- `business_owner_dashboard.dart`
- `tenant_dashboard.dart`
- `tenant_swap_service.dart`
- `no_selection_needed_banner.dart`

**Lines of Code:**
- Added: ~1,200 lines
- Modified: ~150 lines
- Deleted: ~50 lines (cleanup duplicates)

**Design Elements:**
- Gradient backgrounds: 8+
- Shadow effects: 15+
- Icon badges: 20+
- Color-coded urgency states: 3

### 🎯 Next Steps (Priority Order)

**Updated:** 11 December 2025 (17:00 WIB) - Post Phase 3 Completion

1. **Comprehensive End-to-End Testing** (HIGH PRIORITY)
   - Test free tier BO with all restrictions
   - Test premium BO with no restrictions  
   - Test trial BO with countdown banners
   - Test tenant under free BO (restricted product/category management)
   - Test tenant under premium BO (full access)
   - Verify all upgrade dialogs and banners
   - **Estimated Time:** 1 hour
   - **Status:** 🚧 IN PROGRESS

2. **Production Code Cleanup** (HIGH PRIORITY)
   - Remove debug logging from auth flow
   - Remove debug logging from product management
   - Remove debug logging from guest menu page
   - Clean up console noise
   - **Estimated Time:** 15-30 minutes
   - **Status:** ⏳ TODO

3. **Phase 5: Soft Limit Implementation** (OPTIONAL - Post-MVP)
   - Count active products/categories
   - Show "X/15 products active" indicator
   - Block create when limit reached
   - Allow toggle between active/inactive
   - **Estimated Time:** 3-4 hours
   - **Status:** ⏳ DEFERRED

4. **Dark Mode Support** (LOW PRIORITY - Post-MVP)
   - Count active products/categories
   - Show "X/15 products active" indicator
   - Block create when limit reached
   - Allow toggle between active/inactive
   - **Estimated Time:** 2-3 hours
   - **Status:** ⏳ DEFERRED

5. **Dark Mode Support** (LOW PRIORITY - Post-MVP)
   - Refactor hardcoded colors
   - Test theme switching
   - **Estimated Time:** 1-2 hours
   - **Status:** ⏳ POST-MVP

### ⚠️ Known Issues

1. **Text Contrast in Light Mode** - ✅ RESOLVED
   - Issue: Comparison table text too light, hard to read
   - Fix: Changed to `Colors.black87` with heavier font weights

2. **Duplicate Banners** - ✅ RESOLVED
   - Issue: Old D7SelectionBanner showing alongside new consolidated banner
   - Fix: Disabled old banner in dashboard logic

3. **Swap Limit UI Incomplete** - 🚧 IN PROGRESS
   - Issue: Backend validates swap limit but UI doesn't show dialogs
   - Status: Service returns proper errors, UI update pending

4. **Dark Mode Not Supported** - 📝 PLANNED (Post-MVP)
   - Issue: Hardcoded colors don't follow device theme
   - Impact: Low (readability prioritized over theme consistency)

### 🔄 Architecture Decisions

#### **Consolidated Banner Approach**
Replaced multiple separate banners (D7, success, etc.) with single consolidated banner.

**Rationale:**
- Reduces UI clutter
- Consistent messaging
- Easier to maintain
- Better UX (single source of truth)

#### **Educational Pages over Modal Dialogs**
Created dedicated full pages instead of modal dialogs.

**Rationale:**
- More space for detailed information
- Better readability
- Can include complex comparisons and examples
- Allows users to reference while making decisions

#### **Hardcoded Colors (Temporary)**
Used `Colors.black87` instead of theme-aware colors.

**Rationale:**
- Ensures readability immediately
- Faster implementation for MVP
- Can refactor to theme-aware later
- User feedback prioritized contrast over theme consistency

#### **1x Swap Limit**
Limited selection changes to 1 time during trial, no grace period swaps.

**Rationale:**
- Creates upgrade incentive (want more flexibility? pay!)
- User still has flexibility (1 change allowed)
- Simpler than grace period tracking
- Reduces abuse potential

### 🛡️ Safety Measures

#### **Cleanup Function Safety**
**Function:** `cleanup-expired-contracts`  
**Schedule:** Daily at 00:00 UTC (07:00 WIB)  

**Business Owner Protection:**
```javascript
Query.notEqual('role', 'owner_business'),  // Excluded!
Query.notEqual('role', 'owner_bussines'),  // Legacy typo also excluded
```

**Current State:**
- ✅ BO accounts safe from auto-deletion
- ✅ Trial extended to 2025-12-24 for testing
- ✅ Next cleanup: 11 Dec 2025, 07:00 WIB (won't affect test account)

#### **Data Backup Recommendations**
- Trial users can download/export data during H-7 to H-5 grace period
- DELETE operations remain enabled for cleanup
- VIEW access maintained for data review

---

## Overview

**Model Type:** Independent Subscription with Cascade Benefit

**Key Features:**
- ✅ Business Owner and Tenant have separate subscriptions
- ✅ BO Premium unlocks ALL tenants automatically
- ✅ Tenant Premium paused when BO upgrades (no loss of paid days)
- ✅ 30-day trial with full access for Business Owners
- ✅ D-7 selection window with revenue-based auto-selection
- ✅ Restrictive Free Tier to encourage upgrades
- ⭐ **Educational Downgrade Flow** for better user experience

---

## Pricing Structure

| Role | Free Tier | Premium | Trial |
|------|-----------|---------|-------|
| **Business Owner** | Rp 0 | **Rp 149,000/bulan** | 30 days (full access) |
| **Tenant** | Rp 0 | **Rp 49,000/bulan** | - |

### Pricing Rationale

**Business Owner Premium (Rp 149k):**
- Unlocks ALL owned tenants automatically
- ROI positive at 4+ tenants (4 × Rp 49k = Rp 196k)
- Full analytics across all tenants
- Export capabilities

**Tenant Premium (Rp 49k):**
- Independent subscription
- Full access to single tenant
- Can pause if BO upgrades (no loss)

---

## Feature Comparison

### Business Owner Features

| Feature | Free | Premium |
|---------|------|---------|
| **Tenant Management** | View + Delete only | ✅ Full CRUD |
| **User Management** | View + Delete only | ✅ Full CRUD |
| **Contract Management** | ✅ Full CRUD | ✅ Full CRUD |
| **Analytics Dashboard** | ❌ Blocked | ✅ Full Access |
| **Export Reports (PDF/Excel)** | ❌ No | ✅ Yes |
| **All Tenants Auto-Upgrade** | ❌ No | ✅ **Yes** |

### Tenant Features

| Feature | Free (BO Free) | Premium |
|---------|----------------|---------|
| **Product Management** | View + Delete only | ✅ Full CRUD |
| **Category Management** | View + Delete only | ✅ Full CRUD |
| **Staff Management** | View + Delete only | ✅ Full CRUD |
| **Order Management** | ✅ Full CRUD | ✅ Full CRUD |
| **Analytics (Laporan Saya)** | ❌ Blocked | ✅ Full Access |
| **Export Reports (PDF/Excel)** | ❌ No | ✅ Yes |

---

## Subscription Scenarios

### Scenario A: BO Free + Tenant Free

**Access Levels:**
- Business Owner: Limited (view+delete only, no analytics)
- Tenant: Limited (view+delete only, no analytics)

```yaml
BO:
  subscription_tier: free
  
Tenant:
  subscription_tier: free
  effective_tier: free
  payment_status: free
```

---

### Scenario B: BO Free + Tenant Premium (Rp 49k)

**Access Levels:**
- Business Owner: Still limited
- Tenant: **Full premium** (from own subscription)

```yaml
BO:
  subscription_tier: free
  
Tenant:
  subscription_tier: premium
  subscription_status: active
  effective_tier: premium
  payment_status: self_paid
```

---

### Scenario C: BO Premium (Rp 149k) + Tenant Free

**Access Levels:**
- Business Owner: Full premium
- Tenant: **Full premium** (inherited from BO)

```yaml
BO:
  subscription_tier: premium
  
Tenant:
  subscription_tier: free
  effective_tier: premium  # Inherited!
  payment_status: via_business_owner
```

**Key Benefit:** All tenants get premium when BO upgrades! 🎁

---

### Scenario D: BO Premium (Rp 149k) + Tenant Premium (Active)

**Access Levels:**
- Business Owner: Full premium
- Tenant: **Subscription PAUSED**, uses BO premium

```yaml
BO:
  subscription_tier: premium
  
Tenant:
  subscription_tier: premium
  subscription_status: paused
  paused_at: 2025-12-10T08:00:00Z
  paused_days_remaining: 15
  effective_tier: premium  # From BO
  payment_status: via_business_owner
```

**When BO downgrades:**
```yaml
Tenant:
  subscription_status: active  # Auto-resume
  subscription_expires_at: now + 15 days  # Restored
  effective_tier: premium
  payment_status: self_paid
```

---

## Trial & Grace Period

### Timeline (30-Day Trial for Business Owner)

```
Day 1: Sign up
    ↓
    [Trial Active - 30 days full Premium access]
    ↓
D-7: Selection Window Opens
    ├─► Banner appears: "Pilih 2 tenant dengan performa terbaik"
    ├─► Shows revenue stats for each tenant
    ├─► User can select 2 tenants manually
    │
    └─► If ignored:
        ↓
D-0: Trial Expires
    ├─► Auto-select 2 tenants by REVENUE (highest first)
    ├─► Downgrade to Free Tier
    ├─► Apply restrictions immediately
    └─► Email notification sent
```

### D-7 Selection Banner

```
🎯 Pilih 2 Tenant Terbaik Anda

Trial berakhir dalam 7 hari. Pilih 2 tenant untuk 
tetap dapat akses penuh setelah trial berakhir.

Jika tidak memilih, sistem akan otomatis memilih 
2 tenant dengan pendapatan tertinggi (30 hari terakhir).

📊 L ihat Performa Tenant
[Pilih Sekarang]  [Nanti]
```

---

## Educational Downgrade Flow

### Overview

**Purpose:** Improve user experience during trial→free transition with educational, non-intrusive approach.

**Key Improvements:**
- 🎯 Consolidated banner replacing multiple separate banners
- 📚 Dedicated "Apa penurunannya?" information pages
- 🔐 Read-only grace period (H-7 to H-5) with DELETE exception
- 👥 1-user-per-tenant selection for free tier
- ✅ Auto-skip selection when ≤ limits

### Timeline with Educational Flow

```
Day 1: Sign up (Trial starts)
    ↓
    [30 days full Premium access]
    ↓
D-8: Normal trial continues
    ↓
D-7: Educational Flow Begins
    ├─► If tenants ≤ 2: Show success banner (no action needed)
    ├─► If tenants > 2: Show consolidated trial warning banner
    │   └─► "Apa penurunannya?" button → Info page
    ↓
D-5: Read-Only Grace Period Starts
    ├─► CREATE/UPDATE: Blocked (show educational dialog)
    ├─► DELETE: Still allowed (cleanup opportunity)
    ├─► VIEW/DOWNLOAD: Still allowed (backup data)
    └─► Banner changes to more urgent messaging
    ↓
D-0: Trial Expires
    ├─► Auto-select tenants (if not manually selected)
    ├─► Auto-select users (1 per tenant, if applicable)
    ├─► Downgrade to Free Tier
    └─► Restrictions applied immediately
```

### Consolidated Banner Approach

**Old Approach (Removed):**
- Separate D-7 Selection Banner
- Separate Trial Warning Banner
- Takes too much screen space
- Repetitive messaging

**New Approach:**
```
┌─────────────────────────────────────────┐
│ ⏰ Trial berakhir dalam X hari          │
│ Nikmati fitur premium dengan subscribe  │
│                                          │
│ [Apa penurunannya?] [Upgrade]          │
└─────────────────────────────────────────┘
```

**Benefits:**
- Single, clean banner
- Educational button leads to detailed info
- Less intrusive
- Better mobile UX

### Downgrade Impact Pages

#### Business Owner Impact Page

**Contents:**
1. **Header**: Countdown + current status
2. **Comparison Table**: Premium vs Free features
3. **Examples with Scenarios**:
   - "Tambah Tenant Baru": What happens in free tier
   - "Edit Data Tenant": Restrictions explained
   - "Kelola User": 1-user-per-tenant limit example
   - "Analytics": What gets locked
4. **Preparation Section**:
   - Tenant Selection Card (if >2 tenants)
   - User Selection Card (if any tenant has >1 user)
5. **Upgrade CTA**: Single clear upgrade option

#### Tenant Impact Page

**Contents:**
1. **Header**: Countdown + current status
2. **Comparison Table**: Tenant-specific features
3. **Examples with Concrete Scenarios**:
   - "Tambah Produk": e.g., "Nasi Goreng Pete" menu
   - "Edit Harga": e.g., "Es Teh 3rb → 5rb"
   - "Tambah Staff": Warung staff management
   - "Lihat Laporan": Analytics locked example
   - "Export Data": PDF/Excel restriction
4. **Upgrade Option**:
   - Self-upgrade: Rp 49k/bulan
   - Pause mechanism explained (if BO upgrades later)
5. **No "Ask BO" option**: Simplified flow

### Read-Only Grace Period (H-7 to H-5)

**Purpose:** Give users time to prepare without hard lockout.

**Access Matrix:**

| Action | H-8+ (Full Trial) | H-7 to H-5 (Grace) | H-0+ (Free Tier) |
|--------|-------------------|---------------------|------------------|
| **CREATE** | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| **UPDATE** | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| **DELETE** | ✅ Allowed | ✅ **Allowed** | ✅ Allowed |
| **VIEW** | ✅ Allowed | ✅ Allowed | Limited |
| **DOWNLOAD** | ✅ Allowed | ✅ Allowed | ❌ Blocked |

**Rationale for DELETE Exception:**
- Users should be able to cleanup/remove unwanted data
- Prevents data accumulation before downgrade
- Positive UX: "Prepare your account for free tier"

**Educational Dialog (when trying CREATE/UPDATE):**
```
╔══════════════════════════════════════╗
║ 👁️ Mode View Only                   ║
║                                      ║
║ Trial berakhir dalam X hari.         ║
║                                      ║
║ Anda masih bisa:                     ║
║ ✅ Melihat data                      ║
║ ✅ Download laporan                  ║
║ ✅ Lihat analytics                   ║
║ ✅ HAPUS data (cleanup!)             ║
║                                      ║
║ Tidak bisa:                          ║
║ ❌ Tambah data baru                  ║
║ ❌ Edit/update data                  ║
║                                      ║
║ 💡 Manfaatkan untuk backup data!     ║
║                                      ║
║ [Mengerti] [Apa penurunannya?]      ║
╚══════════════════════════════════════╝
```

### Auto-Skip Selection Logic

**Scenario 1: Tenants ≤ 2**
```
If (tenantCount <= 2):
    - Hide D-7 selection banner
    - Show success banner instead
    - Auto-select ALL tenants on expiry
    - No user action needed
```

**Scenario 2: Users ≤ 1 per Tenant**
```
If (usersPerTenant <= 1 for ALL tenants):
    - Hide user selection card
    - Show success card instead
    - Auto-select existing users
    - No user action needed
```

**Benefits:**
- Reduces unnecessary friction
- Better UX for small businesses
- Clear communication of status

### User Selection (1-per-Tenant)

**Purpose:** For free tier, each tenant can only have 1 active user.

**Selection UI:**
- Similar to tenant selection page
- Shows per-tenant user list
- Displays user activity stats
- Only shown for tenants with >1 user

**Auto-Selection Algorithm:**
```javascript
For each tenant:
  If (usersInTenant == 1):
    selectedUser = that user
  Else if (usersInTenant > 1):
    // Sort by activity/last login
    selectedUser = mostActiveUser
```

### Implementation Checklist

**Phase 1: Auto-Select Logic** ✅
- [ ] Auto-select when ≤2 tenants
- [ ] Auto-select when ≤1 user per tenant
- [ ] Success banner components

**Phase 2: Educational Pages** 🔄
- [ ] Consolidated trial warning banner
- [ ] BO Downgrade Impact Page
- [ ] Tenant Downgrade Impact Page
- [ ] Navigation flows

**Phase 3: Read-Only Grace** ⏳
- [ ] TierFeatureGuard with DELETE exception
- [ ] Read-only grace dialog
- [ ] Update all CREATE/UPDATE buttons
- [ ] Keep DELETE buttons enabled

**Phase 4: User Selection** ⏳
- [ ] User selection page
- [ ] User selection card in BO impact page
- [ ] Auto-selection logic
- [ ] Activity stats display

---

## Auto-Selection Algorithm

### Selection Criteria

**Primary Sort:** Revenue (last 30 days, completed orders only)  
**Secondary Sort:** Created date DESC (if revenue is tied)

### Algorithm Logic

```javascript
async function autoSelectTopTenants(boUserId) {
  // 1. Query all tenants
  const tenants = await getTenantsByOwner(boUserId);
  
  // 2. Calculate revenue for each
  const tenantsWithRevenue = await Promise.all(
    tenants.map(async (tenant) => {
      const orders = await getCompletedOrders(tenant.$id, {
        startDate: thirtyDaysAgo,
        endDate: now
      });
      
      const revenue = orders.reduce((sum, order) => sum + order.total_price, 0);
      
      return {
        ...tenant,
        monthlyRevenue: revenue,
        transactionCount: orders.length
      };
    })
  );
  
  // 3. Sort by revenue DESC, then created date DESC
  const sorted = tenantsWithRevenue.sort((a, b) => {
    if (b.monthlyRevenue !== a.monthlyRevenue) {
      return b.monthlyRevenue - a.monthlyRevenue;  // Primary
    }
    return new Date(b.$createdAt) - new Date(a.$createdAt);  // Secondary
  });
  
  // 4. Select top 2
  const top2 = sorted.slice(0, 2);
  
  // 5. Update database
  await updateUserSelection(boUserId, {
    selected_tenant_ids: top2.map(t => t.$id),
    selection_submitted_at: now,
    manual_tenant_selection: false
  });
  
  return top2;
}
```

### Example

```
Business Owner has 5 tenants:

Revenue (30 days, completed orders):
1. Warung Makan   → Rp 2,500,000  ✅ SELECTED
2. Kopi Shop      → Rp 1,800,000  ✅ SELECTED
3. Toko Buah      → Rp   800,000
4. Bakso Bakar    → Rp   500,000
5. Es Teh Manis   → Rp         0

Result after D-0:
- Warung Makan: No restrictions (auto-selected)
- Kopi Shop: No restrictions (auto-selected)
- Others: Free tier restrictions applied
```

---

## Pause Mechanism

### When BO Upgrades to Premium

```javascript
// Appwrite Function: handle-bo-upgrade

async function pauseTenantSubscriptions(boUserId) {
  const tenants = await getTenantsByOwner(boUserId);
  
  for (const tenant of tenants) {
    if (tenant.subscription_tier === 'premium' && 
        tenant.subscription_status === 'active') {
      
      const daysRemaining = calculateDaysRemaining(tenant.subscription_expires_at);
      
      await updateTenant(tenant.$id, {
        subscription_status: 'paused',
        paused_at: new Date(),
        paused_days_remaining: daysRemaining,
        payment_status: 'via_business_owner'
      });
    } else {
      // Free tenant, just mark as via BO
      await updateTenant(tenant.$id, {
        payment_status: 'via_business_owner'
      });
    }
  }
}
```

### When BO Downgrades from Premium

```javascript
// Appwrite Function: handle-bo-downgrade

async function resumeTenantSubscriptions(boUserId) {
  const tenants = await getTenantsByOwner(boUserId);
  
  for (const tenant of tenants) {
    if (tenant.subscription_status === 'paused') {
      const newExpiresAt = new Date();
      newExpiresAt.setDate(newExpiresAt.getDate() + tenant.paused_days_remaining);
      
      await updateTenant(tenant.$id, {
        subscription_status: 'active',
        subscription_expires_at: newExpiresAt,
        paused_at: null,
        paused_days_remaining: null,
        payment_status: 'self_paid'
      });
    } else if (tenant.subscription_tier === 'free') {
      await updateTenant(tenant.$id, {
        payment_status: 'free'
      });
    }
  }
}
```

---

## Database Schema

### User Collection (Business Owner)

```dart
class UserModel {
  // Existing subscription fields
  final String subscriptionTier;         // 'free' | 'premium'
  final DateTime? subscriptionExpiresAt;
  final String paymentStatus;            // 'active' | 'expired' | 'trial'
  
  // Trial fields
  final DateTime? subscriptionStartedAt;
  final List<String>? selectedTenantIds; // For free tier: 2 selected tenants
  final DateTime? selectionSubmittedAt;
  final bool? manualTenantSelection;     // true if manual, false if auto
}
```

### Tenant Collection

```dart
class TenantModel {
  final String ownerId;                  // Business Owner user_id
  
  // Tenant-specific subscription
  final String subscriptionTier;         // 'free' | 'premium'
  final String subscriptionStatus;       // 'active' | 'paused' | 'expired'
  final DateTime? subscriptionExpiresAt;
  final DateTime? subscriptionPausedAt;
  final int? pausedDaysRemaining;
  final String paymentStatus;            // 'free' | 'self_paid' | 'via_business_owner'
  
  // Computed property
  String get effectiveTier {
    // Check if owner is premium
    if (owner.subscriptionTier == 'premium') return 'premium';
    
    // Check own subscription
    if (subscriptionTier == 'premium' && subscriptionStatus == 'active') {
      return 'premium';
    }
    
    return 'free';
  }
}
```

---

## Implementation Plan

### Phase 1: Database & Backend (Week 1)

**Tasks:**
- [ ] Update database schema (add tenant subscription fields)
- [ ] Create Appwrite functions:
  - [ ] `handle-bo-upgrade` - Pause tenant subscriptions
  - [ ] `handle-bo-downgrade` - Resume tenant subscriptions
  - [ ] `auto-select-tenants` - Revenue-based selection at D-0
- [ ] Update `cleanup-expired-contracts` function
- [ ] Add `getEffectiveTier()` helper method

**Files:**
- `functions/handle-bo-upgrade/src/main.js` (NEW)
- `functions/handle-bo-downgrade/src/main.js` (NEW)
- `functions/cleanup-expired-contracts/src/main.js` (UPDATE)
- `lib/shared/models/tenant_model.dart` (UPDATE)
- `lib/shared/models/user_model.dart` (UPDATE)

---

### Phase 2: Business Owner Frontend (Week 2)

**Tasks:**
- [ ] Block restricted actions in free tier:
  - [ ] Disable "Create/Edit Tenant" → Show upgrade dialog
  - [ ] Disable "Create/Edit User" → Show upgrade dialog
  - [ ] Block "Laporan" menu → Show upgrade dialog
- [ ] Add D-7 selection banner
- [ ] Create upgrade dialog with tenant benefit messaging
- [ ] Add subscription status display on dashboard

**Files:**
- `lib/features/business_owner/presentation/business_owner_dashboard.dart`
- `lib/features/business_owner/presentation/pages/manage_tenants_page.dart`
- `lib/features/business_owner/presentation/pages/tenant_user_management_page.dart`
- `lib/features/business_owner/presentation/widgets/upgrade_dialog.dart` (NEW)
- `lib/features/business_owner/presentation/widgets/d7_selection_banner.dart` (NEW)

---

### Phase 3: Tenant Frontend (Week 2)

**Tasks:**
- [ ] Check `effectiveTier` for access control
- [ ] Block restricted actions in free tier:
  - [ ] Disable "Create/Edit Product" → Show upgrade dialog
  - [ ] Disable "Create/Edit Category" → Show upgrade dialog
  - [ ] Disable "Invite/Edit Staff" → Show upgrade dialog
  - [ ] Block "Laporan Saya" menu → Show upgrade dialog
- [ ] Show pause notice if subscription paused
- [ ] Update upgrade dialog (mention BO upgrade option)

**Files:**
- `lib/features/tenant/presentation/tenant_dashboard.dart`
- `lib/features/tenant/presentation/pages/product_management_page.dart`
- `lib/features/tenant/presentation/pages/category_management_page.dart`
- `lib/features/tenant/presentation/pages/staff_management_page.dart`
- `lib/features/tenant/presentation/widgets/subscription_paused_notice.dart` (NEW)

---

### Phase 4: Testing (Week 3)

**Test Cases:**
- [ ] Test 30-day trial flow
- [ ] Test D-7 selection banner
- [ ] Test manual tenant selection
- [ ] Test auto-selection by revenue
- [ ] Test BO upgrade → Tenant auto-upgrade
- [ ] Test BO upgrade → Tenant pause mechanism
- [ ] Test BO downgrade → Tenant resume mechanism
- [ ] Test free tier restrictions (all CRUD operations)
- [ ] Test premium access (BO and Tenant)

---

## Estimated Timeline

**Total Duration:** 3 weeks

- Week 1: Backend & Database (40%)
- Week 2: Frontend Implementation (40%)
- Week 3: Testing & Polish (20%)

**Team Size:** 1-2 developers  
**Total Hours:** ~80-100 hours

---

## Success Metrics

**Business Metrics:**
- Trial to Premium conversion rate > 10%
- Average tenants per BO > 3
- Tenant independent subscription rate > 5%

**Technical Metrics:**
- Zero data loss in pause/resume
- Correct effective_tier calculation 100%
- Auto-selection accuracy 100%

---

**Document Status:** ✅ Approved for Implementation  
**Next Step:** Phase 1 - Database & Backend Development
