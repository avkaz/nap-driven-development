#!/usr/bin/env bash
# Bash 3.2+; uninstall can also remove the verified, clean NDD source clone.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$KIT_DIR" != *$'\n'* && "$KIT_DIR" != *$'\t'* ]] || { echo 'Distribution path contains tabs or line breaks.' >&2; exit 1; }
NAMES=(ndd-setup ndd-spec ndd-plan ndd-do ndd-help ndd-review ndd-init)
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
CODEX_DIR="$HOME/.agents/skills"
WANT_CLAUDE=0 WANT_CODEX=0 UNINSTALL=0 DRY_RUN=0 REPLACE=0 KEEP_SOURCE=0
MODE=copy
TARGETS=() LOCKS=() STAGES=() DESTS=() BACKUPS=() RECEIPTS=()
OLD_MOVED=() RECORD_MOVED=() NEW_INSTALLED=() NEW_RECORDED=()
SUCCESS=0

cleanup_registered_projects() {
  local helper="$KIT_DIR/skills/ndd-setup/scripts/project-registry.sh"
  local state_dir=${NDD_STATE_DIR:-$HOME/.ndd}
  if [[ -f "$helper" ]]; then
    if ! bash "$helper" cleanup "$@"; then
      echo "Warning: project cleanup was skipped or incomplete; continuing NDD removal. Registry retained at $state_dir/projects." >&2
    fi
  elif [[ -e "$state_dir/projects" || -L "$state_dir/projects" || -e "$state_dir/.projects.lock" ]]; then
    echo "Warning: project cleanup helper is missing; continuing NDD removal. Registry retained at $state_dir/projects." >&2
  fi
}

usage() {
  cat <<'HELP'
Usage: bash install.sh [--claude | --codex | --all] [options]
  --dry-run           show actions without writing anything
  --uninstall         remove owned skills/state; with both agents, clean up this NDD clone
  --keep-source       keep this source clone during uninstall
  --replace           accepted for compatibility; replacement is automatic
  --link              development mode: link skills to this checkout
  --claude-dir PATH   select a custom Claude skills directory
  --codex-dir PATH    select a custom Codex skills directory
  -h, --help          show help
Without a target, detect existing agent directories; if none exist, use --all
or choose one agent explicitly. Existing NDD skills, including local edits,
are replaced automatically. Successful installs retain no backups. Receipts
live beside each skills folder in <skills-directory>.ndd-kit. Full uninstall
also clears registered ndd.prefix settings from ~/.ndd/projects (override root with NDD_STATE_DIR)
and private specs settings, asking before it deletes each private specs folder.
HELP
}
fail() { echo "Error: $*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) WANT_CLAUDE=1 ;;
    --codex) WANT_CODEX=1 ;;
    --all) WANT_CLAUDE=1; WANT_CODEX=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --keep-source) KEEP_SOURCE=1 ;;
    --replace) REPLACE=1 ;;
    --link) MODE=link ;;
    --claude-dir|--codex-dir)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "$1 needs a path"
      if [[ "$1" == --claude-dir ]]; then CLAUDE_DIR="$2"; WANT_CLAUDE=1
      else CODEX_DIR="$2"; WANT_CODEX=1; fi
      shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1 (use --help)" ;;
  esac
  shift
done
[[ $UNINSTALL -eq 0 || $REPLACE -eq 0 ]] || fail "--replace cannot be used with --uninstall; preserve modified files manually."
[[ $UNINSTALL -eq 0 || "$MODE" == copy ]] || fail "--link is an install option."
[[ $KEEP_SOURCE -eq 0 || $UNINSTALL -eq 1 ]] || fail "--keep-source requires --uninstall."
if [[ $WANT_CLAUDE -eq 0 && $WANT_CODEX -eq 0 ]]; then
  [[ -d "${CLAUDE_DIR%/skills}" ]] && WANT_CLAUDE=1
  [[ -d "${CODEX_HOME:-$HOME/.codex}" || -d "$HOME/.agents" ]] && WANT_CODEX=1
