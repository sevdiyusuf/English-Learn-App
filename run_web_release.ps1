# Flutter Web Release Mode Script
# This runs the app in release mode for better performance
Write-Host "Building Flutter Web in release mode..." -ForegroundColor Green
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful! Starting local web server..." -ForegroundColor Green
Write-Host ""
Write-Host "Server will be available at:" -ForegroundColor Cyan
Write-Host "  http://localhost:8000" -ForegroundColor White
Write-Host "  http://127.0.0.1:8000" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

cd build/web

# Try python3 first, then python
$pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
}

if ($pythonCmd) {
    # Open browser automatically
    Start-Process "http://localhost:8000"
    
    # Start the server
    python -m http.server 8000
} else {
    Write-Host "Python not found. Please install Python or use another web server." -ForegroundColor Red
    Write-Host "Alternative: npx serve -s build/web" -ForegroundColor Yellow
    exit 1
}

