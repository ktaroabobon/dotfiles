---
name: create-issue
description: KURA-Family プロジェクトの GitHub Issue を起票する。課題・原因・解決策・作業ブランチ名を構造化して記載し、既存ラベルから適切なものを選んで付与する。gh CLI を使用。「Issue を起票」「Issue を作成」「バグを報告」「課題を起票」「issue にして」時に使用。
---

# GitHub Issue 作成

gh CLI で KURA-Family プロジェクトに構造化された Issue を起票する。

## Step 1: Issue 作成

### Issue 本文テンプレート

以下の 4 セクションを必ず含める：

```markdown
## 課題
何が起きているか。エラーメッセージやログがあれば含める。

## 原因
なぜこの問題が起きているか。技術的な根本原因の分析。

## 解決策
どう修正するか。具体的な方針を番号付きリストで記載。

## 作業ブランチ
`feature/xxx` or `fix/xxx`
```

必要に応じて `## 関連ファイル` セクションを追加する。

### ラベル付与

Read [references/labels.md](references/labels.md) to select appropriate labels.

**絶対に新しいラベルを作成しない。** 既存ラベルのみ使用する。

### gh コマンド

```bash
gh issue create \
  --title "簡潔なタイトル" \
  --label "bug,golang" \
  --body "$(cat <<'EOF'
## 課題
...

## 原因
...

## 解決策
...

## 作業ブランチ
`feature/xxx`
EOF
)"
```

- `--repo` は対象リポジトリが cwd と異なる場合のみ指定
- タイトルは日本語で簡潔に（70文字以内）

## Step 2: プロジェクトへの紐付け

Issue 作成後、CooT-Inc のプロジェクトボード（Project #1）に紐付ける。

```bash
# Issue をプロジェクトに追加（出力から item ID を取得）
gh project item-add 1 --owner CooT-Inc --url <ISSUE_URL> --format json
```

レスポンスの `id` フィールド（例: `PVTI_lADODN0xAs4A-gvH...`）を次のステップで使用する。

## Step 3: Estimate（ストーリーポイント）の設定

フィボナッチ数（1, 2, 3, 5, 8, 13）で見積もりを設定する。

### 基準

- **estimate: 3** = 基本的な CRUD API 1本の実装（例: [#167](https://github.com/CooT-Inc/KURA-Family-backend/issues/167) ユーザー詳細取得API）
- **estimate: 1** = 設定変更、ドキュメント修正、lint ルール変更など軽微なタスク
- **estimate: 2** = 単純なリファクタリング、バグ修正、テスト追加
- **estimate: 3** = 標準的な API 実装、単機能の追加
- **estimate: 5** = 複数コンポーネントにまたがる機能、複雑なビジネスロジック
- **estimate: 8** = 大規模な機能追加、アーキテクチャ変更
- **estimate: 13** = フェーズレベルの大型タスク

### gh コマンド

```bash
gh project item-edit \
  --project-id PVT_kwDODN0xAs4A-gvH \
  --id <ITEM_ID> \
  --field-id PVTF_lADODN0xAs4A-gvHzgx5IGQ \
  --number <ESTIMATE_VALUE>
```

- `--project-id`: `PVT_kwDODN0xAs4A-gvH`（CooT-Inc Project #1）
- `--field-id`: `PVTF_lADODN0xAs4A-gvHzgx5IGQ`（Estimate フィールド）
- `--number`: フィボナッチ数の見積もり値

## 完了

起票後に Issue URL をユーザーに返す。
