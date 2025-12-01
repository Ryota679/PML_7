# Appwrite Orders Collection - Permission Setup Guide

## Collection Permissions (Table Level)

Saat setup collection `orders` di Appwrite Console, gunakan permissions berikut:

### ✅ Correct Permissions

```
┌─────────────────────────────────────────────────────┐
│ Permissions                                         │
├────────────┬────────────────────────────────────────┤
│ Role       │ Create  Read  Update  Delete           │
├────────────┼────────────────────────────────────────┤
│ Any        │   ✓      ✓      ✗       ✗             │
│ Label      │                                         │
│  - tenant  │   ✗      ✗      ✓       ✓             │
│  - staff   │   ✗      ✗      ✓       ✗             │
│  - admin   │   ✗      ✗      ✗       ✓             │
│   system   │                                         │
└────────────┴────────────────────────────────────────┘
```

### Step-by-Step di Appwrite Console:

#### 1. Create Permission
- Click "Add role"
- Select: **Any**
- Check: ✓ Create
- Check: ✓ Read

#### 2. Update Permission (Tenant)
- Click "Add role"
- Select: **Label**
- Type: `tenant` (lowercase)
- Check: ✓ Update

#### 3. Update Permission (Staff)
- Click "Add role"
- Select: **Label**
- Type: `staff` (lowercase)
- Check: ✓ Update

#### 4. Delete Permission (Tenant)
- Click "Add role"
- Select: **Label**
- Type: `tenant` (lowercase)
- Check: ✓ Delete

#### 5. Delete Permission (Admin)
- Click "Add role"
- Select: **Label**
- Type: `adminsystem` (sesuai label di Auth Anda)
- Check: ✓ Delete

---

## Why This Design?

### ✅ Create: Any
**Use Case:** Guest checkout tanpa login
- Guest tidak perlu register untuk order
- Order langsung dibuat saat checkout
- Customer name disimpan di order, bukan di Auth

### ✅ Read: Any
**Use Case:** Guest order tracking
- Customer bisa track order via order number (ORD-123456)
- Tidak perlu login untuk cek status
- Public API: `/order/:orderNumber`

### ✅ Update: tenant + staff
**Use Case:** Update order status (pending → preparing → ready)
- Tenant dapat update status order di tenant mereka
- Staff juga dapat update (delegated access)
- Business Owner & Admin TIDAK bisa update (bukan workflow mereka)

**Security Layer:**
```dart
// App-layer validation
if (currentUser.tenantId != order.tenantId) {
  throw UnauthorizedException();
}
```

### ✅ Delete: tenant + adminsystem
**Use Case:** Cancel order atau cleanup
- Tenant dapat cancel/delete order yang salah
- Admin dapat cleanup data untuk maintenance
- Staff TIDAK bisa delete (prevent accidental deletion)

---

## Security Considerations

### 🔒 Document-Level Permissions (Optional Enhancement)

Jika ingin security lebih ketat, gunakan document permissions saat create order:

```javascript
// Dalam createOrder Appwrite Function
const order = await databases.createDocument(
  DATABASE_ID,
  ORDERS_COLLECTION_ID,
  ID.unique(),
  orderData,
  [
    Permission.read(Role.any()),
    Permission.update(Role.label('tenant')),
    Permission.update(Role.label('staff')),
    Permission.delete(Role.label('tenant')),
    Permission.delete(Role.label('adminsystem')),
  ]
);
```

**Benefit:** Lebih granular, tapi collection-level permission sudah cukup untuk use case ini.

---

## Testing Permissions

### Test Case 1: Guest Create Order
```
User: Not authenticated
Action: POST /order
Expected: ✅ Success
```

### Test Case 2: Guest Read Order
```
User: Not authenticated
Action: GET /order/ORD-123456
Expected: ✅ Success
```

### Test Case 3: Tenant Update Order (Own Tenant)
```
User: Authenticated (label: tenant, tenant_id: ABC)
Action: PATCH /order/XYZ (order.tenant_id = ABC)
Expected: ✅ Success
```

### Test Case 4: Tenant Update Order (Different Tenant)
```
User: Authenticated (label: tenant, tenant_id: ABC)
Action: PATCH /order/XYZ (order.tenant_id: DEF)
Expected: ❌ 401 Unauthorized (app-layer validation)
```

### Test Case 5: Business Owner Update Order
```
User: Authenticated (label: BusinessOwner)
Action: PATCH /order/XYZ
Expected: ❌ 401 Unauthorized (no tenant/staff label)
```

### Test Case 6: Tenant Delete Order
```
User: Authenticated (label: tenant, tenant_id: ABC)
Action: DELETE /order/XYZ (order.tenant_id = ABC)
Expected: ✅ Success
```

### Test Case 7: Staff Delete Order
```
User: Authenticated (label: staff)
Action: DELETE /order/XYZ
Expected: ❌ 401 Unauthorized (staff tidak punya delete permission)
```

---

## Migration Notes

**If you already created the collection with wrong permissions:**

1. Go to Appwrite Console → Database → Orders collection
2. Click "Settings" → "Permissions" tab
3. Delete existing permissions
4. Add new permissions as documented above
5. Save changes

**No data migration needed** - hanya update permissions.
