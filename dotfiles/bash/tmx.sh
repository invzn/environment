# tmx: sesh/fzf session switcher with git worktree management.
#
# Usage:
#   tmx                 two-stage picker. Stage one: the git repos among sesh's
#                       sessions and directories, deduped to their main
#                       checkout (non-repo entries are filtered out). Stage
#                       two: the chosen repo's worktrees -- enter opens the
#                       highlighted one, typing a new branch name and pressing
#                       enter creates a worktree for it, esc returns to stage
#                       one.
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

# Stage two: open one of <root>'s worktrees, or create one by typing a new
# branch name. Returns 1 on cancel so the caller can reopen stage one.
_tmx_pick_worktree () {
  local root="$1" out tab=$'\t'
  out="$(_tmx_repo_worktrees "$root" | \
    fzf --delimiter "$tab" --with-nth 1 \
        --bind 'enter:accept-or-print-query' \
        --header "$(basename "$root") worktrees | enter: open, or type a new branch name to create")" || return 1
  [ -n "$out" ] || return 1
  case "$out" in
    *"$tab"*) sesh connect "${out#*"$tab"}" ;;
    *)        _tmx_new "$root" "$out" ;;
  esac
}

_tmx_pick () {
  local repo root
  while true; do
    repo="$(_tmx_repos | fzf --header 'pick a repo')" || return 0
    [ -n "$repo" ] || return 0
    root="$(_tmx_resolve_dir "$repo")" || return 1
    _tmx_pick_worktree "$root" && return 0
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
