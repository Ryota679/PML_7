# Sprint 3A: Deploy Collections - FINAL FIXED VERSION
# All parameters must use kebab-case!

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Sprint 3A: Collection Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$DB_ID = "kantin-db"
$ORDERS_ID = "orders"
$ITEMS_ID = "order_items"

# Check CLI
Write-Host "Checking CLI..." -ForegroundColor Yellow
appwrite --version 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Appwrite CLI not found!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] CLI ready" -ForegroundColor Green
Write-Host ""

# Confirm
Write-Host "Will DELETE old 'orders' collection!" -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y") {
    Write-Host "Cancelled" -ForegroundColor Red
    exit 0
}
Write-Host ""

# Delete old
Write-Host "[1/3] Deleting old orders..." -ForegroundColor Cyan
appwrite databases delete-collection --database-id $DB_ID --collection-id $ORDERS_ID 2>$null
Write-Host "OK - Deleted`n" -ForegroundColor Green

# Create Orders
Write-Host "[2/3] Creating Orders collection..." -ForegroundColor Cyan
appwrite databases create-collection --database-id $DB_ID --collection-id $ORDERS_ID --name "Orders" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "OK - Collection created" -ForegroundColor Green
Start-Sleep -Seconds 2

# Orders Attributes
Write-Host "Creating 8 attributes..." -ForegroundColor Yellow
appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key order_number --size 50 --required true 2>&1 | Out-Null
Write-Host "  1/8 order_number" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key tenant_id --size 255 --required true 2>&1 | Out-Null
Write-Host "  2/8 tenant_id" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key customer_name --size 255 --required true 2>&1 | Out-Null
Write-Host "  3/8 customer_name" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key customer_contact --size 100 --required true 2>&1 | Out-Null
Write-Host "  4/8 customer_contact" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key table_number --size 50 --required false 2>&1 | Out-Null
Write-Host "  5/8 table_number" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-integer-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key total_amount --required true --default 0 2>&1 | Out-Null
Write-Host "  6/8 total_amount" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key status --size 50 --required true --default pending 2>&1 | Out-Null
Write-Host "  7/8 status" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key notes --size 500 --required false 2>&1 | Out-Null
Write-Host "  8/8 notes" -ForegroundColor Gray
Write-Host "OK - Attributes created`n" -ForegroundColor Green

Write-Host "Waiting 5s for attributes..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Orders Indexes
Write-Host "Creating 3 indexes..." -ForegroundColor Yellow
appwrite databases create-index --database-id $DB_ID --collection-id $ORDERS_ID --key idx_tenant_id --type key --attributes tenant_id 2>&1 | Out-Null
Write-Host "  1/3 idx_tenant_id" -ForegroundColor Gray
Start-Sleep -Seconds 1

appwrite databases create-index --database-id $DB_ID --collection-id $ORDERS_ID --key idx_status --type key --attributes status 2>&1 | Out-Null
Write-Host "  2/3 idx_status" -ForegroundColor Gray
Start-Sleep -Seconds 1

appwrite databases create-index --database-id $DB_ID --collection-id $ORDERS_ID --key idx_order_number --type unique --attributes order_number 2>&1 | Out-Null
Write-Host "  3/3 idx_order_number" -ForegroundColor Gray
Write-Host "OK - Indexes created`n" -ForegroundColor Green

# Create Order Items
Write-Host "[3/3] Creating Order Items collection..." -ForegroundColor Cyan
appwrite databases create-collection --database-id $DB_ID --collection-id $ITEMS_ID --name "Order Items" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "OK - Collection created" -ForegroundColor Green
Start-Sleep -Seconds 2

# Order Items Attributes
Write-Host "Creating 7 attributes..." -ForegroundColor Yellow
appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key order_id --size 255 --required true 2>&1 | Out-Null
Write-Host "  1/7 order_id" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key product_id --size 255 --required true 2>&1 | Out-Null
Write-Host "  2/7 product_id" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key product_name --size 255 --required true 2>&1 | Out-Null
Write-Host "  3/7 product_name" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-integer-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key product_price --required true 2>&1 | Out-Null
Write-Host "  4/7 product_price" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-integer-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key quantity --required true --default 1 2>&1 | Out-Null
Write-Host "  5/7 quantity" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-integer-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key subtotal --required true 2>&1 | Out-Null
Write-Host "  6/7 subtotal" -ForegroundColor Gray
Start-Sleep -Milliseconds 500

appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ITEMS_ID --key notes --size 255 --required false 2>&1 | Out-Null
Write-Host "  7/7 notes" -ForegroundColor Gray
Write-Host "OK - Attributes created`n" -ForegroundColor Green

Write-Host "Waiting 5s for attributes..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Order Items Indexes
Write-Host "Creating 2 indexes..." -ForegroundColor Yellow
appwrite databases create-index --database-id $DB_ID --collection-id $ITEMS_ID --key idx_order_id --type key --attributes order_id 2>&1 | Out-Null
Write-Host "  1/2 idx_order_id" -ForegroundColor Gray
Start-Sleep -Seconds 1

appwrite databases create-index --database-id $DB_ID --collection-id $ITEMS_ID --key idx_product_id --type key --attributes product_id 2>&1 | Out-Null
Write-Host "  2/2 idx_product_id" -ForegroundColor Gray
Write-Host "OK - Indexes created`n" -ForegroundColor Green

# Done
Write-Host "==================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Success:" -ForegroundColor Cyan
Write-Host "  - orders (8 attributes, 3 indexes)" -ForegroundColor White
Write-Host "  - order_items (7 attributes, 2 indexes)" -ForegroundColor White
Write-Host ""
Write-Host "Next: Continue Sprint 3A UI" -ForegroundColor Yellow
Write-Host ""
