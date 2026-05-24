# Copy trained model artifacts into the Flutter app bundle (Windows).
# Linux/macOS: use ./scripts/sync_mobile_assets.sh
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SrcModels = Join-Path $Root "models"
$Dest = Join-Path $Root "mobile\assets\models"
$Python = Join-Path $Root ".venv\Scripts\python.exe"

if (-not (Test-Path $Python)) {
    $Python = "python"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$Keras = Join-Path $SrcModels "agroscan_baseline.keras"
if (-not (Test-Path $Keras)) {
    Write-Error "Missing $Keras — train the model first."
    exit 1
}

Write-Host "Exporting TFLite (predictions + conv features for Grad-CAM)..."
& $Python (Join-Path $Root "scripts\export_mobile_explain_tflite.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Required = @(
    "agroscan_baseline_float.tflite",
    "gradcam_classifier_weights.bin",
    "gradcam_classifier_weights.json",
    "labels.json"
)

foreach ($file in $Required) {
    $path = Join-Path $Dest $file
    if (-not (Test-Path $path)) {
        Write-Error "Missing $path after export."
        exit 1
    }
    Write-Host "Ready $path"
}

Write-Host "Mobile assets ready in $Dest"
