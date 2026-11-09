#!/usr/bin/env bash
# Bash 3.2+, Git and a SHA-256 utility. Records are data, never sourced.
set -euo pipefail
umask 077

action=${1:-}
[[ $# -eq 0 ]] || shift
project='' prefix='' dry_run=0 locked=0 temporary=''
state_dir=${NDD_STATE_DIR:-$HOME/.ndd}
projects_dir="$state_dir/projects"
lock_dir="$state_dir/.projects.lock"
fail() { echo "Project registry: $*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project|--prefix)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      if [[ "$1" == --project ]]; then project=$2; else prefix=$2; fi
      shift ;;
    --dry-run) dry_run=1 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done
[[ "$action" == register || "$action" == cleanup ]] || fail 'Use register --project PATH --prefix VALUE, or cleanup [--dry-run].'
[[ "$action" != register || $dry_run -eq 0 ]] || fail 'Registration does not accept --dry-run.'

check_directory() {
  local current=$1
  [[ "$current" == /* && "$current" != / && "$current" != *$'\n'* && "$current" != *$'\r'* && "$current" != *$'\t'* ]] || return 1
  [[ "/$current/" != */../* && "/$current/" != */./* ]] || return 1
  while [[ "$current" != / ]]; do
    [[ ! -L "$current" && ( ! -e "$current" || -d "$current" ) ]] || return 1
    current=$(dirname "$current")
  done
}
check_directory "$state_dir" && check_directory "$projects_dir" || fail 'Registry paths must be absolute real directories.'
[[ ! -e "$lock_dir" && ! -L "$lock_dir" ]] || fail "Registry lock exists: $lock_dir"
if [[ "$action" == cleanup && ! -d "$projects_dir" ]]; then exit 0; fi
for variable in GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_CONFIG GIT_CONFIG_COUNT; do
  [[ -z "${!variable:-}" ]] || fail "Run without the $variable environment override."
done
command -v git >/dev/null 2>&1 || fail 'Git is required.'
if command -v shasum >/dev/null 2>&1; then
  hash_path() { printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }
elif command -v sha256sum >/dev/null 2>&1; then
  hash_path() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }
else fail 'SHA-256 utility missing.'; fi

check_git_dir() {
  local common=$1 resolved
  check_directory "$common" || return 1
  [[ -f "$common/config" && ! -L "$common/config" ]] || return 1
  resolved=$(git --git-dir="$common" rev-parse --path-format=absolute --git-common-dir) || return 1
  [[ "$resolved" == "$common" ]]
}
read_prefix() {
  local code=0
  saved_prefix=$(git config --file "$1/config" --no-includes --get-all ndd.prefix; code=$?; printf '\001'; exit "$code") || code=$?
  saved_prefix=${saved_prefix%$'\001'}
  saved_prefix=${saved_prefix%$'\n'}
  [[ $code -eq 0 || $code -eq 1 ]] || return "$code"
  prefix_present=1
  [[ $code -ne 1 ]] || prefix_present=0
}
release_lock() {
  [[ -z "$temporary" ]] || rm -f -- "$temporary"
  if [[ $locked -eq 1 ]]; then rmdir "$lock_dir"; fi
}
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ $dry_run -eq 0 ]]; then
  mkdir -p "$state_dir"
  mkdir "$lock_dir" 2>/dev/null || fail "Registry lock exists: $lock_dir"
  locked=1
fi

if [[ "$action" == register ]]; then
  [[ -n "$project" ]] || fail 'Provide --project PATH.'
  [[ "$prefix" =~ ^[a-z][a-z0-9]{1,15}$ ]] || fail 'Invalid prefix.'
  project=$(git -C "$project" rev-parse --show-toplevel) || fail 'Project is not a Git worktree.'
  project=$(cd "$project" && pwd -P)
  common=$(git -C "$project" rev-parse --path-format=absolute --git-common-dir)
  check_directory "$project" && check_git_dir "$common" || fail 'Project Git paths are unavailable or redirected.'
  read_prefix "$common" || fail 'Cannot read local ndd.prefix.'
  [[ $prefix_present -eq 1 && "$saved_prefix" == "$prefix" ]] || fail 'Save and verify the confirmed local prefix before registering it.'
  mkdir -p "$projects_dir"
  record="$projects_dir/$(hash_path "$common").record"
  [[ ! -L "$record" && ( ! -e "$record" || -f "$record" ) ]] || fail "Invalid record: $record"
  if [[ -f "$record" ]]; then
    previous=$(sed -n '5p' "$record")
    [[ "$(wc -l < "$record" | tr -d '[:space:]')" == 5 && "$(sed -n '1p' "$record")" == ndd-project-v1 && "$(sed -n '3p' "$record")" == "$common" && "$(sed -n '4p' "$record")" == ndd.prefix && "$previous" =~ ^[a-z][a-z0-9]{1,15}$ ]] || fail "Malformed record: $record"
  fi
  # Keep repeat setup (including another linked worktree) free of timestamp churn.
  if [[ -f "$record" ]] && [[ "$(sed -n '1p' "$record")" == ndd-project-v1 && "$(sed -n '3p' "$record")" == "$common" && "$(sed -n '4p' "$record")" == ndd.prefix && "$(sed -n '5p' "$record")" == "$prefix" && "$(wc -l < "$record" | tr -d '[:space:]')" == 5 ]]; then
    echo "Project already registered: $project"
    exit 0
  fi
  temporary=$(mktemp "$projects_dir/.record.XXXXXX")
  printf 'ndd-project-v1\n%s\n%s\nndd.prefix\n%s\n' "$project" "$common" "$prefix" > "$temporary"
  mv -f -- "$temporary" "$record"
  temporary=''
  echo "Registered project: $project (ndd.prefix=$prefix)"
  exit 0
fi

read_specs_root() {
  local code=0
  specs_root=$(git config --file "$1/config" --no-includes --get ndd.specsRoot) || code=$?
  [[ $code -eq 0 || $code -eq 1 ]] || return 1
  [[ $code -eq 0 ]] || specs_root=''
}
clean_private_specs() {
  local common=$1 worktrees line link exclude answer code
  read_specs_root "$common" || return 1
  [[ -n "$specs_root" ]] || return 0
  # Only a folder created by setup under the NDD state directory may be deleted.
  if [[ "$(dirname "$specs_root")" != "$state_dir/specs" ]] || ! check_directory "$specs_root"; then
    echo "Private specs folder is not inside $state_dir/specs; retained: $specs_root" >&2
    return 1
  fi
  echo "Remove private specs settings (ndd.specsRoot, ndd-specs links, exclude line): $specs_root"
  if [[ $dry_run -eq 1 ]]; then
    [[ ! -d "$specs_root" ]] || echo "Uninstall will ask whether to delete private specs: $specs_root"
    return 0
  fi
  worktrees=$(git --git-dir="$common" worktree list --porcelain) || return 1
  while IFS= read -r line; do
    [[ "$line" == 'worktree '* ]] || continue
    link="${line#worktree }/ndd-specs"
    if [[ -L "$link" && "$(readlink "$link")" == "$specs_root" ]]; then rm -- "$link"; fi
  done <<< "$worktrees"
  exclude="$common/info/exclude"
  if [[ -f "$exclude" ]] && grep -qx '/ndd-specs' "$exclude"; then
    code=0
    grep -vx '/ndd-specs' "$exclude" > "$exclude.ndd-tmp" || code=$?
    [[ $code -le 1 ]] || return 1
    mv -f -- "$exclude.ndd-tmp" "$exclude"
  fi
  if [[ -d "$specs_root" ]]; then
    printf 'Delete private specs permanently? %s [y/N] ' "$specs_root"
    answer=''
    read -r answer || true
    if [[ "$answer" == y || "$answer" == Y ]]; then
      rm -rf -- "$specs_root"
      echo "Deleted private specs: $specs_root"
    else
      echo "Kept private specs: $specs_root"
    fi
  fi
  git config --file "$common/config" --no-includes --unset-all ndd.specsRoot || return 1
}
clean_record() {
  local record=$1 project common key prefix expected
  [[ -f "$record" && ! -L "$record" ]] || return 1
  [[ "$(wc -l < "$record" | tr -d '[:space:]')" == 5 && "$(sed -n '1p' "$record")" == ndd-project-v1 ]] || return 1
  project=$(sed -n '2p' "$record"); common=$(sed -n '3p' "$record")
  key=$(sed -n '4p' "$record"); prefix=$(sed -n '5p' "$record")
  [[ "$key" == ndd.prefix && "$prefix" =~ ^[a-z][a-z0-9]{1,15}$ ]] || return 1
  expected="$projects_dir/$(hash_path "$common").record"
  [[ "$record" == "$expected" ]] && check_git_dir "$common" || return 1
  clean_private_specs "$common" || return 1
  read_prefix "$common" || return 1
  if [[ $prefix_present -eq 1 && "$saved_prefix" != "$prefix" ]]; then
    echo "Prefix changed; retained: $project" >&2
    return 1
  fi
  echo "Remove registered ndd.prefix=$prefix: $project"
  [[ $dry_run -eq 0 ]] || return 0
  if [[ $prefix_present -eq 1 ]]; then
    # Match the recorded value, so a different concurrent value is not deleted.
    git config --file "$common/config" --no-includes --unset-all ndd.prefix "^$prefix$" || return 1
    read_prefix "$common" || return 1
    [[ $prefix_present -eq 0 ]] || return 1
  fi
  rm -- "$record"
}
failed=0
for record in "$projects_dir"/* "$projects_dir"/.[!.]* "$projects_dir"/..?*; do
  [[ -e "$record" || -L "$record" ]] || continue
  if ! clean_record "$record"; then
    echo "Warning: project cleanup skipped; retained record: $record" >&2
    failed=1
  fi
done
if [[ $dry_run -eq 0 && $failed -eq 0 ]]; then
  rmdir "$projects_dir"
  if [[ -d "$state_dir/specs" && -z "$(ls -A "$state_dir/specs")" ]]; then rmdir "$state_dir/specs"; fi
  rmdir "$lock_dir"; locked=0
  # Preserve unrelated contents in the common NDD state directory.
  if [[ -z "$(ls -A "$state_dir")" ]]; then rmdir "$state_dir"; fi
fi
