# .envファイルから環境変数を読み込むヘルパースクリプト
# 使用方法: . .\scripts\load-env.ps1

if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            if ($key -and $value) {
                Set-Item -Path "env:$key" -Value $value
            }
        }
    }
    Write-Host "環境変数を.envファイルから読み込みました" -ForegroundColor Green
} else {
    Write-Host "警告: .envファイルが見つかりません" -ForegroundColor Yellow
}

