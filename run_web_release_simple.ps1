# Simple script to run the web server if build is already done
Write-Host "Starting web server on http://localhost:8000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path "build/web")) {
    Write-Host "Error: build/web directory not found!" -ForegroundColor Red
    Write-Host "Please run: flutter build web --release" -ForegroundColor Yellow
    exit 1
}

cd build/web

# Open browser
Start-Process "http://localhost:8000"

# Start server
python -m http.server 8000

