# Sprint 2: Create Collections via Appwrite CLI
# Run this script from project root directory

Write-Host "=== Sprint 2: Database Collections Setup ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DATABASE_ID = "kantin-db"
$PROJECT_ID = "perojek-pml"

Write-Host "Database ID: $DATABASE_ID" -ForegroundColor Yellow
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow
Write-Host ""

# ============================================
# 1. CREATE COLLECTION: tenants
# ============================================
Write-Host "Creating collection: tenants..." -ForegroundColor Green

appwrite databases create-collection `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --name "tenants" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Collection 'tenants' created successfully" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Failed to create collection 'tenants'" -ForegroundColor Red
}

# Add attributes for tenants
Write-Host "Adding attributes to tenants..." -ForegroundColor Yellow

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "owner_id" `
    --size 255 `
    --required true

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases createEnumAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "type" `
    --elements "food,beverage,snack,dessert,other" `
    --required true `
    --default "food"

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases createBooleanAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "is_active" `
    --required true `
    --default true

appwrite databases createUrlAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "logo_url" `
    --required false

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "phone" `
    --size 20 `
    --required false

appwrite databases createIntegerAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "[OK] Tenants attributes created!" -ForegroundColor Green
Write-Host "Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Create indexes for tenants
Write-Host "Creating indexes for tenants..." -ForegroundColor Yellow

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "owner_id_index" `
    --type "key" `
    --attributes "owner_id" `
    --orders "ASC"

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "tenants" `
    --key "active_tenants_index" `
    --type "key" `
    --attributes "is_active" `
    --orders "DESC"

Write-Host "[OK] Tenants indexes created!" -ForegroundColor Green
Write-Host ""

# ============================================
# 2. CREATE COLLECTION: categories
# ============================================
Write-Host "Creating collection: categories..." -ForegroundColor Green

appwrite databases createCollection `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --name "categories" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Collection 'categories' created successfully" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Failed to create collection 'categories'" -ForegroundColor Red
}

# Add attributes for categories
Write-Host "Adding attributes to categories..." -ForegroundColor Yellow

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "description" `
    --size 255 `
    --required false

appwrite databases createIntegerAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "display_order" `
    --min 0 `
    --max 999 `
    --required false `
    --default 0

appwrite databases createBooleanAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "is_active" `
    --required true `
    --default true

Write-Host "[OK] Categories attributes created!" -ForegroundColor Green
Write-Host "Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Create indexes for categories
Write-Host "Creating indexes for categories..." -ForegroundColor Yellow

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "tenant_categories_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "categories" `
    --key "display_order_index" `
    --type "key" `
    --attributes "display_order" `
    --orders "ASC"

Write-Host "[OK] Categories indexes created!" -ForegroundColor Green
Write-Host ""

# ============================================
# 3. CREATE COLLECTION: products
# ============================================
Write-Host "Creating collection: products..." -ForegroundColor Green

appwrite databases createCollection `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --name "products" `
    --documentSecurity true `
    --enabled true

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Collection 'products' created successfully" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Failed to create collection 'products'" -ForegroundColor Red
}

# Add attributes for products
Write-Host "Adding attributes to products..." -ForegroundColor Yellow

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "tenant_id" `
    --size 255 `
    --required true

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "category_id" `
    --size 255 `
    --required false

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "name" `
    --size 100 `
    --required true

appwrite databases createStringAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "description" `
    --size 500 `
    --required false

appwrite databases createIntegerAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "price" `
    --min 0 `
    --max 100000000 `
    --required true `
    --default 0

appwrite databases createUrlAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "image_url" `
    --required false

appwrite databases createBooleanAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "is_available" `
    --required true `
    --default true

appwrite databases createIntegerAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "stock" `
    --min 0 `
    --max 9999 `
    --required false

appwrite databases createIntegerAttribute `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "display_order" `
    --min 0 `
    --max 9999 `
    --required false `
    --default 0

Write-Host "[OK] Products attributes created!" -ForegroundColor Green
Write-Host "Waiting for attributes to be available..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Create indexes for products
Write-Host "Creating indexes for products..." -ForegroundColor Yellow

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "tenant_products_index" `
    --type "key" `
    --attributes "tenant_id" `
    --orders "ASC"

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "category_products_index" `
    --type "key" `
    --attributes "category_id" `
    --orders "ASC"

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "available_products_index" `
    --type "key" `
    --attributes "is_available" `
    --orders "DESC"

appwrite databases createIndex `
    --databaseId $DATABASE_ID `
    --collectionId "products" `
    --key "price_index" `
    --type "key" `
    --attributes "price" `
    --orders "ASC"

Write-Host "[OK] Products indexes created!" -ForegroundColor Green
Write-Host ""

# ============================================
# SUMMARY
# ============================================
Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Collections created:" -ForegroundColor Green
Write-Host "  [OK] tenants (8 attributes, 2 indexes)" -ForegroundColor White
Write-Host "  [OK] categories (5 attributes, 2 indexes)" -ForegroundColor White
Write-Host "  [OK] products (9 attributes, 4 indexes)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Set Collection Permissions Manually" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to Appwrite Console and set these permissions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "For 'tenants' collection:" -ForegroundColor Cyan
Write-Host "  - Role: any -> Read" -ForegroundColor White
Write-Host "  - Role: users -> Create" -ForegroundColor White
Write-Host "  - Role: label:owner_bussines -> Read, Update, Delete" -ForegroundColor White
Write-Host "  - Role: applications -> Create, Read, Update" -ForegroundColor White
Write-Host ""
Write-Host "For 'categories' collection:" -ForegroundColor Cyan
Write-Host "  - Role: any -> Read" -ForegroundColor White
Write-Host "  - Role: label:tenant -> Create, Read, Update, Delete" -ForegroundColor White
Write-Host "  - Role: applications -> Create, Read, Update, Delete" -ForegroundColor White
Write-Host ""
Write-Host "For 'products' collection:" -ForegroundColor Cyan
Write-Host "  - Role: any -> Read" -ForegroundColor White
Write-Host "  - Role: label:tenant -> Create, Read, Update, Delete" -ForegroundColor White
Write-Host "  - Role: applications -> Create, Read, Update, Delete" -ForegroundColor White
Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
