# projectFeatures.mdc を実装内容に合わせて更新する

実装の修正・追加が終わったあと、該当する機能仕様を @order/projectFeatures.mdc に反映するために実行する。

以下を実行してください。

1. **@order/ai-order.set-config.mdc** を開いて内容を読み込む（frontmatter を除く本文すべて）
2. そのオーダーに従い、**直近の実装（修正・追加・変更）に該当する** @order/projectFeatures.mdc の項目を最新の状態に更新する
3. projectFeatures.mdc が存在しない場合は、先に **@order/ai-order.init-config.mdc** を実行してから更新する
4. 技術スタックの詳細は @order/TechStack.mdc に委譲し、projectFeatures との重複を避ける

**運用**: 実装を終えたあと、機能仕様を残したい場合にユーザーまたは作業者がこのコマンドを実行する。
