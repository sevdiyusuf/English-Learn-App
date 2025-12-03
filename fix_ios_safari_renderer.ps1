# Fix iOS Safari renderer issue by modifying flutter_bootstrap.js after build
# This script modifies flutter_bootstrap.js to use HTML renderer for iOS Safari
# The main.dart.js file works with both CanvasKit and HTML renderer,
# so we just need to change the build config to use HTML renderer for iOS Safari

$flutterBootstrapPath = "build\web\flutter_bootstrap.js"

if (-not (Test-Path $flutterBootstrapPath)) {
    Write-Host "flutter_bootstrap.js not found at $flutterBootstrapPath" -ForegroundColor Red
    exit 1
}

Write-Host "Fixing iOS Safari renderer in flutter_bootstrap.js..." -ForegroundColor Yellow

# Read the file
$content = Get-Content $flutterBootstrapPath -Raw -Encoding UTF8

# Check if the fix is already applied
if ($content -match "Using HTML renderer for iOS Safari compatibility") {
    Write-Host "Fix already applied to flutter_bootstrap.js" -ForegroundColor Green
    exit 0
}

# Extract engine revision from existing build config
$engineRevision = "f73bfc4522dd0bc87bbcdb4bb3088082755c5e87"
if ($content -match '"engineRevision":"([^"]+)"') {
    $engineRevision = $matches[1]
    Write-Host "Found engine revision: $engineRevision" -ForegroundColor Cyan
}

# Find the buildConfig assignment and replace it
# Pattern: _flutter.buildConfig = {"engineRevision":"...","builds":[...]};
# We need to replace it with a function that checks for iOS Safari

$oldPattern = '_flutter\.buildConfig\s*=\s*\{[^}]+\};'

$newCode = @"
// Override build config to include HTML renderer for iOS Safari compatibility
// iOS Safari doesn't support WebAssembly.compileStreaming required by CanvasKit
// The main.dart.js file works with both renderers, so we can switch at runtime
(function() {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
                (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const hasWebAssemblyStreaming = typeof WebAssembly !== 'undefined' && 
                                  typeof WebAssembly.compileStreaming !== 'undefined';
  
  if (isIOS || !hasWebAssemblyStreaming) {
    // Use HTML renderer for iOS Safari or if WebAssembly.compileStreaming is not available
    _flutter.buildConfig = {
      "engineRevision": "$engineRevision",
      "builds": [
        {"compileTarget": "dart2js", "renderer": "html", "mainJsPath": "main.dart.js"}
      ]
    };
    console.log('Using HTML renderer for iOS Safari compatibility');
  } else {
    // Use CanvasKit for other browsers
    _flutter.buildConfig = {
      "engineRevision": "$engineRevision",
      "builds": [
        {"compileTarget": "dart2js", "renderer": "canvaskit", "mainJsPath": "main.dart.js"}
      ]
    };
  }
})();
"@

# Try to replace the pattern
if ($content -match $oldPattern) {
    $content = $content -replace $oldPattern, $newCode
    # Save with UTF-8 encoding without BOM
    [System.IO.File]::WriteAllText((Resolve-Path $flutterBootstrapPath).Path, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Successfully modified flutter_bootstrap.js for iOS Safari compatibility" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Warning: Could not find buildConfig pattern in flutter_bootstrap.js" -ForegroundColor Yellow
    Write-Host "Attempting alternative fix method..." -ForegroundColor Yellow
    
    # Alternative: Append the fix before _flutter.loader.load
    if ($content -match '(_flutter\.loader\.load\()') {
        $beforeLoader = $content.Substring(0, $content.IndexOf('_flutter.loader.load('))
        $afterLoader = $content.Substring($content.IndexOf('_flutter.loader.load('))
        
        # Check if buildConfig is set
        if ($beforeLoader -notmatch '_flutter\.buildConfig\s*=') {
            # BuildConfig is not set, add it before loader.load
            $fixCode = @"

// Fix for iOS Safari: Set buildConfig with HTML renderer support
if (!_flutter.buildConfig) {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
                (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const hasWebAssemblyStreaming = typeof WebAssembly !== 'undefined' && 
                                  typeof WebAssembly.compileStreaming !== 'undefined';
  
  _flutter.buildConfig = {
    "engineRevision": "$engineRevision",
    "builds": [
      {"compileTarget": "dart2js", "renderer": (isIOS || !hasWebAssemblyStreaming ? "html" : "canvaskit"), "mainJsPath": "main.dart.js"}
    ]
  };
  if (isIOS || !hasWebAssemblyStreaming) {
    console.log('Using HTML renderer for iOS Safari compatibility');
  }
}

"@
            $content = $beforeLoader + $fixCode + $afterLoader
            [System.IO.File]::WriteAllText((Resolve-Path $flutterBootstrapPath).Path, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "Successfully added iOS Safari fix to flutter_bootstrap.js" -ForegroundColor Green
            exit 0
        }
    }
    
    Write-Host "Could not apply fix automatically. Manual intervention required." -ForegroundColor Red
    exit 1
}

