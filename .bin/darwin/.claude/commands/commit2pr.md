---
allowed-tools: Bash, Read, Write
description: すべての変更を commit し、remote に push した後、PR を作成する
---

## Context

- 現在のブランチの変更をすべて commit して push
- PR が存在しない場合のみ新規作成

## Your task

### 1. commit & push

`/commit2push` の手順に従って、すべての変更を commit → push してください。

### 2. PR の存在確認と作成

GitHub CLI を使用して以下を実行：

1. **PR 存在確認**
   ```bash
   gh pr list --head [現在のブランチ名] --json number
   ```

2. **PR が存在しない場合のみ作成**
   - PRテンプレートを以下の優先順位で検索し、見つかったものを使用:
     1. `.github/pull_request_template.md`
     2. `.github/PULL_REQUEST_TEMPLATE/pull_request_template.md`
     3. `docs/pull_request_template.md`
   - テンプレートに従って PR の body を作成
   - **日本語で作成すること**
   - **Claude に関する記述を含めないこと**
   - PR タイトルは現在のブランチ名から推測するか、commit メッセージから生成

   ```bash
   gh pr create --title "[PR タイトル]" --body "[テンプレートに従った内容]"
   ```

3. **PR が既に存在する場合**
   - "PR は既に存在します" というメッセージを表示
   - PR の URL を表示

### 3. 完了メッセージ

- commit した内容のサマリー
- push の成功
- PR の作成結果（新規作成 or 既存）
- PR の URL

## 注意事項

- すべての操作で日本語メッセージを使用
- エラーが発生した場合は適切なエラーメッセージを日本語で表示
- GitHub CLI が利用可能であることを前提とする（未インストールの場合はインストール指示を表示）
