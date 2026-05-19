すべての変更を commit して remote に push してください。

## Step 1: commit

`/commit` の手順に従ってすべての変更を commit してください（CI チェック → 塊ごとに commit）。

## Step 2: push 前の steering 同期（該当する場合）

プロジェクトに `.kiro/steering/` が存在する場合、push 前に `/kiro:steering` を実行して同期すること。
- steering に変更があった場合はその差分も commit に含める

## Step 3: push

`git push origin [現在のブランチ名]` で push する。upstream が未設定なら `-u` を付ける。
