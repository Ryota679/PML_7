# Sprint 2: Create Collections via Appwrite CLI
# Appwrite CLI v11.1.1 - Using kebab-case commands

Write-Host "=== Sprint 2: Database Collections Setup ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DATABASE_ID = "kantin-db"

Write-Host "Database ID: $DATABASE_ID" -ForegroundColor Yellow
Write-Host ""

# ============================================
# 1. CREATE COLLECTION: tenants
# ============================================
Write-Host "[1/3] Creating collection: tenants..." -ForegroundColor Green

appwrite databases create-collection `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --name "tenants" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create collection 'tenants'" -ForegroundColor Red
    exit 1
}

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "owner_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-enum-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "type" `
    --elements "food" "beverage" "snack" "dessert" "other" `
    --required true `
    --default "food"

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases create-boolean-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "is_active" `
    --required true `
    --default true

appwrite databases create-url-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "logo_url" `
    --required false

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "phone" `
    --size 20 `
    --required false

appwrite databases create-integer-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "      Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "owner_id_index" `
    --type "key" `
    --attributes "owner_id" `
    --orders "ASC"

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "active_tenants_index" `
    --type "key" `
    --attributes "is_active" `
    --orders "DESC"

Write-Host "[OK] Collection 'tenants' created with 8 attributes and 2 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# 2. CREATE COLLECTION: categories
# ============================================
Write-Host "[2/3] Creating collection: categories..." -ForegroundColor Green

appwrite databases create-collection `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --name "categories" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create collection 'categories'" -ForegroundColor Red
    exit 1
}

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "description" `
    --size 255 `
    --required false

appwrite databases create-integer-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "display_order" `
    --min 0 `
    --max 999 `
    --required false `
    --default 0

appwrite databases create-boolean-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "is_active" `
    --required true `
    --default true

Write-Host "      Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "tenant_categories_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "display_order_index" `
    --type "key" `
    --attributes "display_order" `
    --orders "ASC"

Write-Host "[OK] Collection 'categories' created with 5 attributes and 2 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# 3. CREATE COLLECTION: products
# ============================================
Write-Host "[3/3] Creating collection: products..." -ForegroundColor Green

appwrite databases create-collection `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --name "products" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create collection 'products'" -ForegroundColor Red
    exit 1
}

Write-Host "      Adding attributes..." -ForegroundColor Yellow

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "category_id" `
    --size 255 `
    --required false

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases create-string-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases create-integer-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "price" `
    --min 0 `
    --max 100000000 `
    --required true `
    --default 0

appwrite databases create-url-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "image_url" `
    --required false

appwrite databases create-boolean-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "is_available" `
    --required true `
    --default true

appwrite databases create-integer-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "stock" `
    --min 0 `
    --max 9999 `
    --required false

appwrite databases create-integer-attribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "      Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "      Creating indexes..." -ForegroundColor Yellow

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "tenant_products_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "category_products_index" `
    --type "key" `
    --attributes "category_id" `
    --orders "ASC"

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "available_products_index" `
    --type "key" `
    --attributes "is_available" `
    --orders "DESC"

appwrite databases create-index `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "price_index" `
    --type "key" `
    --attributes "price" `
    --orders "ASC"

Write-Host "[OK] Collection 'products' created with 9 attributes and 4 indexes" -ForegroundColor Green
Write-Host ""

# ============================================
# SUMMARY
# ============================================
Write-Host "=== Collections Created Successfully! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  [OK] tenants     - 8 attributes, 2 indexes" -ForegroundColor White
Write-Host "  [OK] categories  - 5 attributes, 2 indexes" -ForegroundColor White
Write-Host "  [OK] products    - 9 attributes, 4 indexes" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "NEXT STEP: Set Collection Permissions" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to Appwrite Console > Database > kantin-db" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Collection: tenants" -ForegroundColor Cyan
Write-Host "   Settings > Permissions > Add Role Permissions:" -ForegroundColor White
Write-Host "   - Role: Any              -> [X] Read" -ForegroundColor Gray
Write-Host "   - Role: Users            -> [X] Create" -ForegroundColor Gray
Write-Host "   - Role: owner_bussines   -> [X] Read [X] Update [X] Delete" -ForegroundColor Gray
Write-Host "   - Role: Applications     -> [X] Create [X] Read [X] Update" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Collection: categories" -ForegroundColor Cyan
Write-Host "   Settings > Permissions > Add Role Permissions:" -ForegroundColor White
Write-Host "   - Role: Any              -> [X] Read" -ForegroundColor Gray
Write-Host "   - Role: tenant           -> [X] Create [X] Read [X] Update [X] Delete" -ForegroundColor Gray
Write-Host "   - Role: Applications     -> [X] Create [X] Read [X] Update [X] Delete" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Collection: products" -ForegroundColor Cyan
Write-Host "   Settings > Permissions > Add Role Permissions:" -ForegroundColor White
Write-Host "   - Role: Any              -> [X] Read" -ForegroundColor Gray
Write-Host "   - Role: tenant           -> [X] Create [X] Read [X] Update [X] Delete" -ForegroundColor Gray
Write-Host "   - Role: Applications     -> [X] Create [X] Read [X] Update [X] Delete" -ForegroundColor Gray
Write-Host ""
Write-Host "Script completed!" -ForegroundColor Green
Write-Host ""
