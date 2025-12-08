# GitHubアップロード手順

## 1. GitHubでリポジトリを作成

1. GitHubにログイン: https://github.com
2. 右上の「+」ボタン → 「New repository」をクリック
3. リポジトリ名を入力（例: `postgresql-vector-search`）
4. 説明を入力（オプション）
5. **Public** または **Private** を選択
6. **「Initialize this repository with a README」はチェックしない**（既にファイルがあるため）
7. 「Create repository」をクリック

## 2. リモートリポジトリを追加

GitHubでリポジトリを作成したら、表示されるURLを使用してリモートを追加します。

### HTTPSの場合:
```powershell
git remote add origin https://github.com/your-username/your-repository-name.git
```

### SSHの場合:
```powershell
git remote add origin git@github.com:your-username/your-repository-name.git
```

## 3. プッシュ

```powershell
git push -u origin main
```

初回プッシュ時、GitHubの認証情報を求められる場合があります。

## 4. 確認

GitHubのリポジトリページで、ファイルが正しくアップロードされているか確認してください。

## 注意事項

- `.env`ファイルは`.gitignore`で除外されているため、アップロードされません
- 機密情報（パスワードなど）が含まれるファイルは含まれていません
- `venv/`ディレクトリも除外されています

