# Sprint 2: Database Schema Documentation

**Created:** 25 November 2025  
**Purpose:** Complete schema definition untuk collections Sprint 2

---

## 📊 Collections Overview

Sprint 2 memerlukan 3 collections utama:
1. **`tenants`** - Informasi tenant/stand di kantin
2. **`categories`** - Kategori produk per tenant
3. **`products`** - Menu/produk yang dijual tenant

---

## 1️⃣ Collection: `tenants`

### **Collection ID:** `tenants`
### **Database ID:** `kantin-db`

### **Purpose:**
Menyimpan informasi tenant/stand yang dimiliki oleh business owner.

### **Attributes:**

```json
[
  {
    "key": "owner_id",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "name",
    "type": "string",
    "size": 100,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "type",
    "type": "enum",
    "elements": ["food", "beverage", "snack", "dessert", "other"],
    "required": true,
    "array": false,
    "default": "food"
  },
  {
    "key": "description",
    "type": "string",
    "size": 500,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "is_active",
    "type": "boolean",
    "required": true,
    "array": false,
    "default": true
  },
  {
    "key": "logo_url",
    "type": "url",
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "phone",
    "type": "string",
    "size": 20,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "display_order",
    "type": "integer",
    "min": 0,
    "max": 9999,
    "required": false,
    "array": false,
    "default": 0
  }
]
```

### **Indexes:**

```json
[
  {
    "key": "owner_id_index",
    "type": "key",
    "attributes": ["owner_id"],
    "orders": ["ASC"]
  },
  {
    "key": "active_tenants_index",
    "type": "key",
    "attributes": ["is_active"],
    "orders": ["DESC"]
  },
  {
    "key": "owner_active_index",
    "type": "key",
    "attributes": ["owner_id", "is_active"],
    "orders": ["ASC", "DESC"]
  }
]
```

### **Permissions:**

**Document Level:**
```javascript
// Read permissions (any user can read active tenants)
Read: ["any"]

// Write permissions (only owner and functions)
Create: ["users"]  // Any authenticated user can create
Update: ["label:owner_bussines"]  // Only owner can update their tenants
Delete: ["label:owner_bussines"]  // Only owner can delete their tenants
```

**Collection Level:**
```javascript
// In Appwrite Console > Settings > Permissions
- Role: "any" → Read
- Role: "users" → Create
- Role: "label:owner_bussines" → Read, Update, Delete
- Role: "applications" (Functions) → Create, Read, Update
```

### **Document-Level Permission Strategy:**
```javascript
// Set saat create tenant
permissions: [
  Permission.read(Role.any()),
  Permission.update(Role.user(ownerId)),
  Permission.delete(Role.user(ownerId))
]
```

---

## 2️⃣ Collection: `categories`

### **Collection ID:** `categories`
### **Database ID:** `kantin-db`

### **Purpose:**
Mengorganisir produk dalam kategori (misal: Mie, Nasi, Minuman, dll.)

### **Attributes:**

```json
[
  {
    "key": "tenant_id",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "name",
    "type": "string",
    "size": 100,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "description",
    "type": "string",
    "size": 255,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "display_order",
    "type": "integer",
    "min": 0,
    "max": 999,
    "required": false,
    "array": false,
    "default": 0
  },
  {
    "key": "is_active",
    "type": "boolean",
    "required": true,
    "array": false,
    "default": true
  }
]
```

### **Indexes:**

```json
[
  {
    "key": "tenant_categories_index",
    "type": "key",
    "attributes": ["tenant_id"],
    "orders": ["ASC"]
  },
  {
    "key": "tenant_active_categories",
    "type": "key",
    "attributes": ["tenant_id", "is_active"],
    "orders": ["ASC", "DESC"]
  },
  {
    "key": "display_order_index",
    "type": "key",
    "attributes": ["display_order"],
    "orders": ["ASC"]
  }
]
```

### **Permissions:**

**Collection Level:**
```javascript
- Role: "any" → Read (public can see categories)
- Role: "label:tenant" → Create, Read, Update, Delete (tenant manages own categories)
- Role: "applications" → Create, Read, Update, Delete
```

