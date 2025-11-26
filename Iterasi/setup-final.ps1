# Sprint 2: Database Collections Setup - Final Version
# Fixed for Appwrite CLI v11.1.1

Write-Host "=== Sprint 2: Collections Setup (CLI v11) ===" -ForegroundColor Cyan
Write-Host ""

$DB = "kantin-db"
$ErrorActionPreference = "Continue"

# ============================================
# Helper: Delete collection if exists
# ============================================
function Remove-CollectionIfExists {
    param($CollectionId)
    
    Write-Host "Checking if collection '$CollectionId' exists..." -ForegroundColor Yellow
    $result = appwrite databases get-collection --database-id $DB --collection-id $CollectionId 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Collection '$CollectionId' exists. Deleting..." -ForegroundColor Yellow
        appwrite databases delete-collection --database-id $DB --collection-id $CollectionId
        Start-Sleep -Seconds 2
        Write-Host "Deleted!" -ForegroundColor Green
    }
    else {
        Write-Host "Collection '$CollectionId' does not exist. Proceeding..." -ForegroundColor Gray
    }
}

# ============================================
# 1. CREATE COLLECTION: tenants
# ============================================
Write-Host ""
Write-Host "[1/3] Setting up collection: tenants" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Remove-CollectionIfExists "tenants"

Write-Host "Creating collection..." -ForegroundColor Yellow

appwrite databases create-collection `
    --database-id $DB `
    --collection-id "tenants" `
    --name "tenants" `
    --document-security true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create tenants collection" -ForegroundColor Red
    exit 1
}

Write-Host "Adding attributes (8)..." -ForegroundColor Yellow

# Attribute 1: owner_id
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "owner_id" `
    --size 255 `
    --required true

# Attribute 2: name
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "name" `
    --size 100 `
    --required true

# Attribute 3: type (enum) - No default parameter
appwrite databases create-enum-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "type" `
    --elements "food" "beverage" "snack" "dessert" "other" `
    --required true

# Attribute 4: description
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "description" `
    --size 500 `
    --required false

# Attribute 5: is_active (boolean) - No default parameter
appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "is_active" `
    --required true

# Attribute 6: logo_url
appwrite databases create-url-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "logo_url" `
    --required false

# Attribute 7: phone
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "phone" `
    --size 20 `
    --required false

# Attribute 8: display_order (integer) - No default parameter
appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false

Write-Host "Waiting 15 seconds for attributes to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "Creating indexes (2)..." -ForegroundColor Yellow

# Index 1
appwrite databases create-index `
    --database-id $DB `
    --collection-id "tenants" `
    --key "owner_id_index" `
    --type "key" `
    --attributes "owner_id" `
    --orders "ASC"

# Index 2
appwrite databases create-index `
    --database-id $DB `
    --collection-id "tenants" `
    --key "active_index" `
    --type "key" `
    --attributes "is_active" `
    --orders "DESC"

Write-Host "[OK] tenants: 8 attributes, 2 indexes" -ForegroundColor Green

# ============================================
# 2. CREATE COLLECTION: categories
# ============================================
Write-Host ""
Write-Host "[2/3] Setting up collection: categories" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Remove-CollectionIfExists "categories"

Write-Host "Creating collection..." -ForegroundColor Yellow

appwrite databases create-collection `
    --database-id $DB `
    --collection-id "categories" `
    --name "categories" `
    --document-security true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create categories collection" -ForegroundColor Red
    exit 1
}

Write-Host "Adding attributes (5)..." -ForegroundColor Yellow

# Attribute 1: tenant_id
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "tenant_id" `
    --size 255 `
    --required true

# Attribute 2: name
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "name" `
    --size 100 `
    --required true

# Attribute 3: description
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "description" `
    --size 255 `
    --required false

# Attribute 4: display_order
appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "display_order" `
    --min 0 `
    --max 999 `
    --required false

# Attribute 5: is_active
appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "is_active" `
    --required true

Write-Host "Waiting 15 seconds for attributes to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "Creating indexes (2)..." -ForegroundColor Yellow

# Index 1
appwrite databases create-index `
    --database-id $DB `
    --collection-id "categories" `
    --key "tenant_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

# Index 2
appwrite databases create-index `
    --database-id $DB `
    --collection-id "categories" `
    --key "order_index" `
    --type "key" `
    --attributes "display_order" `
    --orders "ASC"

Write-Host "[OK] categories: 5 attributes, 2 indexes" -ForegroundColor Green

# ============================================
# 3. CREATE COLLECTION: products
# ============================================
Write-Host ""
Write-Host "[3/3] Setting up collection: products" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Remove-CollectionIfExists "products"

Write-Host "Creating collection..." -ForegroundColor Yellow

appwrite databases create-collection `
    --database-id $DB `
    --collection-id "products" `
    --name "products" `
    --document-security true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create products collection" -ForegroundColor Red
    exit 1
}

Write-Host "Adding attributes (9)..." -ForegroundColor Yellow

# Attribute 1: tenant_id
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "tenant_id" `
    --size 255 `
    --required true

# Attribute 2: category_id
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "category_id" `
    --size 255 `
    --required false

# Attribute 3: name
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "name" `
    --size 100 `
    --required true

# Attribute 4: description
appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "description" `
    --size 500 `
    --required false

# Attribute 5: price
appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "price" `
    --min 0 `
    --max 100000000 `
    --required true

# Attribute 6: image_url
appwrite databases create-url-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "image_url" `
    --required false

# Attribute 7: is_available
appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "is_available" `
    --required true

# Attribute 8: stock
appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "stock" `
    --min 0 `
    --max 9999 `
    --required false

# Attribute 9: display_order
appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false

Write-Host "Waiting 15 seconds for attributes to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "Creating indexes (4)..." -ForegroundColor Yellow

# Index 1
appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "tenant_products" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

# Index 2
appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "category_products" `
    --type "key" `
    --attributes "category_id" `
    --orders "ASC"

# Index 3
appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "available_products" `
    --type "key" `
    --attributes "is_available" `
    --orders "DESC"

# Index 4
appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "price_index" `
    --type "key" `
    --attributes "price" `
    --orders "ASC"

Write-Host "[OK] products: 9 attributes, 4 indexes" -ForegroundColor Green

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Collections Created Successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  [OK] tenants     - 8 attributes, 2 indexes" -ForegroundColor Green
Write-Host "  [OK] categories  - 5 attributes, 2 indexes" -ForegroundColor Green
Write-Host "  [OK] products    - 9 attributes, 4 indexes" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "NEXT STEP: Set Permissions" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to Appwrite Console > Database > kantin-db" -ForegroundColor Cyan
Write-Host ""
Write-Host "For each collection, go to Settings > Permissions:" -ForegroundColor White
Write-Host ""
Write-Host "1. tenants:" -ForegroundColor Cyan
Write-Host "   Any              -> Read" -ForegroundColor Gray
Write-Host "   Users            -> Create" -ForegroundColor Gray
Write-Host "   owner_bussines   -> Read, Update, Delete" -ForegroundColor Gray
Write-Host "   Applications     -> Create, Read, Update" -ForegroundColor Gray
Write-Host ""
Write-Host "2. categories:" -ForegroundColor Cyan
Write-Host "   Any              -> Read" -ForegroundColor Gray
Write-Host "   tenant           -> Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host "   Applications     -> All" -ForegroundColor Gray
Write-Host ""
Write-Host "3. products:" -ForegroundColor Cyan
Write-Host "   Any              -> Read" -ForegroundColor Gray
Write-Host "   tenant           -> Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host "   Applications     -> All" -ForegroundColor Gray
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
