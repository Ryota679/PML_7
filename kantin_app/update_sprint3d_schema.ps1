# Sprint 3D: Update Orders Collection
# Add customer_id field untuk link orders to registered customers

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Sprint 3D: Update Orders Schema" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$DB_ID = "kantin-db"
$ORDERS_ID = "orders"

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
Write-Host "Will add 'customer_id' field to orders collection" -ForegroundColor Yellow
Write-Host "This is backward compatible (optional field)" -ForegroundColor Green
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y") {
    Write-Host "Cancelled" -ForegroundColor Red
    exit 0
}
Write-Host ""

# Add customer_id attribute
Write-Host "Adding customer_id attribute..." -ForegroundColor Cyan
appwrite databases create-string-attribute --database-id $DB_ID --collection-id $ORDERS_ID --key customer_id --size 255 --required false 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Attribute created" -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Could not create attribute" -ForegroundColor Red
    Write-Host "Note: Field might already exist" -ForegroundColor Yellow
}

# Wait for attribute to be ready
Write-Host "`nWaiting 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Create index on customer_id
Write-Host "`nCreating index on customer_id..." -ForegroundColor Cyan
appwrite databases create-index --database-id $DB_ID --collection-id $ORDERS_ID --key idx_customer_id --type key --attributes customer_id 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Index created" -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Could not create index" -ForegroundColor Red
    Write-Host "Note: Index might already exist" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "UPDATE COMPLETE!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Changes:" -ForegroundColor Cyan
Write-Host "  - orders.customer_id (String, optional)" -ForegroundColor White
Write-Host "  - Index: idx_customer_id" -ForegroundColor White
Write-Host ""
Write-Host "Backward Compatible:" -ForegroundColor Green
Write-Host "  - Existing guest orders: customer_id = null" -ForegroundColor White
Write-Host "  - New customer orders: customer_id = {userId}" -ForegroundColor White
Write-Host ""
Write-Host "Next: Verify 'users' collection supports role='customer'" -ForegroundColor Yellow
Write-Host ""
