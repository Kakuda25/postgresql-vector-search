# .cursor（このプロジェクト）

Cursor の **プロジェクト固有** 設定はここだけに置く。

| パス | 種別 | 内容 |
|------|------|------|
| `rules/` | ルール | 構成・作業フロー（`cursor-project-structure.mdc` 等） |
| `order/` | 知識・手順 | TechStack、projectFeatures、ai-order.* |
| `docs/` | 作業記録 | 調査メモ・セッション記録 |

## グローバル（全プロジェクト共通）

以下は **`~/.cursor/`** に配置し、このリポジトリには含めない。

| パス | 内容 |
|------|------|
| `~/.cursor/commands/` | スラッシュコマンド（read-order、run-order-* 等） |
| `~/.cursor/agents/` | サブエージェント |
| `~/.cursor/skills/` | スキル（css/html/jquery/php 等） |
| `~/.cursor/skills-cursor/` | Cursor 公式スキル |

コマンド・エージェントは、**ワークスペースルート** の `.cursor/order/` と `.cursor/docs/` を参照する。

## 修正後フロー

```
修正完了 → /run-order-postfix
            ├─ check（order/ai-order.index.mdc）
            └─ 仕様影響あり → set（order/ai-order.set.mdc）
```
