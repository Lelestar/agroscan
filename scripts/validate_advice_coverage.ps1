# Check that every disease class has an advice sheet (Windows).
# Linux/macOS: ./scripts/validate_advice_coverage.sh
# All platforms: cd mobile && dart run tool/validate_advice_coverage.dart
$ErrorActionPreference = "Stop"

$Mobile = (Resolve-Path (Join-Path $PSScriptRoot "..\mobile")).Path
Push-Location $Mobile
try {
    dart run tool/validate_advice_coverage.dart
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
