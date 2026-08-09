# tmx: sesh/fzf session switcher with git worktree management.
#
# Usage:
#   tmx                 flat picker over every worktree of every git repo
#                       among sesh's sessions and directories, shown as
#                       "[host/org/repo] worktree" (relative to
#                       $_TMX_REPO_BASE, basename for repos elsewhere) and
#                       ordered most recently used at
#                       the bottom (recency = the worktree session's last
#                       tmux attach; sessionless worktrees sort last). Enter
#                       opens the highlighted worktree; ctrl-n creates a new
#                       one: pick a repo, then type the branch name.
#   tmx new <branch> [base]
#                       create a worktree for <branch> in the current repo
#                       (branching from [base] if <branch> doesn't exist) and
#                       connect to a session rooted there
#   tmx ls              list the current repo's worktrees
#   tmx rm              pick a repo, then one of its worktrees to remove;
#                       kills the worktree's tmux session too
#
# Worktrees live inside each repo at <repo>/.worktrees/<branch> (slashes in
# branch names become dashes). `.worktrees/` is auto-added to each repo's
# .git/info/exclude so it never shows up as untracked. Listings come straight
# from `git worktree list`, so worktrees created outside tmx show up too.
#
# Caveat: sesh names sessions after the directory basename, so worktrees for
# the same branch name in two different repos share one tmux session name.

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

# Resolve picker selection $1 to a directory using the pre-fetched tmux
# session list in $_tmx_tmux_sessions ("name<TAB>path" lines, one snapshot
# per _tmx_repos call). Sets $_tmx_dir on success; no forks either way.
_tmx_resolve_from_sessions () {
  local sel="$1" lname lpath
  case "$sel" in
    "~"*) sel="$HOME${sel#\~}" ;;
  esac
  if [ -d "$sel" ]; then
    _tmx_dir="$sel"
    return 0
  fi
  while IFS=$'\t' read -r lname lpath; do
    if [ "$lname" = "$1" ] && [ -d "$lpath" ]; then
      _tmx_dir="$lpath"
      return 0
    fi
  done <<<"$_tmx_tmux_sessions"
  return 1
}

# Find the main checkout root that owns directory $1 by walking upward
# through the filesystem, without forking. Sets $_tmx_root on success;
# returns 1 if $1 isn't inside a git repo (walked all the way to "/").
# The only case that forks is a linked worktree whose recorded gitdir is a
# relative path -- rare in practice (git records absolute gitdir paths) --
# where one `cd`+`pwd -P` subshell normalizes it.
_tmx_repo_root () {
  local cur="$1" parent line gitdir name reldir relfile
  case "$cur" in
    /*) ;;
    *) cur="$PWD/$cur" ;;
  esac
  [ "$cur" != "/" ] && cur="${cur%/}"
  while true; do
    if [ -d "$cur/.git" ]; then
      _tmx_root="$cur"
      return 0
    fi
    if [ -f "$cur/.git" ]; then
      IFS= read -r line < "$cur/.git" || return 1
      gitdir="${line#gitdir: }"
      case "$gitdir" in
        /*) ;;
        */*) reldir="${gitdir%/*}"; relfile="${gitdir##*/}"
             gitdir="$(cd "$cur/$reldir" 2>/dev/null && pwd -P)/$relfile" ;;
        *)   gitdir="$(cd "$cur" 2>/dev/null && pwd -P)/$gitdir" ;;
      esac
      case "$gitdir" in
        */worktrees/*)
          name="${gitdir##*/worktrees/}"
          _tmx_root="${gitdir%/worktrees/"$name"}"
          _tmx_root="${_tmx_root%/.git}"
          return 0
          ;;
        *) return 1 ;;
      esac
    fi
    [ "$cur" = "/" ] && return 1
    parent="${cur%/*}"
    [ -z "$parent" ] && parent="/"
    cur="$parent"
  done
}

# The git repos among sesh's sessions and directories, deduped to their main
# checkout root (linked worktrees collapse into their repo), ~-abbreviated.
_tmx_repos () {
  local sel _tmx_tmux_sessions _tmx_dir _tmx_root
  _tmx_tmux_sessions="$(tmux list-sessions -F '#{session_name}	#{session_path}' 2>/dev/null)"
  sesh list | awk '!seen[$0]++' | while IFS= read -r sel; do
    _tmx_resolve_from_sessions "$sel" || continue
    _tmx_repo_root "$_tmx_dir" || continue
    echo "$_tmx_root"
  done | awk '!seen[$0]++' | sed "s|^$HOME|~|"
}

