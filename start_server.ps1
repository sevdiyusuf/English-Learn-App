# Simple script to start the web server
Write-Host "Starting web server..." -ForegroundColor Green
Write-Host ""

if (-not (Test-Path "build/web")) {
    Write-Host "Error: build/web directory not found!" -ForegroundColor Red
    Write-Host "Please run: flutter build web --release" -ForegroundColor Yellow
    exit 1
}

Write-Host "Server will be available at: http://localhost:8000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Change to build/web directory
Set-Location build/web

# Open browser
Start-Process "http://localhost:8000"

# Start server
python -m http.server 8000

