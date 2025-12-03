# Deploy Flutter Web App to Firebase Hosting
# Bu script uygulamayı Firebase'e deploy eder ve herkesin erişebileceği kalıcı bir URL oluşturur

# Set execution policy for this session (if needed)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase Hosting Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Build kontrolü
Write-Host "Step 1: Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release --no-source-maps

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# Fix iOS Safari renderer issue
Write-Host "Step 1.5: Fixing iOS Safari renderer compatibility..." -ForegroundColor Yellow
& "$PSScriptRoot\fix_ios_safari_renderer.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: iOS Safari renderer fix failed, but continuing..." -ForegroundColor Yellow
}

Write-Host ""

# Firebase CLI kontrolü
$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    Write-Host "Firebase CLI is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installation:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor White
    Write-Host ""
    Write-Host "Then login:" -ForegroundColor Yellow
    Write-Host "  firebase login" -ForegroundColor White
    exit 1
}

Write-Host "Step 2: Deploying to Firebase Hosting..." -ForegroundColor Yellow
Write-Host ""

# Firebase'e deploy et
firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your app is now live at:" -ForegroundColor Yellow
Write-Host "(Check the URL above or Firebase Console)" -ForegroundColor White
Write-Host ""
Write-Host "To view your hosting URLs, run:" -ForegroundColor Yellow
Write-Host "  firebase hosting:channel:list" -ForegroundColor White
Write-Host ""

