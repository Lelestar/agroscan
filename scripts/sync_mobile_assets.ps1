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

$Keras = $env:KERAS_MODEL
if (-not $Keras) {
    $Jalon4 = Join-Path $SrcModels "jalon4_original_segmented_plantdoc_ft.keras"
    $Plantwild = Join-Path $SrcModels "agroscan_plantwild.keras"
    $Baseline = Join-Path $SrcModels "agroscan_baseline.keras"
    if (Test-Path $Jalon4) { $Keras = $Jalon4 }
    elseif (Test-Path $Plantwild) { $Keras = $Plantwild }
    elseif (Test-Path $Baseline) { $Keras = $Baseline }
    else {
        Write-Error "Missing Keras model. Train jalon4 (jalon4_original_segmented_plantdoc_ft.keras), jalon3, or baseline."
        exit 1
    }
}
if (-not (Test-Path $Keras)) {
    Write-Error "Missing $Keras"
    exit 1
}
Write-Host "Using Keras model: $Keras"

Write-Host "Exporting TFLite (predictions + conv features for Grad-CAM)..."
& $Python (Join-Path $Root "scripts\export_mobile_explain_tflite.py") --keras $Keras
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
