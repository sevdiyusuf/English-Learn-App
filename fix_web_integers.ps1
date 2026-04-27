# Script to fix JavaScript integer overflow in Isar-generated files for web builds
# Run this after build_runner if you need to build for web

$files = @(
    "lib\features\word_match\models\word_pair.g.dart",
    "lib\features\word_match\models\word_set.g.dart",
    "lib\features\dictionary\models\dict_entry.g.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Fixing integers in $file..." -ForegroundColor Yellow
        $content = Get-Content $file -Raw
        
        # Replace large integer literals with web-safe values (within JavaScript's safe integer range)
        # JavaScript safe integer range: -2^53 to 2^53-1 (approximately -9007199254740991 to 9007199254740991)
        # We'll use a smaller safe value like 0 or 1 for web builds
        $content = $content -replace 'id: -?\d{16,}', 'id: 0'
        
        Set-Content $file -Value $content -NoNewline
        Write-Host "Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nDone! You can now build for web." -ForegroundColor Green
