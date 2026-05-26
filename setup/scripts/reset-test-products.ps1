# 全商品削除 → テスト用商品投入
$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $root

if (Test-Path "$root\venv\Scripts\Activate.ps1") {
    & "$root\venv\Scripts\python.exe" "$root\app\scripts\reset-test-products.py"
} else {
    python "$root\app\scripts\reset-test-products.py"
}
