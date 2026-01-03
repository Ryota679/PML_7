# Auto-cleanup script for wrapping all print() with kDebugMode
# This script will:
# 1. Add import 'package:flutter/foundation.dart' if not exists
# 2. Wrap all standalone print() with if (kDebugMode) {}

$files = @(
    "lib\features\business_owner\services\tenant_swap_service.dart",
    "lib\features\tenant\providers\upgrade_token_provider.dart",
    "lib\features\tenant\presentation\pages\tenant_upgrade_payment_page.dart",
    "lib\features\business_owner\services\grace_period_service.dart",
    "lib\features\business_owner\services\tenant_stats_service.dart",
    "lib\features\business_owner\presentation\widgets\assign_user_dialog.dart",
    "lib\features\tenant\presentation\pages\product_management_page.dart",
    "lib\features\auth\presentation\login_page.dart",
    "lib\shared\models\order_model.dart"
)

foreach ($file in $files) {
    $filePath = "c:\kantin_app\$file"
    if (Test-Path $filePath) {
        Write-Host "Processing: $file" -ForegroundColor Cyan
        
        $content = Get-Content $filePath -Raw
        
        # Add import if not exists
        if (-not ($content -match "import 'package:flutter/foundation\.dart'")) {
            $content = $content -replace "(^import.*?;)", "`$1`nimport 'package:flutter/foundation.dart';"
            Write-Host "  Added kDebugMode import" -ForegroundColor Green
        }
        
        # Wrap print statements (simple approach - may need manual review)
        # This wraps single-line prints
        $content = $content -replace "(\s+)(print\(.+?\);)", "`$1if (kDebugMode) `$2"
        
        Set-Content $filePath $content -NoNewline
        Write-Host "  Wrapped print statements" -ForegroundColor Green
    }
}

Write-Host "`nCleanup complete!" -ForegroundColor Green
Write-Host "Please review files manually for multi-line prints" -ForegroundColor Yellow
