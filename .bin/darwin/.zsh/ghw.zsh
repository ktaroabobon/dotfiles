# ----------------------------------------------------------------
# Git Worktree Helper (`ghw` command)
# ----------------------------------------------------------------
function ghw() {
  # Gitリポジトリで実行されているかチェック
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository." >&2
    return 1
  fi

  # 引数がない場合は `git worktree list` を実行
  if [ -z "$1" ]; then
    git worktree list
    return
  fi

  case "$1" in
    # `ghw switch <branch>`: ワークツリーの切り替え・作成
    switch)
      shift # "switch" を引数リストから削除
      local branch_name="$1"
      if [ -z "$branch_name" ]; then
        echo "Usage: ghw switch <branch-name>" >&2
        return 1
      fi

      # メインのワークツリーのパスを取得 (e.g., /path/to/your-repo)
      local main_worktree_path
      main_worktree_path=$(git worktree list --porcelain | head -n1 | cut -d' ' -f2)

      # 移動先のブランチに紐づくワークツリーのパスを検索
      local target_path
      target_path=$(git worktree list | grep "\[$branch_name\]" | awk '{print $1}')

      if [ -n "$target_path" ]; then
        # ワークツリーが既に存在すれば、そこに移動
        echo "✅ Switched to existing worktree for '$branch_name'"
        cd "$target_path"
      else
        # ワークツリーが存在しなければ、新規作成
        # --- カスタマイズポイント ---
        # 作成場所: メインワークツリーの親ディレクトリ (../<branch_name>)
        # 例: `/path/to/your-repo` の隣に `/path/to/feature-x` を作成
        local new_path="$main_worktree_path/../$branch_name"

        if [ -d "$new_path" ]; then
          echo "Error: Directory '$new_path' already exists." >&2
          echo "Run 'git worktree prune' and remove the directory manually if it's a stale worktree." >&2
          return 1
        fi
        
        echo "🛠️ Creating new worktree for branch '$branch_name'..."
        
        # ローカルにブランチが存在するかチェック
        if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
          # 存在する場合: そのブランチでワークツリーを作成
          git worktree add "$new_path" "$branch_name"
        else
          # 存在しない場合: ブランチを新規作成 (-b) してワークツリーを作成
          git worktree add -b "$branch_name" "$new_path"
        fi

        if [ $? -eq 0 ]; then
          echo "✅ Created and switched to new worktree."
          cd "$new_path"
        else
          echo "Error: Failed to create worktree." >&2
          return 1
        fi
      fi
      ;;

    # `git` の基本コマンドはそのまま実行
    add | commit | push | merge | reset | switch | branch | checkout | status | log | diff | pull )
      git "$@"
      ;;

    # 上記以外は `git worktree` のコマンドとして実行 (list, remove, prune など)
    *)
      git worktree "$@"
      ;;
  esac
}

