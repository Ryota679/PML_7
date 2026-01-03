# Add tenant_code field to tenants collection
# Run this script: .\add_tenant_code_field.ps1

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Adding tenant_code field to tenants collection" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$PROJECT_ID = "676b23ce003a57e7b9ab"
$DATABASE_ID = "676b248b001a47f62c39"
$TENANTS_COLLECTION_ID = "676b28500034bef6cbdd"

Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Green
Write-Host "Database ID: $DATABASE_ID" -ForegroundColor Green
Write-Host "Collection ID: $TENANTS_COLLECTION_ID" -ForegroundColor Green
Write-Host ""

# Add tenant_code attribute
Write-Host "Adding tenant_code attribute..." -ForegroundColor Yellow

appwrite databases createStringAttribute `
    --database-id $DATABASE_ID `
    --collection-id $TENANTS_COLLECTION_ID `
    --key "tenant_code" `
    --size 6 `
    --required false `
    --array false

if ($LASTEXITCODE -eq 0) {
    Write-Host "tenant_code attribute created" -ForegroundColor Green
}
else {
    Write-Host "Failed to create tenant_code attribute" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Create unique index
Write-Host "Creating unique index on tenant_code..." -ForegroundColor Yellow

appwrite databases createIndex `
    --database-id $DATABASE_ID `
    --collection-id $TENANTS_COLLECTION_ID `
    --key "idx_tenant_code" `
    --type "unique" `
    --attributes "tenant_code"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Unique index created" -ForegroundColor Green
}
else {
    Write-Host "Failed to create index" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Success! Database migration completed" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
