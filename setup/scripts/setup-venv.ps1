# PowerShell Script: Virtual Environment Setup
# Usage: .\setup\scripts\setup-venv.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtual Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check Python version
Write-Host "`n[1/6] Checking Python version..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0 -or "$pythonVersion" -notmatch "Python\s+3\.") {
        Write-Host "Error: Valid Python 3 was not found." -ForegroundColor Red
        Write-Host "The current 'python' command appears to be the Windows app alias, not a real Python installation." -ForegroundColor Yellow
        Write-Host "Install Python 3.10+ from https://www.python.org/downloads/ and enable 'Add python.exe to PATH'." -ForegroundColor Yellow
        exit 1
    }
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
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to create virtual environment." -ForegroundColor Red
        exit 1
    }
    Write-Host "OK: Virtual environment created" -ForegroundColor Green
}

# 3. Check virtual environment commands
Write-Host "`n[3/6] Checking virtual environment commands..." -ForegroundColor Yellow
$venvPython = ".\venv\Scripts\python.exe"
$venvPip = ".\venv\Scripts\pip.exe"
if (-not (Test-Path $venvPython) -or -not (Test-Path $venvPip)) {
    Write-Host "Error: Virtual environment commands were not found." -ForegroundColor Red
    exit 1
}
Write-Host "OK: Virtual environment commands found" -ForegroundColor Green

# 4. Upgrade pip
Write-Host "`n[4/6] Upgrading pip..." -ForegroundColor Yellow
& $venvPython -m pip install --upgrade pip --quiet
Write-Host "OK: pip upgraded" -ForegroundColor Green

# 5. Install required libraries
Write-Host "`n[5/6] Installing required libraries..." -ForegroundColor Yellow
Write-Host "(This may take some time)" -ForegroundColor Gray
& $venvPip install -r requirements.txt
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
Write-Host "1. Activate virtual environment:" -ForegroundColor White
Write-Host '   .\venv\Scripts\Activate.ps1' -ForegroundColor Cyan
Write-Host "`n2. Load environment variables:" -ForegroundColor White
Write-Host '   . .\setup\scripts\load-env.ps1' -ForegroundColor Cyan
Write-Host "`n3. Generate embeddings:" -ForegroundColor White
Write-Host '   python app\scripts\generate-embeddings.py' -ForegroundColor Cyan
Write-Host "`n4. Search similar products:" -ForegroundColor White
Write-Host '   python app\scripts\search-similar-products.py "handpiece"' -ForegroundColor Cyan
Write-Host "`nTo deactivate virtual environment: deactivate" -ForegroundColor Gray
