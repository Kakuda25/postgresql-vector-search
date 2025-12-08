# PowerShellスクリプト: 実行例
# 使用方法: .\scripts\run-example.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ベクトル生成と検索の実行例" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 仮想環境の有効化確認
if (-not $env:VIRTUAL_ENV) {
    Write-Host "`n仮想環境が有効化されていません。" -ForegroundColor Yellow
    Write-Host "仮想環境を有効化します..." -ForegroundColor Yellow
    & .\venv\Scripts\Activate.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "エラー: 仮想環境の有効化に失敗しました。" -ForegroundColor Red
        Write-Host "先に .\scripts\setup-venv.ps1 を実行してください。" -ForegroundColor Red
        exit 1
    }
}

# 環境変数の確認
if (-not $env:POSTGRES_PASSWORD) {
    Write-Host "`nPOSTGRES_PASSWORD環境変数が設定されていません。" -ForegroundColor Yellow
    Write-Host ".envファイルから読み込みますか？ (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y") {
        if (Test-Path ".env") {
            Get-Content .env | ForEach-Object {
                if ($_ -match "^POSTGRES_PASSWORD=(.+)$") {
                    $env:POSTGRES_PASSWORD = $matches[1]
                }
            }
            Write-Host "✓ .envファイルから環境変数を読み込みました" -ForegroundColor Green
        } else {
            Write-Host "エラー: .envファイルが見つかりません。" -ForegroundColor Red
            Write-Host "環境変数を手動で設定してください:" -ForegroundColor Yellow
            Write-Host '$env:POSTGRES_PASSWORD = "your_password"' -ForegroundColor Cyan
            exit 1
        }
    } else {
        Write-Host "環境変数を手動で設定してください:" -ForegroundColor Yellow
        Write-Host '$env:POSTGRES_PASSWORD = "your_password"' -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "実行メニュー" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. ベクトルを生成（全商品）" -ForegroundColor White
Write-Host "2. 類似商品を検索" -ForegroundColor White
Write-Host "3. 使用例を実行（e5-usage-example.py）" -ForegroundColor White
Write-Host "0. 終了" -ForegroundColor White
Write-Host ""

$choice = Read-Host "選択してください (0-3)"

switch ($choice) {
    "1" {
        Write-Host "`nベクトルを生成中..." -ForegroundColor Yellow
        python app/scripts/generate-embeddings.py
    }
    "2" {
        $query = Read-Host "`n検索クエリを入力してください"
        if ($query) {
            Write-Host "`n類似商品を検索中..." -ForegroundColor Yellow
            python app/scripts/search-similar-products.py $query
        } else {
            Write-Host "検索クエリが入力されませんでした。" -ForegroundColor Red
        }
    }
    "3" {
        Write-Host "`n使用例を実行中..." -ForegroundColor Yellow
        python setup/examples/e5-usage-example.py
    }
    "0" {
        Write-Host "終了します。" -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "無効な選択です。" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

