y# Real-time Menu Updates Feature

## Tujuan
Agar guest bisa langsung tahu kalau produk yang mereka lihat sudah tidak tersedia lagi saat tenant toggle OFF produk tersebut.

## Use Cases

### **Case 1: Guest Browsing Menu**
```
Guest buka menu → Lihat "Nasi Goreng" (Tersedia)
Tenant toggle OFF "Nasi Goreng"
→ Menu guest auto-refresh → "Nasi Goreng" (Tidak Tersedia)
```

### **Case 2: Produk di Cart**
```
Guest add "Es Teh" ke cart
Tenant toggle OFF "Es Teh"  
→ Cart shows badge "⚠️ Tidak Tersedia"
→ User bisa pilih: hapus atau tetap lanjut checkout
```

### **Case 3: Sudah Bayar/Order**
```
Guest bayar order dengan "Kopi Susu"
Tenant toggle OFF "Kopi Susu" (setelah payment)
→ Order tetap masuk
→ Staff/Tenant view shows badge: "🔴 Menu tidak tersedia saat ini"
→ Staff bisa cancel order jika perlu
```

## Implementation

### Component 1: Appwrite Realtime Subscription
**File:** `guest_products_provider.dart`
- Subscribe to products collection updates
- Auto-refresh when product availability changes
- Only for current tenant's products

### Component 2: Cart Validation
**File:** `cart_item_widget.dart`
- Check product `isAvailable` status
- Show warning badge if unavailable
- Don't block checkout (let user decide)

### Component 3: Staff Order Badge
**File:** `order_item_card.dart`
- For each order item, check current availability
- Show badge if menu no longer available
- Helps staff know which items to check

## Technical Details

### Appwrite Realtime
```dart
realtime.subscribe([
  'databases.kantin-db.collections.products.documents'
])
```

### Events to Monitor
- `databases.*.collections.*.documents.*.update` → Product updated
- Check `tenant_id` matches
- Refresh product list

## Files Modified
1. `lib/features/guest/providers/guest_products_provider.dart`
2. `lib/features/guest/presentation/guest_menu_page.dart`  
3. `lib/features/guest/presentation/widgets/cart_item_widget.dart`
4. `lib/features/tenant/presentation/widgets/order_item_card.dart`

## Testing
- [ ] Guest menu auto-updates when tenant toggles
- [ ] Cart shows badge for unavailable items
- [ ] Staff order view shows unavailable badge
- [ ] Real-time works across multiple devices

---

**Created:** 2025-12-15  
**Status:** In Progress
