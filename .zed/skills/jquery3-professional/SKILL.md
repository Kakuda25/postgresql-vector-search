---
name: jquery3-professional
description: Applies professional jQuery 3.x standards for writing, reviewing, and refactoring code. Use when working with jQuery, .js files that use $ or jQuery, or when the user asks for jQuery best practices, event handling, AJAX, or DOM manipulation guidance.
---

# jQuery 3.x プロフェッショナル

jQuery 3.x の API とプロ品質を満たすための指針。コードの作成・レビュー・リファクタ時に適用する。

## 基本方針

- **統一 API**: イベントは `.on()` / `.off()` に統一する。`.bind()` / `.live()` / `.delegate()` は使わない。
- **イベント委譲**: 動的追加要素には委譲（`.on(events, selector, handler)`）を使う。委譲先は `document` より近い共通の祖先にバインドする。
- **読みやすさ**: セレクタはキャッシュし、意図が分かる命名にする。過剰なチェーンは避ける。

## セレクタとキャッシュ

- 同じセレクタを繰り返す場合は変数にキャッシュする。DOM 走査の削減と可読性のため。
- ID セレクタは単一要素のため `#id` で十分。`#id .child` のように必要以上に複雑にしない。
- セレクタは可能な限り具体的にし、不要なユニバーサルセレクタ（`*`）は使わない。

```javascript
var $container = $('#container');
$container.on('click', '.btn-action', handler);
$container.find('.item').addClass('active');
```

## イベント

- 登録は `.on(events [, selector] [, data], handler)` を使う。動的要素には第二引数に `selector` を渡して委譲する。
- 委譲は「存在が保証されている最も近い祖先」にバインドする。`$(document).on(...)` は他に適切な祖先がない場合のみ。
- 名前空間（例: `click.myPlugin`）を使うと `.off('click.myPlugin')` で対象だけ解除でき、他に影響しない。
- 削除・差し替え前に `.off()` で解除する。メモリリークと二重発火を防ぐ。
- `.click()` / `.focus()` 等のショートカットは可読性のため使ってよいが、動的要素には `.on('click', selector, fn)` の委譲を優先する。

## DOM 操作とセキュリティ

- **ユーザー入力をそのまま DOM に反映する場合は `.text()` を使う。** `.html()` に未サニタイズの文字列を渡さない（XSS の原因）。
- 信頼できるソースの HTML を挿入する場合のみ `.html()` を使い、必要ならサニタイズしてから渡す。
- 複数要素の挿入・削除はまとめて行う。ループ内で都度 DOM 操作しない。`.detach()` で一旦外して加工してから再挿入するパターンを検討する。
- 属性は状態・論理値に `.prop()`、HTML 属性に `.attr()` を使い分ける（例: `checked`, `disabled` は `.prop()`）。

## AJAX

- `$.ajax()` のオプションで `dataType` を明示する。jQuery 3 では script の自動実行等に仕様変更があるため、期待する型を指定する。
- 成功・失敗は `.done()` / `.fail()` / `.always()` または Promise として `.then()` で扱う。jQuery 3 の Deferred は Promise/A+ 互換。
- ユーザー入力やパラメータをそのまま URL や `data` に載せない。エンコード・検証してから渡す。
- 必要に応じて `context` で `this` を固定する。コールバック内で `this` を前提にする場合は明示する。

```javascript
$.ajax({
  url: '/api/items',
  dataType: 'json',
  method: 'GET'
})
  .done(function (data) { /* ... */ })
  .fail(function (jqXHR, textStatus, errorThrown) { /* ... */ });
```

## 非推奨・削除された API

- `.load()` / `.unload()` / `.error()` は削除済み。`.on('load', ...)` / `.on('unload', ...)` / `.on('error', ...)` に置き換える。
- `.size()` は使わず `.length` を使う。
- `.andSelf()` は `.addBack()` に置き換える。
- レガシーなカスタム擬似セレクタ（`:even`, `:odd` 等以外の非標準）は 3.x で削除されているため使わない。
- CSS の単位なし数値に自動で `px` が付かなくなった箇所がある。必要な場合は明示的に `'10px'` のように単位を付ける。

## パフォーマンス

- ループ内ではセレクタをキャッシュし、DOM の取得・変更を最小限にする。
- 表示切替は `.show()` / `.hide()` / `.toggle()` の他、`.addClass()` / `.removeClass()` で CSS に任せる方法も検討する。アニメーションは必要時のみ。
- 大量要素のフィルタは `.filter()` やネイティブの `Array.prototype` で配列として処理してから DOM を更新する選択肢を検討する。

## 他ライブラリ・Vanilla JS との共存

- `$` のコンフリクトを避けるため、必要なら `jQuery.noConflict()` を使い、スコープ内で `jQuery` を変数に代入して使う。
- 単純な取得・クラス切替などは Vanilla JS（`querySelector`, `classList`）で十分な場合は、プロジェクト方針に合わせて統一する。jQuery に依存する既存コードの修正・拡張では jQuery 3.x のルールに従う。

## レビュー時のチェック

- [ ] イベントは `.on()` / `.off()` で統一されているか
- [ ] 動的要素に委譲を使っているか、委譲先は適切な祖先か
- [ ] ユーザー入力を `.html()` に渡していないか（XSS）
- [ ] 同じセレクタの繰り返しをキャッシュしているか
- [ ] AJAX で `dataType` を明示しているか
- [ ] 削除された API（`.load()`, `.error()`, `.size()` 等）を使っていないか
- [ ] 不要なイベントを `.off()` で解除しているか
