# Sprint 3A: Deploy Collections via Appwrite CLI

## Prerequisites

1. Install Appwrite CLI (jika belum):
```powershell
npm install -g appwrite-cli
```

2. Login ke Appwrite:
```powershell
appwrite login
```

3. Set project:
```powershell
appwrite init project
# Pilih: perojek-pml
```

## Option 1: Update via appwrite.json (Recommended)

File `appwrite.json` sudah saya update dengan schema baru. Deploy dengan:

```powershell
# Deploy semua collections
appwrite deploy collection

# Atau deploy specific database
appwrite deploy database kantin-db
```

## Option 2: Manual CLI Commands

Jika prefer manual commands:

### 1. Update Orders Collection

```powershell
# Delete old orders collection (WARNING: akan hapus data!)
appwrite deleteCollection --collectionId orders --databaseId kantin-db

# Create orders collection dengan schema baru
appwrite createCollection \
  --collectionId orders \
  --name "Orders" \
  --databaseId kantin-db \
  --permissions 'create("any")' 'read("users")' 'update("users")' 'delete("users")'

# Create attributes
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key order_number --size 50 --required true
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key tenant_id --size 255 --required true
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key customer_name --size 255 --required true
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key customer_contact --size 100 --required true
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key table_number --size 50 --required false
appwrite createIntegerAttribute --collectionId orders --databaseId kantin-db --key total_amount --required true --default 0
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key status --size 50 --required true --default pending
appwrite createStringAttribute --collectionId orders --databaseId kantin-db --key notes --size 500 --required false

# Create indexes
appwrite createIndex --collectionId orders --databaseId kantin-db --key idx_tenant_id --type key --attributes tenant_id
appwrite createIndex --collectionId orders --databaseId kantin-db --key idx_status --type key --attributes status
appwrite createIndex --collectionId orders --databaseId kantin-db --key idx_order_number --type unique --attributes order_number
appwrite createIndex --collectionId orders --databaseId kantin-db --key idx_created_at --type key --attributes '$createdAt' --orders DESC
```

### 2. Create Order Items Collection

```powershell
# Create order_items collection
appwrite createCollection \
  --collectionId order_items \
  --name "Order Items" \
  --databaseId kantin-db \
  --permissions 'create("any")' 'read("users")' 'update("users")' 'delete("users")'

# Create attributes
appwrite createStringAttribute --collectionId order_items --databaseId kantin-db --key order_id --size 255 --required true
appwrite createStringAttribute --collectionId order_items --databaseId kantin-db --key product_id --size 255 --required true
appwrite createStringAttribute --collectionId order_items --databaseId kantin-db --key product_name --size 255 --required true
appwrite createIntegerAttribute --collectionId order_items --databaseId kantin-db --key product_price --required true
appwrite createIntegerAttribute --collectionId order_items --databaseId kantin-db --key quantity --required true --default 1
appwrite createIntegerAttribute --collectionId order_items --databaseId kantin-db --key subtotal --required true
appwrite createStringAttribute --collectionId order_items --databaseId kantin-db --key notes --size 255 --required false

# Create indexes
appwrite createIndex --collectionId order_items --databaseId kantin-db --key idx_order_id --type key --attributes order_id
appwrite createIndex --collectionId order_items --databaseId kantin-db --key idx_product_id --type key --attributes product_id
```

## Option 3: Script Automation

Saya buatkan PowerShell script `deploy_sprint3a_collections.ps1` untuk automation.

Run dengan:
```powershell
.\deploy_sprint3a_collections.ps1
```

## Verification

Setelah deploy, verify:

```powershell
# List all collections
appwrite listCollections --databaseId kantin-db

# Get orders collection details
appwrite getCollection --collectionId orders --databaseId kantin-db

# Get order_items collection details  
appwrite getCollection --collectionId order_items --databaseId kantin-db
```

## Notes

- ⚠️ Jika update orders collection yang sudah ada data, backup dulu!
- ✅ Permissions: `create("any")` memungkinkan guest create order tanpa login
- ✅ Indexes optimal untuk query performance
- ✅ CLI lebih cepat dan reproducible vs manual Console

## Next Steps

Setelah collections deployed:
1. Test create order via Appwrite Console
2. Continue Sprint 3A: Implement Guest Menu UI
3. Implement Cart Page UI
