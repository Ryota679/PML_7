# Sprint 2: Import Collections to Appwrite

**Created:** 25 November 2025

⚠️ **Note:** Appwrite Console tidak fully support JSON import untuk collections. Collections harus dibuat via Console UI atau CLI.

Namun, kita sudah punya collection `tenants` yang partially created. Berikut langkah-langkahnya:

---

## ✅ **Current Status**

### **Collection: tenants (Partial)**
- ✅ Collection created
- ✅ 6/8 attributes created:
  - `owner_id` (string, 255)
  - `name` (string, 100) 
  - `description` (string, 500)
  - `logo_url` (url)
  - `phone` (string, 20)
- ❌ Missing 2 attributes:
  - `type` (enum)
  - `is_active` (boolean)
  - `display_order` (integer)
- ⏳ 1/2 indexes created:
  - `owner_id_index`
- ❌ Missing 1 index:
  - `active_tenants_index`

---

## 📋 **Manual Completion Steps**

### **Step 1: Complete `tenants` Collection**

#### **1.1 Add Missing Attributes:**

**Go to:** Appwrite Console > Database > kantin-db > tenants > Attributes

**Add Attribute #1: type (Enum)**
```
Type: Enum
Key: type
Elements: food, beverage, snack, dessert, other
Required: ✓ Yes
Default: food
Array: ✗ No
```

**Add Attribute #2: is_active (Boolean)**
```
Type: Boolean
Key: is_active
Required: ✓ Yes
Default: true
Array: ✗ No
```

**Add Attribute #3: display_order (Integer)**
```
Type: Integer
Key: display_order
Min: 0
Max: 9999
Required: ✗ No
Default: 0
Array: ✗ No
```

#### **1.2 Add Missing Index:**

**Go to:** tenants > Indexes

**Add Index:**
```
Key: active_tenants_index
Type: Key
Attributes: is_active
Order: DESC
```

#### **1.3 Set Permissions:**

**Go to:** tenants > Settings > Permissions

**Add these role permissions:**
- Role: `Any` → ☑️ Read
- Role: `Users` → ☑️ Create
- Role: `Label:owner_bussines` → ☑️ Read, Update, Delete
- Role: `Applications` → ☑️ Create, Read, Update

---

### **Step 2: Create `categories` Collection**

**Go to:** Database > kantin-db > Create Collection

**Collection Settings:**
```
Collection ID: categories
Name: categories
Document Security: ✓ Enabled
Enabled: ✓ Yes
```

**Attributes (5):**

1. **tenant_id**
   - Type: String, Size: 255, Required: ✓

2. **name**
   - Type: String, Size: 100, Required: ✓

3. **description**
   - Type: String, Size: 255, Required: ✗

4. **display_order**
   - Type: Integer, Min: 0, Max: 999, Required: ✗, Default: 0

5. **is_active**
   - Type: Boolean, Required: ✓, Default: true

**Indexes (2):**

1. **tenant_categories_index**
   - Type: Key, Attributes: tenant_id, Order: ASC

2. **display_order_index**
   - Type: Key, Attributes: display_order, Order: ASC

**Permissions:**
- Role: `Any` → ☑️ Read
- Role: `Label:tenant` → ☑️ Create, Read, Update, Delete
- Role: `Applications` → ☑️ Create, Read, Update, Delete

---

### **Step 3: Create `products` Collection**

**Go to:** Database > kantin-db > Create Collection

**Collection Settings:**
```
Collection ID: products
Name: products
Document Security: ✓ Enabled
Enabled: ✓ Yes
```

**Attributes (9):**

1. **tenant_id**
   - Type: String, Size: 255, Required: ✓

2. **category_id**
   - Type: String, Size: 255, Required: ✗

3. **name**
   - Type: String, Size: 100, Required: ✓

4. **description**
   - Type: String, Size: 500, Required: ✗

5. **price**
   - Type: Integer, Min: 0, Max: 100000000, Required: ✓, Default: 0

6. **image_url**
   - Type: URL, Required: ✗

7. **is_available**
   - Type: Boolean, Required: ✓, Default: true

8. **stock**
   - Type: Integer, Min: 0, Max: 9999, Required: ✗

9. **display_order**
   - Type: Integer, Min: 0, Max: 9999, Required: ✗, Default: 0

**Indexes (4):**

1. **tenant_products_index**
   - Type: Key, Attributes: tenant_id, Order: ASC

2. **category_products_index**
   - Type: Key, Attributes: category_id, Order: ASC

3. **available_products_index**
   - Type: Key, Attributes: is_available, Order: DESC

4. **price_index**
   - Type: Key, Attributes: price, Order: ASC

**Permissions:**
- Role: `Any` → ☑️ Read
- Role: `Label:tenant` → ☑️ Create, Read, Update, Delete
- Role: `Applications` → ☑️ Create, Read, Update, Delete

---

## ✅ **Verification Checklist**

After completing all steps:

- [ ] Collection `tenants` has 8 attributes
- [ ] Collection `tenants` has 2 indexes
- [ ] Collection `tenants` permissions are set
- [ ] Collection `categories` created with 5 attributes
- [ ] Collection `categories` has 2 indexes
- [ ] Collection `categories` permissions are set
- [ ] Collection `products` created with 9 attributes
- [ ] Collection `products` has 4 indexes
- [ ] Collection `products` permissions are set

---

## 🎯 **Testing**

After setup, test dengan create sample documents:

### **Test: Create Tenant**
```javascript
databases.createDocument(
  'kantin-db',
  'tenants',
  ID.unique(),
  {
    owner_id: 'your_user_id',
    name: 'Warung Mie Bu Ani',
    type: 'food',
    description: 'Mie ayam enak',
    is_active: true,
    display_order: 1
  }
);
```

### **Test: Create Category**
```javascript
databases.createDocument(
  'kantin-db',
  'categories',
  ID.unique(),
  {
    tenant_id: 'tenant_id_from_above',
    name: 'Mie Ayam',
    is_active: true,
    display_order: 1
  }
);
```

### **Test: Create Product**
```javascript
databases.createDocument(
  'kantin-db',
  'products',
  ID.unique(),
  {
    tenant_id: 'tenant_id_from_above',
    category_id: 'category_id_from_above',
    name: 'Mie Ayam Spesial',
    description: 'Mie ayam + telur',
    price: 15000,
    is_available: true,
    display_order: 1
  }
);
```

---

## ⏱️ **Estimated Time**

- Complete tenants: ~5 minutes
- Create categories: ~10 minutes
- Create products: ~15 minutes
- **Total: ~30 minutes**

---

**Good luck! 🚀**
