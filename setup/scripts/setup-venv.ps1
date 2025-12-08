# PowerShell Script: Virtual Environment Setup
# Usage: .\setup\scripts\setup-venv.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtual Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check Python version
Write-Host "`n[1/6] Checking Python version..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "OK: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Python is not installed." -ForegroundColor Red
    Write-Host "Please install Python 3.8 or higher: https://www.python.org/downloads/" -ForegroundColor Red
    exit 1
}

# 2. Create virtual environment
Write-Host "`n[2/6] Creating virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "Virtual environment 'venv' already exists. Remove and recreate? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y") {
        Remove-Item -Recurse -Force venv
        python -m venv venv
        Write-Host "OK: Virtual environment recreated" -ForegroundColor Green
    } else {
        Write-Host "Using existing virtual environment" -ForegroundColor Green
    }
} else {
    python -m venv venv
    Write-Host "OK: Virtual environment created" -ForegroundColor Green
}

# 3. Activate virtual environment
Write-Host "`n[3/6] Activating virtual environment..." -ForegroundColor Yellow
try {
    & .\venv\Scripts\Activate.ps1
    Write-Host "OK: Virtual environment activated" -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to activate virtual environment." -ForegroundColor Red
    Write-Host "You may need to change execution policy:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# 4. Upgrade pip
Write-Host "`n[4/6] Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip --quiet
Write-Host "OK: pip upgraded" -ForegroundColor Green

# 5. Install required libraries
Write-Host "`n[5/6] Installing required libraries..." -ForegroundColor Yellow
Write-Host "(This may take some time)" -ForegroundColor Gray
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install libraries." -ForegroundColor Red
    exit 1
}
Write-Host "OK: Libraries installed" -ForegroundColor Green

# 6. Check environment variables
Write-Host "`n[6/6] Checking environment variables..." -ForegroundColor Yellow
if (-not $env:POSTGRES_PASSWORD) {
    Write-Host "Warning: POSTGRES_PASSWORD environment variable is not set" -ForegroundColor Yellow
    Write-Host "Set it with:" -ForegroundColor Yellow
    Write-Host '$env:POSTGRES_PASSWORD = "your_password"' -ForegroundColor Cyan
    Write-Host "`nOr load from .env file:" -ForegroundColor Yellow
    Write-Host 'Get-Content .env | ForEach-Object { if ($_ -match "^POSTGRES_PASSWORD=(.+)$") { $env:POSTGRES_PASSWORD = $matches[1] } }' -ForegroundColor Cyan
} else {
    Write-Host "OK: POSTGRES_PASSWORD is set" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Set environment variable:" -ForegroundColor White
Write-Host '   $env:POSTGRES_PASSWORD = "your_password"' -ForegroundColor Cyan
Write-Host "`n2. Generate embeddings:" -ForegroundColor White
Write-Host '   python scripts/generate-embeddings.py --sentence-transformers --sentence-model intfloat/multilingual-e5-large' -ForegroundColor Cyan
Write-Host "`n3. Search similar products:" -ForegroundColor White
Write-Host '   python scripts/search-similar-products.py "handpiece"' -ForegroundColor Cyan
Write-Host "`nTo deactivate virtual environment: deactivate" -ForegroundColor Gray
