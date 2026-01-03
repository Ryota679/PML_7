# Sprint 2: Create Collections via Appwrite CLI v11
# Using correct kebab-case parameter names

Write-Host "=== Sprint 2: Database Collections Setup ===" -ForegroundColor Cyan
Write-Host ""

$DB = "kantin-db"

Write-Host "Database: $DB" -ForegroundColor Yellow
Write-Host ""

# ============================================
# 1. CREATE COLLECTION: tenants
# ============================================
Write-Host "[1/3] Creating collection: tenants..." -ForegroundColor Green

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

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "owner_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-enum-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "type" `
    --elements "food" "beverage" "snack" "dessert" "other" `
    --required true `
    --default "food"

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "is_active" `
    --required true `
    --default true

appwrite databases create-url-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "logo_url" `
    --required false

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "phone" `
    --size 20 `
    --required false

appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "tenants" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "      Waiting for attributes..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --database-id $DB `
    --collection-id "tenants" `
    --key "owner_id_index" `
    --type "key" `
    --attributes "owner_id" `
    --orders "ASC"

appwrite databases create-index `
    --database-id $DB `
    --collection-id "tenants" `
    --key "active_index" `
    --type "key" `
    --attributes "is_active" `
    --orders "DESC"

Write-Host "[OK] tenants: 8 attributes, 2 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# 2. CREATE COLLECTION: categories
# ============================================
Write-Host "[2/3] Creating collection: categories..." -ForegroundColor Green

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

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "description" `
    --size 255 `
    --required false

appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "display_order" `
    --min 0 `
    --max 999 `
    --required false `
    --default 0

appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "categories" `
    --key "is_active" `
    --required true `
    --default true

Write-Host "      Waiting for attributes..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --database-id $DB `
    --collection-id "categories" `
    --key "tenant_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases create-index `
    --database-id $DB `
    --collection-id "categories" `
    --key "order_index" `
    --type "key" `
    --attributes "display_order" `
    --orders "ASC"

Write-Host "[OK] categories: 5 attributes, 2 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# 3. CREATE COLLECTION: products
# ============================================
Write-Host "[3/3] Creating collection: products..." -ForegroundColor Green

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

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "category_id" `
    --size 255 `
    --required false

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-string-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "price" `
    --min 0 `
    --max 100000000 `
    --required true `
    --default 0

appwrite databases create-url-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "image_url" `
    --required false

appwrite databases create-boolean-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "is_available" `
    --required true `
    --default true

appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "stock" `
    --min 0 `
    --max 9999 `
    --required false

appwrite databases create-integer-attribute `
    --database-id $DB `
    --collection-id "products" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "      Waiting for attributes..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "tenant_products" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "category_products" `
    --type "key" `
    --attributes "category_id" `
    --orders "ASC"

appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "available_products" `
    --type "key" `
    --attributes "is_available" `
    --orders "DESC"

appwrite databases create-index `
    --database-id $DB `
    --collection-id "products" `
    --key "price_index" `
    --type "key" `
    --attributes "price" `
    --orders "ASC"

Write-Host "[OK] products: 9 attributes, 4 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# SUMMARY
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Collections Created Successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [OK] tenants     (8 attributes, 2 indexes)" -ForegroundColor White
Write-Host "  [OK] categories  (5 attributes, 2 indexes)" -ForegroundColor White
Write-Host "  [OK] products    (9 attributes, 4 indexes)" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "NEXT STEP: Set Permissions in Console" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Appwrite Console > Database > kantin-db > Each Collection > Settings > Permissions" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. tenants collection:" -ForegroundColor White
Write-Host "   - Any:             Read" -ForegroundColor Gray
Write-Host "   - Users:           Create" -ForegroundColor Gray
Write-Host "   - owner_bussines:  Read, Update, Delete" -ForegroundColor Gray
Write-Host "   - Applications:    Create, Read, Update" -ForegroundColor Gray
Write-Host ""
Write-Host "2. categories collection:" -ForegroundColor White
Write-Host "   - Any:             Read" -ForegroundColor Gray
Write-Host "   - tenant:          Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host "   - Applications:    Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host ""
Write-Host "3. products collection:" -ForegroundColor White
Write-Host "   - Any:             Read" -ForegroundColor Gray
Write-Host "   - tenant:          Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host "   - Applications:    Create, Read, Update, Delete" -ForegroundColor Gray
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
