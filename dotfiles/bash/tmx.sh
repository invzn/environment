# tmx: sesh/fzf session switcher with git worktree management.
#
# Usage:
#   tmx                 fuzzy-pick a session, directory, or worktree and connect;
#                       ctrl-n on a highlighted entry creates a worktree in that
#                       repo (prompts for the branch name) and connects to it
#   tmx new <branch> [base]
#                       create a worktree for <branch> in the current repo
#                       (branching from [base] if <branch> doesn't exist) and
#                       connect to a session rooted there
#   tmx ls              list tmx-managed worktrees and their branches
#   tmx rm              fuzzy-pick a worktree, remove it, and kill its session
#
# Worktrees live inside each repo at <repo>/.worktrees/<branch> (slashes in
# branch names become dashes). Since they're scattered across repos, created
# worktrees are recorded in $TMX_REGISTRY so the picker/ls/rm can list them;
# stale entries are filtered out on read. `.worktrees/` is auto-added to each
# repo's .git/info/exclude so it never shows up as untracked.
#
# Caveat: sesh names sessions after the directory basename, so worktrees for
# the same branch name in two different repos share one tmux session name.

TMX_REGISTRY="${TMX_REGISTRY:-${XDG_STATE_HOME:-$HOME/.local/state}/tmx/worktrees}"

_tmx_worktrees () {
  [ -f "$TMX_REGISTRY" ] || return 0
  local wt
  while IFS= read -r wt; do
    [ -d "$wt" ] && printf '%s\n' "$wt"
  done < "$TMX_REGISTRY"
  return 0
}

_tmx_register () {
  mkdir -p "$(dirname "$TMX_REGISTRY")"
  grep -qxF "$1" "$TMX_REGISTRY" 2>/dev/null || echo "$1" >> "$TMX_REGISTRY"
}

_tmx_unregister () {
  [ -f "$TMX_REGISTRY" ] || return 0
  grep -vxF "$1" "$TMX_REGISTRY" > "$TMX_REGISTRY.tmp"
  mv "$TMX_REGISTRY.tmp" "$TMX_REGISTRY"
}

# Resolve a picker selection (a ~/path or a tmux session name) to a directory.
_tmx_resolve_dir () {
  local sel="$1" path
  case "$sel" in
    "~"*) sel="$HOME${sel#\~}" ;;
  esac
  if [ -d "$sel" ]; then
    echo "$sel"
    return 0
  fi
  path="$(tmux display-message -p -t "=$1" '#{session_path}' 2>/dev/null)"
  if [ -d "$path" ]; then
    echo "$path"
    return 0
  fi
  echo "tmx: cannot resolve '$1' to a directory" >&2
  return 1
}

# Create (if needed) a worktree for <branch> in the repo containing <dir>,
# then connect. New branches base off <dir>'s HEAD unless [base] is given.
_tmx_new () {
  local dir="$1" branch="$2" base="$3" git_dir repo_root wt
  git_dir="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || {
    echo "tmx: $dir is not inside a git repository" >&2
    return 1
  }
  repo_root="${git_dir%/.git}"
  wt="$repo_root/.worktrees/$(echo "$branch" | tr '/' '-')"
  if [ ! -d "$wt" ]; then
    grep -qxF '.worktrees/' "$git_dir/info/exclude" 2>/dev/null || \
      echo '.worktrees/' >> "$git_dir/info/exclude"
    if git -C "$dir" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$dir" worktree add "$wt" "$branch" || return 1
    else
      git -C "$dir" worktree add -b "$branch" "$wt" ${base:+"$base"} || return 1
    fi
    _tmx_register "$wt"
    zoxide add "$wt"
  fi
  sesh connect "$wt"
}

_tmx_pick () {
  local out query key sel dir branch
  out="$({ sesh list; _tmx_worktrees | sed "s|^$HOME|~|"; } | awk '!seen[$0]++' | \
    fzf --print-query --expect=ctrl-n \
        --header 'enter: connect | ctrl-n: new worktree in highlighted repo')" || return
  query="$(sed -n 1p <<< "$out")"
  key="$(sed -n 2p <<< "$out")"
  sel="$(sed -n 3p <<< "$out")"
  if [ "$key" = "ctrl-n" ]; then
    if [ -n "$sel" ]; then
      dir="$(_tmx_resolve_dir "$sel")" || return 1
    else
      dir="$PWD"
    fi
    branch="$(fzf --prompt 'new worktree branch: ' --query "$query" \
                  --bind 'enter:print-query' --no-info \
                  --header "repo: $dir" < /dev/null)"
    [ -n "$branch" ] || return 0
    _tmx_new "$dir" "$branch"
  else
    [ -n "$sel" ] && sesh connect "$sel"
  fi
}

_tmx_ls () {
  local wt
  _tmx_worktrees | while read -r wt; do
    printf '%s  [%s]\n' "$wt" "$(git -C "$wt" branch --show-current 2>/dev/null)"
  done
}

_tmx_rm () {
  local wt main_repo
  wt="$(_tmx_worktrees | fzf)" || return
  [ -n "$wt" ] || return
  main_repo="$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  main_repo="${main_repo%/.git}"
  if [ -n "$main_repo" ]; then
    git -C "$main_repo" worktree remove "$wt" || {
      echo "tmx rm: worktree is dirty; to discard its changes run:" >&2
      echo "  git -C $main_repo worktree remove --force $wt" >&2
      return 1
    }
  else
    echo "tmx rm: $wt is not a git worktree; not touching it" >&2
    return 1
  fi
  tmux kill-session -t "=$(basename "$wt")" 2>/dev/null
  zoxide remove "$wt" 2>/dev/null
  _tmx_unregister "$wt"
  return 0
}

tmx () {
  case "$1" in
    "")  _tmx_pick ;;
    new)
      if [ -z "$2" ]; then
        echo "usage: tmx new <branch> [base]" >&2
        return 1
      fi
      _tmx_new "$PWD" "$2" "$3"
      ;;
    ls)  _tmx_ls ;;
    rm)  _tmx_rm ;;
    *)
      echo "usage: tmx [new <branch> [base] | ls | rm]" >&2
      return 1
      ;;
  esac
}