fi
[[ $WANT_CLAUDE -eq 1 || $WANT_CODEX -eq 1 ]] || fail "No agent detected. Select --claude, --codex, or --all."
[[ $WANT_CLAUDE -eq 0 ]] || TARGETS+=("$CLAUDE_DIR")
[[ $WANT_CODEX -eq 0 ]] || TARGETS+=("$CODEX_DIR")

if command -v shasum >/dev/null 2>&1; then
  hash() { shasum -a 256 | awk '{print $1}'; }
elif command -v sha256sum >/dev/null 2>&1; then
  hash() { sha256sum | awk '{print $1}'; }
else fail "SHA-256 utility missing (shasum or sha256sum)."; fi
exists() { [[ -e "$1" || -L "$1" ]]; }
# Reject symlinks and unusual names instead of following them during ownership checks.
fingerprint() (
  cd "$1" || exit 1
  find . -print | LC_ALL=C sort | while IFS= read -r path; do
    [[ "$path" == . ]] && continue
    [[ "$path" != *$'\t'* && ! -L "$path" ]] || exit 1
    if [[ -d "$path" ]]; then printf 'D\t%s\n' "$path"
    elif [[ -f "$path" ]]; then
      digest=$(hash < "$path") || exit 1
      printf 'F\t%s\t%s\n' "$digest" "$path"
    else exit 1; fi
  done | hash
)
# Ownership is enough for an explicitly requested uninstall, including local edits.
owned_receipt() {
  local record="$1" mode
  [[ -f "$record" && ! -L "$record" ]] || return 1
  case "$(sed -n '1p' "$record")" in
    ndd-kit-install)
      [[ "$(wc -l < "$record" | tr -d '[:space:]')" == 4 ]] || return 1
      mode=$(sed -n '2p' "$record") ;;
    ndd-kit-install-v1)
      # Accept existing ownership records during removal; new records omit kit metadata.
      [[ "$(wc -l < "$record" | tr -d '[:space:]')" == 5 ]] || return 1
      mode=$(sed -n '3p' "$record") ;;
    *) return 1 ;;
  esac
  [[ "$mode" == copy || "$mode" == link ]]
}
# Do not traverse redirected destination parents or metadata directories.
check_path() {
  local path="$1" current="$1"
  [[ "$path" == /* && "$path" != / && "$path" != *$'\n'* && "$path" != *$'\t'* ]] || fail "Use an absolute, non-root path: $path"
  [[ "$path" != *//* ]] || fail "Use a path without repeated separators: $path"
  [[ "/$path/" != */../* && "/$path/" != */./* ]] || fail "Use a path without . or ..: $path"
  while [[ "$current" != / ]]; do
    [[ ! -L "$current" ]] || fail "Destination parent is a symlink: $current. Use its real path."
    [[ ! -e "$current" || -d "$current" ]] || fail "Not a directory: $current"
    current=$(dirname "$current")
  done
  current="$path"
  while [[ ! -d "$current" ]]; do current=$(dirname "$current"); done
  [[ -w "$current" ]] || fail "Directory is not writable: $current"
}
# Only inspect this script's clone. Receipt paths never authorize source deletion.
clone_git() {
  git --no-optional-locks -c core.fsmonitor=false --git-dir="$KIT_DIR/.git" --work-tree="$KIT_DIR" "$@"
}
source_retention_reason() {
  local origin entries changes commits
  if [[ $KEEP_SOURCE -eq 1 ]]; then echo '--keep-source requested'; return; fi
  if [[ $WANT_CLAUDE -ne 1 || $WANT_CODEX -ne 1 ]]; then echo 'select both agents (--all) to remove the clone'; return; fi
  if [[ "$KIT_DIR" == / || "$KIT_DIR" == "$HOME" || "$KIT_DIR" != "$(cd "$KIT_DIR" && pwd -P)" ]]; then
    echo 'source is a protected or redirected directory'; return
  fi
  if [[ ! -d "$KIT_DIR/.git" || -L "$KIT_DIR/.git" ]]; then
    echo 'not a standalone Git clone (ZIPs and linked worktrees are kept)'; return
  fi
  if ! command -v git >/dev/null 2>&1; then echo 'Git is unavailable; source could not be verified'; return; fi
  origin=$(clone_git config --local --no-includes --get remote.origin.url 2>/dev/null) || {
    echo 'could not verify the source repository'; return;
  }
  case "$origin" in
    https://github.com/avkaz/nap-driven-development|https://github.com/avkaz/nap-driven-development.git|git@github.com:avkaz/nap-driven-development.git|ssh://git@github.com/avkaz/nap-driven-development.git) ;;
    *) echo 'origin is not the NDD repository'; return ;;
  esac
  if [[ -d "$KIT_DIR/.git/worktrees" ]]; then echo 'clone has linked worktree metadata'; return; fi
  entries=$(clone_git ls-files -v 2>/dev/null) || { echo 'could not verify the source index'; return; }
  if printf '%s\n' "$entries" | LC_ALL=C grep '^[a-zS] ' >/dev/null; then
    echo 'source index can hide changes (assume-unchanged or skip-worktree)'; return
  fi
  changes=$(clone_git status --porcelain=v1 --untracked-files=all --ignored --ignore-submodules=none 2>/dev/null) || {
    echo 'could not check local source changes'; return;
  }
  if [[ -n "$changes" ]]; then echo 'clone contains local changes, untracked or ignored files'; return; fi
  # Include stashes, detached HEAD and reflogs, not just the checked-out branch.
  commits=$(clone_git rev-list --max-count=1 HEAD --all --reflog --not --remotes 2>/dev/null) || {
    echo 'could not check unpublished source commits'; return;
  }
  if [[ -n "$commits" ]]; then echo 'clone contains history not present in local remote-tracking refs'; return; fi
  return 0
}
if [[ $UNINSTALL -eq 0 ]]; then
  for name in "${NAMES[@]}"; do
    src="$KIT_DIR/skills/$name"
    [[ ! -L "$src" && -f "$src/SKILL.md" && -f "$src/agents/openai.yaml" ]] || fail "Incomplete or linked distribution: $name"
    fingerprint "$src" >/dev/null || fail "Unsupported source entry in $src"
  done
  for asset in spec.md plan.md; do
    [[ -f "$KIT_DIR/skills/ndd-setup/assets/$asset" ]] || fail "Missing asset: $asset"
  done
  [[ -f "$KIT_DIR/skills/ndd-help/assets/help.md" ]] || fail "Missing help resource: assets/help.md"
  [[ -f "$KIT_DIR/skills/ndd-setup/references/project-context.md" ]] || fail "Missing project context resource."
  for resource in assets/review.md references/report-updates.md; do
    [[ -f "$KIT_DIR/skills/ndd-review/$resource" ]] || fail "Missing review resource: $resource"
  done
fi
# Preflight every selected target before the first write.
for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]%/}"; TARGETS[$i]="$target"
  check_path "$target"; check_path "$target.ndd-kit"
  if [[ $UNINSTALL -eq 0 ]]; then check_path "$target.ndd-kit/backups"; fi
  case "$target/" in "$KIT_DIR/"*) fail "Cannot install inside the distribution." ;; esac
  for name in "${NAMES[@]}"; do
    case "$KIT_DIR/" in "$target/$name/"*|"$target.ndd-kit/"*) fail "Distribution overlaps the installation destination." ;; esac
  done
  for other in "${TARGETS[@]:0:$i}"; do
    case "$target/" in "$other/"*|"$other.ndd-kit/"*) fail "Targets must not overlap." ;; esac
    case "$other/" in "$target/"*|"$target.ndd-kit/"*) fail "Targets must not overlap." ;; esac
  done
  echo "Target: $target"
  for name in "${NAMES[@]}"; do
    dest="$target/$name"; record="$target.ndd-kit/$name.receipt"
    [[ ! -L "$record" && ( ! -e "$record" || -f "$record" ) ]] || fail "Invalid receipt: $record"
    if [[ $UNINSTALL -eq 1 ]]; then
      if exists "$dest"; then
        owned_receipt "$record" || fail "Cannot establish NDD ownership: $dest. No files removed."
        echo "  Permanently remove (including local edits): $name"
      else echo "  Absent: $name"; fi
    elif exists "$dest"; then
      echo "  Replace (including local edits; no retained backup): $name"
    else echo "  Install ($MODE): $name"; fi
  done
  if [[ $UNINSTALL -eq 1 && -d "$target.ndd-kit" ]]; then
    echo "  Permanently remove all receipts, backups and staging files: $target.ndd-kit"
  elif [[ $UNINSTALL -eq 0 && -d "$target.ndd-kit/backups" ]]; then
    echo "  Remove previous backups after successful installation: $target.ndd-kit/backups"
  fi
done
SOURCE_REASON=''
if [[ $UNINSTALL -eq 1 ]]; then
  SOURCE_REASON=$(source_retention_reason)
  if [[ -n "$SOURCE_REASON" ]]; then echo "Keep source: $KIT_DIR ($SOURCE_REASON)"
  else echo "Permanently remove source clone after uninstall: $KIT_DIR"; fi
fi
if [[ $DRY_RUN -eq 1 ]]; then
  if [[ $UNINSTALL -eq 1 && $WANT_CLAUDE -eq 1 && $WANT_CODEX -eq 1 ]]; then
    cleanup_registered_projects --dry-run
  fi
  echo 'Dry run: no files changed.'; exit 0
fi

# Uninstall deliberately has no backup or rollback. Keep the lock until all
# contents have been removed, then remove the empty metadata directory.
if [[ $UNINSTALL -eq 1 ]]; then
  cleanup_uninstall() {
    local result=$? path
    set +e
    if [[ $result -ne 0 ]]; then
      echo 'Uninstall incomplete; already deleted files have no backup. Fix the reported error and rerun.' >&2
    fi
    if [[ ${#LOCKS[@]} -gt 0 ]]; then
      for path in "${LOCKS[@]}"; do
        [[ -z "$path" ]] || rmdir "$path" || result=1
      done
    fi
    return "$result"
  }
  trap cleanup_uninstall EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  for target in "${TARGETS[@]}"; do
    [[ -d "$target.ndd-kit" ]] || continue
    mkdir "$target.ndd-kit/lock" 2>/dev/null || fail "Install lock exists: $target.ndd-kit/lock. Check for an active/interrupted install."
    LOCKS+=("$target.ndd-kit/lock")
  done
  if [[ $WANT_CLAUDE -eq 1 && $WANT_CODEX -eq 1 ]]; then
    cleanup_registered_projects
  fi
  for target in "${TARGETS[@]}"; do
    [[ -d "$target.ndd-kit" ]] || continue
    for name in "${NAMES[@]}"; do
      dest="$target/$name"
      if exists "$dest"; then
        owned_receipt "$target.ndd-kit/$name.receipt" || fail "Ownership changed: $dest"
        # rm never follows a removed symlink, including nested backup links.
        rm -rf -- "$dest"
        echo "  Removed: $name"
      fi
    done
    for entry in "$target.ndd-kit"/* "$target.ndd-kit"/.[!.]* "$target.ndd-kit"/..?*; do
      exists "$entry" || continue
      [[ "$entry" == "$target.ndd-kit/lock" ]] && continue
      rm -rf -- "$entry"
    done
    for i in "${!LOCKS[@]}"; do
      if [[ "${LOCKS[$i]}" == "$target.ndd-kit/lock" ]]; then
        rmdir "${LOCKS[$i]}"; LOCKS[$i]=''
      fi
    done
    rmdir "$target.ndd-kit"
  done
  if [[ -z "$SOURCE_REASON" ]]; then
    # Recheck after removing skills, and leave the directory before deleting it.
    SOURCE_REASON=$(source_retention_reason)
    if [[ -z "$SOURCE_REASON" ]]; then
      cd "$(dirname "$KIT_DIR")"
      rm -rf -- "$KIT_DIR"
      exists "$KIT_DIR" && fail "Source removal incomplete: $KIT_DIR"
      echo "Removed source clone: $KIT_DIR"
    else echo "Source retained: $KIT_DIR ($SOURCE_REASON)"; fi
  fi
  echo 'NDD skills and install state removed. No backups retained. Your project files were preserved.'
  exit 0
fi

cleanup() {
  local exit_status=$? i recovery_failed=0
  set +e
  if [[ $SUCCESS -ne 1 ]]; then
    echo 'Installation failed; restoring previous skills and receipts.' >&2
    for ((i=${#DESTS[@]}-1; i>=0; i--)); do
      [[ "${NEW_INSTALLED[$i]}" == 0 ]] || rm -rf "${DESTS[$i]}" || recovery_failed=1
      [[ "${NEW_RECORDED[$i]}" == 0 ]] || rm -f "${RECEIPTS[$i]}" || recovery_failed=1
      [[ "${OLD_MOVED[$i]}" == 0 ]] || mv "${BACKUPS[$i]}/skill" "${DESTS[$i]}" || recovery_failed=1
      [[ "${RECORD_MOVED[$i]}" == 0 ]] || mv "${BACKUPS[$i]}/receipt" "${RECEIPTS[$i]}" || recovery_failed=1
    done
  fi
  # Previous copies exist only for rollback until all selected targets succeed.
  if [[ $SUCCESS -eq 1 ]]; then
    for target in "${TARGETS[@]}"; do
      rm -rf -- "$target.ndd-kit/backups" || recovery_failed=1
    done
  elif [[ $recovery_failed -eq 0 && ${#BACKUPS[@]} -gt 0 ]]; then
    for path in "${BACKUPS[@]}"; do rmdir "$path" || recovery_failed=1; done
  fi
  if [[ ${#STAGES[@]} -gt 0 ]]; then
    for path in "${STAGES[@]}"; do rm -rf "$path" || recovery_failed=1; done
  fi
  if [[ ${#LOCKS[@]} -gt 0 ]]; then
    for path in "${LOCKS[@]}"; do rmdir "$path" || recovery_failed=1; done
  fi
  if [[ $recovery_failed -ne 0 ]]; then
    echo 'Cleanup/restore incomplete. Inspect backups in the selected <skills-directory>.ndd-kit directories before retrying.' >&2
    exit 1
  fi
  return "$exit_status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Lock all targets before changing any skills. Never clear an existing lock.
for target in "${TARGETS[@]}"; do
  mkdir -p "$target.ndd-kit"
  mkdir "$target.ndd-kit/lock" 2>/dev/null || fail "Install lock exists: $target.ndd-kit/lock. Check for an active/interrupted install."
  LOCKS+=("$target.ndd-kit/lock")
done
for target in "${TARGETS[@]}"; do
  mkdir -p "$target"
  for name in "${NAMES[@]}"; do
    dest="$target/$name"; record="$target.ndd-kit/$name.receipt"
    stage=$(mktemp -d "$target.ndd-kit/stage.XXXXXX"); STAGES+=("$stage")
    src="$KIT_DIR/skills/$name"
    if [[ "$MODE" == link ]]; then ln -s "$src" "$stage/skill"
    else cp -R "$src" "$stage/skill"; fi
    digest=$(fingerprint "$src")
    [[ "$(fingerprint "$stage/skill")" == "$digest" ]] || fail "Copy verification failed: $name"
    printf 'ndd-kit-install\n%s\n%s\n%s\n' "$MODE" "$src" "$digest" > "$stage/receipt"
    mkdir -p "$target.ndd-kit/backups"
    backup=$(mktemp -d "$target.ndd-kit/backups/$name.XXXXXX")
    idx=${#DESTS[@]}
    DESTS+=("$dest"); BACKUPS+=("$backup"); RECEIPTS+=("$record")
    OLD_MOVED+=(0); RECORD_MOVED+=(0); NEW_INSTALLED+=(0); NEW_RECORDED+=(0)
    if exists "$dest"; then mv "$dest" "$backup/skill"; OLD_MOVED[$idx]=1; fi
    if [[ -f "$record" ]]; then mv "$record" "$backup/receipt"; RECORD_MOVED[$idx]=1; fi
    mv "$stage/skill" "$dest"; NEW_INSTALLED[$idx]=1
    mv "$stage/receipt" "$record"; NEW_RECORDED[$idx]=1
    echo "  Installed: $name"
  done
done
SUCCESS=1
printf '\nInstalled NDD. Use ndd-setup for readiness or ndd-init for optional project documents ($ in Codex, / in Claude Code).\n'
echo 'Restart the agent if the skills do not appear.'