**Document-Level Permission Strategy:**
```javascript
// Set by tenant saat create category
permissions: [
  Permission.read(Role.any()),
  Permission.update(Role.user(tenantUserId)),
  Permission.delete(Role.user(tenantUserId))
]
```

---

## 3️⃣ Collection: `products`

### **Collection ID:** `products`
### **Database ID:** `kantin-db`

### **Purpose:**
Menyimpan daftar produk/menu yang dijual oleh tenant.

### **Attributes:**

```json
[
  {
    "key": "tenant_id",
    "type": "string",
    "size": 255,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "category_id",
    "type": "string",
    "size": 255,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "name",
    "type": "string",
    "size": 100,
    "required": true,
    "array": false,
    "default": null
  },
  {
    "key": "description",
    "type": "string",
    "size": 500,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "price",
    "type": "integer",
    "min": 0,
    "max": 100000000,
    "required": true,
    "array": false,
    "default": 0
  },
  {
    "key": "image_url",
    "type": "url",
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "is_available",
    "type": "boolean",
    "required": true,
    "array": false,
    "default": true
  },
  {
    "key": "stock",
    "type": "integer",
    "min": 0,
    "max": 9999,
    "required": false,
    "array": false,
    "default": null
  },
  {
    "key": "display_order",
    "type": "integer",
    "min": 0,
    "max": 9999,
    "required": false,
    "array": false,
    "default": 0
  }
]
```

### **Indexes:**

```json
[
  {
    "key": "tenant_products_index",
    "type": "key",
    "attributes": ["tenant_id"],
    "orders": ["ASC"]
  },
  {
    "key": "category_products_index",
    "type": "key",
    "attributes": ["category_id"],
    "orders": ["ASC"]
  },
  {
    "key": "available_products_index",
    "type": "key",
    "attributes": ["is_available"],
    "orders": ["DESC"]
  },
  {
    "key": "tenant_available_products",
    "type": "key",
    "attributes": ["tenant_id", "is_available"],
    "orders": ["ASC", "DESC"]
  },
  {
    "key": "price_index",
    "type": "key",
    "attributes": ["price"],
    "orders": ["ASC"]
  }
]
```

### **Permissions:**

**Collection Level:**
```javascript
- Role: "any" → Read (public can see products)
- Role: "label:tenant" → Create, Read, Update, Delete (tenant manages own products)
- Role: "applications" → Create, Read, Update, Delete
```

**Document-Level Permission Strategy:**
```javascript
// Set by tenant saat create product
permissions: [
  Permission.read(Role.any()),
  Permission.update(Role.user(tenantUserId)),
  Permission.delete(Role.user(tenantUserId))
]
```

---

## 🔐 Security Rules Summary

### **Key Principles:**

1. **Public Read Access:**
   - Semua collections dapat dibaca oleh `any` (guest/public)
   - Ini untuk mendukung flow pemesanan anonim di Sprint 3

2. **Owner Isolation:**
   - Business Owner hanya bisa manage tenant miliknya
   - Query filter by `owner_id`

3. **Tenant Isolation:**
   - Tenant hanya bisa manage category & product miliknya
   - Query filter by `tenant_id`

4. **Document-Level Permissions:**
   - Set saat create document
   - Owner specific: `Permission.update(Role.user(ownerId))`
   - Tenant specific: `Permission.update(Role.user(tenantUserId))`

---

## 📝 Implementation Checklist

### **Appwrite Console Steps:**

#### **1. Create Collection `tenants`**
- [ ] Navigate to Database > kantin-db
- [ ] Click "Create Collection"
- [ ] Collection ID: `tenants`
- [ ] Add attributes (8 attributes dari JSON di atas)
- [ ] Create indexes (3 indexes)
- [ ] Set collection-level permissions
- [ ] Enable "Document Security" (important!)

#### **2. Create Collection `categories`**
- [ ] Collection ID: `categories`
- [ ] Add attributes (5 attributes)
- [ ] Create indexes (3 indexes)
- [ ] Set permissions
- [ ] Enable "Document Security"

#### **3. Create Collection `products`**
- [ ] Collection ID: `products`
- [ ] Add attributes (9 attributes)
- [ ] Create indexes (5 indexes)
- [ ] Set permissions
- [ ] Enable "Document Security"

