# Populate Tenant Codes - Migration Script
# This script generates and updates tenant_code for all existing tenants in Appwrite

param(
    [string]$AppwriteEndpoint = "https://fra.cloud.appwrite.io/v1",
    [string]$ProjectId = "perojek-pml",
    [string]$DatabaseId = "kantin-db",
    [string]$CollectionId = "tenants",
    [string]$ApiKey = "standard_9d167733ad351429a14b1ac9d6937670cc8c5a626643f187d47a8260ba064000cb55bebc669f478b5041141f2b7e1d1bc5dad2ca7310cdb5e7dfd22fa8399ac6245c2b397d7b5d4400d57233929e9ca584382a8f0d1623725007d15974365e3a85421685c46c0aa2a92427e0a3dbb241b89e6fc054e45d8ace5c3d24d165b2b5"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Populate Tenant Codes Migration Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to generate 6-character code from tenant ID
function Get-TenantCode {
    param([string]$TenantId)
    
    # Simple hash-based code generator (same logic as Dart)
    $hash = 0
    foreach ($char in $TenantId.ToCharArray()) {
        $hash = (($hash * 31) + [int]$char) % 1000000
    }
    
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" # Exclude confusing chars (I, O, 0, 1)
    $code = ""
    $value = [Math]::Abs($hash)
    
    for ($i = 0; $i -lt 6; $i++) {
        $code += $chars[$value % $chars.Length]
        $value = [Math]::Floor($value / $chars.Length)
    }
    
    return $code
}

# Step 1: List all tenants
Write-Host "Step 1: Fetching all tenants..." -ForegroundColor Yellow
$headers = @{
    "X-Appwrite-Project" = $ProjectId
    "X-Appwrite-Key" = $ApiKey
    "Content-Type" = "application/json"
}

$listUrl = "$AppwriteEndpoint/databases/$DatabaseId/collections/$CollectionId/documents"
try {
    $response = Invoke-RestMethod -Uri $listUrl -Method Get -Headers $headers
    $tenants = $response.documents
    Write-Host "✅ Found $($tenants.Count) tenants" -ForegroundColor Green
} catch {
    Write-Host "❌ Error fetching tenants: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Update each tenant with generated code
Write-Host ""
Write-Host "Step 2: Generating and updating tenant codes..." -ForegroundColor Yellow
$successCount = 0
$skipCount = 0
$failCount = 0

foreach ($tenant in $tenants) {
    $tenantId = $tenant.'$id'
    $tenantName = $tenant.name
    $existingCode = $tenant.tenant_code
    
    # Skip if already has code
    if ($existingCode -and $existingCode.Trim() -ne "") {
        Write-Host "  ⏭️  $tenantName already has code: $existingCode" -ForegroundColor Gray
        $skipCount++
        continue
    }
    
    # Generate code
    $newCode = Get-TenantCode -TenantId $tenantId
    
    # Update tenant
    $updateUrl = "$AppwriteEndpoint/databases/$DatabaseId/collections/$CollectionId/documents/$tenantId"
    $body = @{
        tenant_code = $newCode
    } | ConvertTo-Json
    
    try {
        $updateResponse = Invoke-RestMethod -Uri $updateUrl -Method Patch -Headers $headers -Body $body
        Write-Host "  ✅ $tenantName → $newCode" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "  ❌ Failed to update $tenantName : $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    Start-Sleep -Milliseconds 200  # Rate limiting
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Migration Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tenants: $($tenants.Count)" -ForegroundColor White
Write-Host "Updated: $successCount" -ForegroundColor Green
Write-Host "Skipped (already has code): $skipCount" -ForegroundColor Yellow
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "✨ You can now scan QR codes for all tenants!" -ForegroundColor Green
}
