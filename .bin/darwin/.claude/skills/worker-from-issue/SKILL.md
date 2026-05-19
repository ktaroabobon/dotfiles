---
name: worker-from-issue
description: GitHub Issue から作業ブランチを決定し、ブランチ別Dockerコンテナを自動起動する。Issue 番号を受け取り、Issue本文/コメントからブランチ名を抽出（または Issue タイトルから生成）し、ブランチ作成後にコンテナを起動、Issue にブランチ情報を記録する。「Issue から作業開始」「Issue #123 のコンテナを起動」「この Issue で開発したい」などの要求で使用。
---

# Worker from Issue

GitHub Issue から作業ブランチを決定し、ブランチ別Docker開発環境を自動的にセットアップする。

## 前提条件

- GitHub CLI (`gh`) がインストールされ認証済み
- Git リポジトリ内で実行
- `worker.sh` と `make worker/*` コマンドが利用可能
- PostgreSQL コンテナが起動済み (`make up`)

## ワークフロー

### 1. Issue 情報の取得

Issue 番号またはURLから Issue 情報を取得:

```bash
# Issue 番号のみの場合
gh issue view <issue_number> --json title,body,comments

# Issue URL の場合
gh issue view <issue_url> --json title,body,comments
```

### 2. ブランチ名の決定

以下の優先順位でブランチ名を決定:

**優先度1: Issue 本文から抽出**

Issue 本文から以下のパターンでブランチ名を検索:
- `ブランチ: feature/xxx`
- `branch: feature/xxx`
- `Branch: feature/xxx`
- バッククォートで囲まれたブランチ名: `` `feature/xxx` ``

正規表現例:
```python
import re

# Issue 本文とコメントを結合
full_text = issue_body + "\n".join([c["body"] for c in comments])

# ブランチ名パターンを検索
patterns = [
    r'[Bb]ranch:\s*`?([a-zA-Z0-9/_-]+)`?',
    r'ブランチ:\s*`?([a-zA-Z0-9/_-]+)`?',
    r'`([a-zA-Z0-9/_-]+/[a-zA-Z0-9/_-]+)`',
]

for pattern in patterns:
    match = re.search(pattern, full_text)
    if match:
        branch_name = match.group(1)
        break
```

**優先度2: Issue コメントから抽出**

Issue 本文で見つからない場合、コメント（新しい順）から同様に検索。

**優先度3: Issue タイトルから生成**

ブランチ名が見つからない場合、Issue タイトルから生成:

```python
def generate_branch_name(issue_number, issue_title):
    # タイトルをスラッグ化
    # 1. 小文字化
    # 2. 記号・スペースをハイフンに変換
    # 3. 連続ハイフンを1つに
    # 4. 最大40文字に制限
    import re
    slug = issue_title.lower()
    slug = re.sub(r'[^a-z0-9]+', '-', slug)
    slug = re.sub(r'-+', '-', slug)
    slug = slug.strip('-')[:40].rstrip('-')

    return f"feature/{issue_number}-{slug}"
```

**例:**
- Issue #123 "Add user authentication" → `feature/123-add-user-authentication`
- Issue #456 "Fix bug in login flow" → `feature/456-fix-bug-in-login-flow`

### 3. ユーザー確認

ブランチ名を提案してユーザーに確認:

```
📋 Issue #123: Add user authentication

ブランチ名: feature/123-add-user-authentication

このブランチで作業を開始しますか？ [Y/n]:
```

ユーザーが拒否した場合、別のブランチ名を入力してもらう。

### 4. ブランチ作成またはチェックアウト

**リモートブランチの確認:**

```bash
git fetch origin
git show-ref --verify --quiet "refs/remotes/origin/${branch_name}"
```

**ブランチ作成:**

- リモートにブランチが存在する場合:
  ```bash
  git checkout -b ${branch_name} origin/${branch_name}
  ```

- リモートにブランチが存在しない場合:
  ```bash
  git checkout -b ${branch_name} main
  ```

### 5. コンテナ起動

```bash
make worker/up BRANCH=${branch_name}
```

コンテナ起動の出力から以下を取得:
- コンテナ名
- ポート番号
- アクセスURL

### 6. Issue へのコメント追加

コンテナ起動成功後、Issue にコメントを追加:

```bash
gh issue comment ${issue_number} --body "作業ブランチ: \`${branch_name}\`
コンテナポート: \`${port}\`
アクセスURL: http://localhost:${port}"
```

**コメントフォーマット例:**

```markdown
🚀 開発環境を起動しました

**ブランチ:** `feature/123-add-user-authentication`
**ポート:** `8081`
**URL:** http://localhost:8081

コンテナを停止する場合:
\`\`\`bash
make worker/stop BRANCH=feature/123-add-user-authentication
\`\`\`
```

## エラーハンドリング

### GitHub CLI 未認証

```bash
gh auth status || {
  echo "❌ GitHub CLI が認証されていません"
  echo "以下のコマンドで認証してください:"
  echo "  gh auth login"
  exit 1
}
```

### Issue が見つからない

```bash
if ! gh issue view ${issue_number} >/dev/null 2>&1; then
  echo "❌ Issue #${issue_number} が見つかりません"
  echo "Issue 番号を確認してください"
  exit 1
fi
```

### コンテナ起動失敗

```bash
if ! make worker/up BRANCH=${branch_name}; then
  echo "❌ コンテナの起動に失敗しました"
  echo "PostgreSQL コンテナが起動しているか確認してください:"
  echo "  make up"
  exit 1
fi
```

### Git 操作失敗

```bash
if ! git checkout -b ${branch_name} main; then
  echo "❌ ブランチの作成に失敗しました"
  echo "既存のブランチ名と競合している可能性があります"
  exit 1
fi
```

## 出力フォーマット

成功時の出力例:

```
🔍 Issue #123 の情報を取得中...
✓ Issue タイトル: Add user authentication

📋 ブランチ名を決定中...
✓ ブランチ名: feature/123-add-user-authentication

🌿 ブランチを作成中...
✓ main から新規ブランチ feature/123-add-user-authentication を作成しました

🐳 コンテナを起動中...
✓ コンテナ kura-worker-feature-123-add-user-authentication を起動しました
✓ ポート: 8081, URL: http://localhost:8081

💬 Issue にコメントを追加中...
✓ Issue #123 にブランチ情報を記録しました

✅ 開発環境の準備が完了しました！
```

## 使用例

**基本的な使い方:**

```
ユーザー: "Issue #123 から作業を始めたい"
ユーザー: "この Issue のコンテナを起動して"
ユーザー: "Issue 456 で開発したい"
```

**Issue URL を使用:**

```
ユーザー: "https://github.com/org/repo/issues/789 のコンテナを起動"
```

**ブランチ名が Issue に記載されている場合:**

Issue #123 の本文に以下が含まれる:
```
作業ブランチ: `feature/add-oauth-login`
```

→ `feature/add-oauth-login` ブランチを使用

## 既存コンテナの再利用

同じブランチのコンテナが既に存在する場合、`worker.sh` が自動的に再利用:

```
ℹ  コンテナ kura-worker-feature-123-xxx は既に起動しています
✓  ポート: 8081, URL: http://localhost:8081
```

この場合も Issue へのコメント追加は実行する。

## 注意事項

- ブランチ名は Git の命名規則に従う必要がある（英数字、ハイフン、スラッシュ、アンダースコア）
- Issue へのコメント追加には GitHub の書き込み権限が必要
- コンテナ起動前に PostgreSQL コンテナが起動している必要がある
- 1つの Issue に対して複数回実行した場合、同じブランチ・コンテナを再利用する