---

## 🎯 Example Documents

### **Example Tenant Document:**
```json
{
  "$id": "tenant_12345",
  "$createdAt": "2025-11-25T13:00:00.000Z",
  "$updatedAt": "2025-11-25T13:00:00.000Z",
  "$permissions": [
    "read(\"any\")",
    "update(\"user:owner_user_id\")",
    "delete(\"user:owner_user_id\")"
  ],
  "owner_id": "owner_user_id",
  "name": "Warung Mie Bu Ani",
  "type": "food",
  "description": "Mie ayam spesial dengan resep turun temurun",
  "is_active": true,
  "logo_url": "https://cloud.appwrite.io/v1/storage/buckets/logos/files/logo123/view",
  "phone": "081234567890",
  "display_order": 1
}
```

### **Example Category Document:**
```json
{
  "$id": "category_67890",
  "$createdAt": "2025-11-25T13:00:00.000Z",
  "$updatedAt": "2025-11-25T13:00:00.000Z",
  "$permissions": [
    "read(\"any\")",
    "update(\"user:tenant_user_id\")",
    "delete(\"user:tenant_user_id\")"
  ],
  "tenant_id": "tenant_12345",
  "name": "Mie Ayam",
  "description": "Berbagai varian mie ayam",
  "display_order": 1,
  "is_active": true
}
```

### **Example Product Document:**
```json
{
  "$id": "product_abc123",
  "$createdAt": "2025-11-25T13:00:00.000Z",
  "$updatedAt": "2025-11-25T13:00:00.000Z",
  "$permissions": [
    "read(\"any\")",
    "update(\"user:tenant_user_id\")",
    "delete(\"user:tenant_user_id\")"
  ],
  "tenant_id": "tenant_12345",
  "category_id": "category_67890",
  "name": "Mie Ayam Spesial",
  "description": "Mie ayam dengan topping telur, pangsit, dan bakso",
  "price": 15000,
  "image_url": "https://cloud.appwrite.io/v1/storage/buckets/products/files/img123/view",
  "is_available": true,
  "stock": null,
  "display_order": 1
}
```

---

## 🔄 Relationships

```
users (owner_bussines)
  └─ 1:N → tenants
              └─ 1:N → categories
              └─ 1:N → products
                          └─ N:1 → categories (optional)

users (tenant)
  └─ 1:1 → tenant (via tenant_id field in users collection)
              └─ 1:N → categories
              └─ 1:N → products
```

---

## 📌 Important Notes

### **1. Document Security:**
Pastikan "Document Security" di-enable untuk semua collections!
- Di Appwrite Console > Collection Settings > "Document Security" = ON
- Ini memungkinkan document-level permissions bekerja

### **2. Query Patterns:**

**Business Owner - Get My Tenants:**
```javascript
databases.listDocuments(
  databaseId,
  'tenants',
  [
    Query.equal('owner_id', currentUserId),
    Query.orderDesc('$createdAt')
  ]
);
```

**Tenant - Get My Products:**
```javascript
databases.listDocuments(
  databaseId,
  'products',
  [
    Query.equal('tenant_id', currentTenantId),
    Query.equal('is_available', true),
    Query.orderAsc('display_order')
  ]
);
```

**Guest - Get All Tenants (Public):**
```javascript
databases.listDocuments(
  databaseId,
  'tenants',
  [
    Query.equal('is_active', true),
    Query.orderAsc('display_order')
  ]
);
```

### **3. Migration from Old Schema:**
Jika ada perubahan dari rencana awal, pastikan:
- Update `users` collection untuk tambah field `tenant_id` (jika belum ada)
- Field ini untuk link user dengan role `tenant` ke tenant document mereka

---

## ✅ Validation Checklist

Sebelum lanjut ke coding, pastikan:
- [ ] 3 Collections sudah dibuat dengan ID yang benar
- [ ] Semua attributes sesuai tipe data dan constraints
- [ ] Indexes sudah dibuat (untuk performa query)
- [ ] Collection-level permissions sudah di-set
- [ ] Document Security sudah di-enable
- [ ] Test create 1 document manual untuk validasi permissions

---

**Ready untuk Sprint 2 Development!** 🚀