# List <root>'s worktrees as "<name>\t<path>" lines; the main checkout is
# named "main", linked worktrees go by their directory basename.
_tmx_repo_worktrees () {
  local root="$1" wt
  git -C "$root" worktree list --porcelain | awk '/^worktree /{print substr($0,10)}' | \
  while IFS= read -r wt; do
    if [ "$wt" = "$root" ]; then
      printf 'main\t%s\n' "$wt"
    else
      printf '%s\t%s\n' "$(basename "$wt")" "$wt"
    fi
  done
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
    zoxide add "$wt"
  fi
  sesh connect "$wt"
}

# Repos checked out under this base are labeled by their path relative to
# it (host/org/repo, e.g. "github.com/invzn/environment"); repos elsewhere
# fall back to their directory basename.
_TMX_REPO_BASE="$HOME/Development/remote"

# Display label for the repo rooted at $1. Sets $_tmx_label; no forks.
_tmx_repo_label () {
  local root="$1"
  _tmx_label="${root#"$_TMX_REPO_BASE"/}"
  [ "$_tmx_label" = "$root" ] && _tmx_label="${root##*/}"
}

# Every worktree of every repo as "[repo] name\t<path>" lines, most
# recently used first (recency = the last tmux attach of a session rooted
# at the worktree; sessionless worktrees keep repo order at the end). With
# fzf's default bottom-prompt layout that puts the most recent entries at
# the bottom, next to the prompt.
_tmx_worktrees_mru () {
  local repo root name path t p mru sessions tab=$'\t' _tmx_label
  sessions="$(tmux list-sessions -F '#{session_last_attached}	#{session_path}' 2>/dev/null)"
  _tmx_repos | while IFS= read -r repo; do
    root="${repo/#\~/$HOME}"
    _tmx_repo_label "$root"
    _tmx_repo_worktrees "$root" | while IFS=$'\t' read -r name path; do
      mru=0
      while IFS=$'\t' read -r t p; do
        if [ "$p" = "$path" ] && [ "${t:-0}" -gt "$mru" ]; then
          mru="$t"
        fi
      done <<<"$sessions"
      printf '%s\t[%s] %s\t%s\n' "$mru" "$_tmx_label" "$name" "$path"
    done
  done | sort -s -t "$tab" -k1,1rn | cut -f2-
}

# ctrl-n flow: pick the repo, type the new branch name, create + connect.
# Returns 1 on cancel at either step so the caller can reopen the picker.
_tmx_new_flow () {
  local repo root branch
  repo="$(_tmx_repos | fzf --header 'new worktree in which repo?')" || return 1
  [ -n "$repo" ] || return 1
  root="${repo/#\~/$HOME}"
  read -r -p "new branch name: " branch || return 1
  [ -n "$branch" ] || return 1
  _tmx_new "$root" "$branch"
}

_tmx_pick () {
  local out key sel tab=$'\t'
  while true; do
    out="$(_tmx_worktrees_mru | \
      fzf --delimiter "$tab" --with-nth 1 --expect=ctrl-n \
          --header 'enter: open | ctrl-n: new worktree')" || return 0
    key="${out%%$'\n'*}"
    sel="${out#*$'\n'}"
    if [ "$key" = "ctrl-n" ]; then
      _tmx_new_flow && return 0
      continue
    fi
    [ -n "$sel" ] || return 0
    sesh connect "${sel#*"$tab"}"
    return 0
  done
}

_tmx_ls () {
  git worktree list || {
    echo "tmx ls: not inside a git repository" >&2
    return 1
  }
}

_tmx_rm () {
  local repo root wt tab=$'\t'
  repo="$(_tmx_repos | fzf --header 'pick the repo to remove a worktree from')" || return 0
  [ -n "$repo" ] || return 0
  root="$(_tmx_resolve_dir "$repo")" || return 1
  wt="$(_tmx_repo_worktrees "$root" | grep -v "^main$tab" | \
    fzf --delimiter "$tab" --with-nth 1 --header "remove a worktree of $(basename "$root")")" || return 0
  [ -n "$wt" ] || return 0
  wt="${wt#*"$tab"}"
  git -C "$root" worktree remove "$wt" || {
    echo "tmx rm: worktree is dirty; to discard its changes run:" >&2
    echo "  git -C $root worktree remove --force $wt" >&2
    return 1
  }
  tmux kill-session -t "=$(basename "$wt")" 2>/dev/null
  zoxide remove "$wt" 2>/dev/null
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
