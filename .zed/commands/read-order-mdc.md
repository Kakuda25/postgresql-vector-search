# @order の mdc を読んで適用する

以下を実行してください。

1. **ユーザーが指定した** `@order` 内の .mdc ファイルを読み込む
   - 例: `Project.mdc`, `TechStack.mdc`, `projectFeatures.mdc`, `ai-order.init.mdc`, `ai-order.check.mdc` など
   - ユーザーが「/read-order-mdc」の後にファイル名を書いていない場合は、**`@order/Project.mdc`** を読む
2. 読み込んだファイルの**本文**（frontmatter の `---` で囲まれた部分は除く）を、今回の会話の前提として適用する
3. 以降の回答・修正は、その mdc に書かれたルールや手順に従う

指定例:
- `/read-order-mdc` → Project.mdc を読む
- `/read-order-mdc TechStack.mdc` → TechStack.mdc を読む
- `/read-order-mdc projectFeatures.mdc` → projectFeatures.mdc を読む
