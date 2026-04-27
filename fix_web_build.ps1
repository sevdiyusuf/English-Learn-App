# Fix JavaScript integer overflow in Isar-generated files for web builds
# Run this script before building for web: .\fix_web_build.ps1

Write-Host "Fixing Isar-generated files for web compatibility..." -ForegroundColor Cyan

$files = @(
    "lib\features\word_match\models\word_pair.g.dart",
    "lib\features\word_match\models\word_set.g.dart",
    "lib\features\dictionary\models\dict_entry.g.dart"
)

$fixed = 0
foreach ($file in $files) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        $content = Get-Content $fullPath -Raw -Encoding UTF8

        # Replace large integer literals (16+ digits) that can't be represented in JavaScript
        # JavaScript safe integer range: -9007199254740991 to 9007199254740991
        # Replace with 0 (safe value that won't break compilation)
        $originalContent = $content
        $content = $content -replace 'id: (-?\d{16,})', 'id: 0'

        if ($content -ne $originalContent) {
            Set-Content $fullPath -Value $content -NoNewline -Encoding UTF8
            Write-Host "  - Fixed integers in $file" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "  - No changes needed in $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ! File not found: $file (will be generated on next build_runner)" -ForegroundColor Yellow
    }
}

if ($fixed -gt 0) {
    Write-Host "`n- Fixed $fixed file(s). You can now build for web." -ForegroundColor Green
} else {
    Write-Host "`n- All files are already web-compatible or do not exist yet." -ForegroundColor Green
}

Write-Host "`nTo build for web, run: flutter build web --release" -ForegroundColor Cyan
