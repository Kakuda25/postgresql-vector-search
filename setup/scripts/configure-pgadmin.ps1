# pgAdmin 用 .pgpass を .env から生成します。
# 使い方: .\setup\scripts\configure-pgadmin.ps1

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $projectRoot ".env"
$pgpassFile = Join-Path $projectRoot "setup\pgadmin\.pgpass"

if (-not (Test-Path $envFile)) {
    Write-Error ".env not found. Copy env.template to .env first."
}

$vars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $vars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$user = if ($vars["POSTGRES_USER"]) { $vars["POSTGRES_USER"] } else { "postgres" }
$password = $vars["POSTGRES_PASSWORD"]
if (-not $password) {
    Write-Error "POSTGRES_PASSWORD is missing in .env"
}

if (Test-Path $pgpassFile) {
    Remove-Item -Recurse -Force $pgpassFile
}

$pgpassContent = "postgres:5432:*:${user}:${password}"
Set-Content -Path $pgpassFile -Value $pgpassContent -Encoding ascii -NoNewline

$pgadminPort = if ($vars["PGADMIN_PORT"]) { $vars["PGADMIN_PORT"] } else { "5050" }
$pgadminEmail = if ($vars["PGADMIN_EMAIL"]) { $vars["PGADMIN_EMAIL"] } else { "admin@example.com" }

Write-Host "Created setup/pgadmin/.pgpass"
Write-Host "pgAdmin: http://localhost:$pgadminPort"
Write-Host "Login: $pgadminEmail"
Write-Host "Server: vector-search (shopDB)"
