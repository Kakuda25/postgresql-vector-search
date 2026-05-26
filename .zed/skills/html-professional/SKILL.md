---
name: html-professional
description: Applies professional HTML5 standards for writing, reviewing, and refactoring markup. Use when working with .html/.htm files, HTML fragments, or when the user asks for HTML best practices, semantics, accessibility, validity, or security guidance.
---

# HTML プロフェッショナル

HTML5 の仕様とプロ品質を満たすための指針。マークアップの作成・レビュー・リファクタ時に適用する。

## 基本方針

- **セマンティクス優先**: 意味に合う要素を選ぶ。見た目目的の div/span の乱用を避け、`header` / `nav` / `main` / `section` / `article` / `aside` / `footer` 等を適切に使う。
- **アクセシビリティ**: ネイティブな HTML の意味と挙動を活かす。ARIA はネイティブで表現できない場合に補足する。
- **妥当なマークアップ**: 文書型・文字コードを明示し、要素の入れ子ルールに従う（例: インライン要素内にブロックを入れない）。

## 文書の骨組み

- 先頭に `<!DOCTYPE html>` を書く。
- `<html>` に `lang` を指定する（例: `lang="ja"`）。部分的な言語切り替えには該当要素に `lang` を付ける。
- `<head>` 内で文字コードを最初に宣言する: `<meta charset="UTF-8">`。
- ビューポートはレスポンシブ前提で `<meta name="viewport" content="width=device-width, initial-scale=1">` を入れる。
- タイトルは `<title>` で1つだけ、内容が分かる文言にする。

## セマンティックな構造

- メインコンテンツは `<main>` で囲む。ページに1つ。`header` / `footer` / `nav` は含めない。
- ナビゲーション領域は `<nav>` を使う。複数ある場合は `aria-label` で区別する（例: `aria-label="メインメニュー"`）。
- 独立したコンテンツのまとまりは `<article>`、テーマ別の区切りは `<section>` を使う。`<section>` には見出し（`h1`–`h6`）を付ける。
- 補足・サイドは `<aside>`、ページ末尾の情報は `<footer>` にまとめる。
- 見出し階層は飛ばさない（`h1` の次に `h4` にしない）。アウトラインが論理的に通るようにする。

## フォーム

- 入力欄には必ず `<label>` を対応させる。`for` と `id` を一致させるか、ラベルでコントロールを囲む。
- 関連する項目は `<fieldset>` でまとめ、`<legend>` でグループ名を付ける。
- 必須項目は `required`、入力形式は `type`（`email`, `url`, `tel`, `number` 等）や `pattern` で指定する。
- オートコンプリートが望ましい場合は `autocomplete` を適切に指定する（例: `name`, `email`）。
- エラー表示は、コントロールと紐づくように `aria-describedby` や `aria-invalid` を活用する。

## メディアとリンク

- `<img>` には必ず `alt` を付ける。装飾画像は `alt=""` にする。内容を簡潔に説明する。
- `<video>` / `<audio>` では字幕・音声解説が必要な場合に `track` を用意する。
- リンクは `<a href="...">` を使う。JavaScript のみの操作は `button` を使い、必要なら `role="button"` とキーボード対応を追加する。
- 新しいタブで開くリンクには `target="_blank"` と合わせて `rel="noopener"`（必要なら `rel="noreferrer"`）を付ける。

## セキュリティと挙動

- 信頼できない入力は HTML にそのまま挿入しない。出力時にエスケープする（属性値・要素内容の区別を踏まえる）。
- インラインイベント（`onclick` 等）は避け、可能なら外部スクリプトでバインドする。ユーザー入力をインラインに含めない。
- 必要に応じて CSP を設定する（`Content-Security-Policy` の meta または HTTP ヘッダ）。

## パフォーマンスと読み込み

- スクリプトは必要なら `defer` または `async` を付ける。レンダリングをブロックしない配置と順序を考慮する。
- 重要なリソースは `<link rel="preload">` で先行読み込みを検討する。
- アイコンやファビコンは `rel="icon"` 等で適切な形式・サイズを指定する。

## ARIA の使い方

- まずネイティブ HTML で意味と操作を表現する。足りない場合だけ ARIA を補う。
- カスタムウィジェットでは `role`、`aria-label` / `aria-labelledby`、`aria-describedby`、状態に応じた `aria-expanded` / `aria-selected` / `aria-checked` 等を正しく付ける。
- ネイティブの意味を上書きするときだけ `role` を変更する。冗長な ARIA（例: ボタンに `role="button"`）は付けない。

## 禁止・非推奨

- 見た目目的の `<b>` / `<i>` は `<strong>` / `<em>` が意味的に適切ならそちらを優先する。純粋にスタイルだけの場合は CSS で制御する。
- 非推奨要素（`<font>`, `<center>`, `<frame>` 等）は使わない。
- テーブルは表データ用に `<table>` を使い、レイアウト目的では使わない。表には `<th>` と `scope` で見出しを明示する。
- 空の `alt` を省略しない。装飾画像は `alt=""` と明示する。

## レビュー時のチェック

- [ ] `DOCTYPE`、`charset`、`lang`、`viewport` が適切か
- [ ] セマンティックな要素で構造が表現されているか
- [ ] 見出し階層が飛んでいないか
- [ ] フォームに `label` / `fieldset` / `legend` が付いているか
- [ ] 画像に `alt` が付いているか（装飾は `alt=""`）
- [ ] 外部リンクに `rel="noopener"` が付いているか
- [ ] ユーザー入力をエスケープせずに出力していないか
- [ ] インラインイベントに信頼できないデータを渡していないか
