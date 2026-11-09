# Installation options and troubleshooting

Start with the [installation, update and uninstall commands](../README.md#install).
This page covers custom locations and problems you may encounter. Project
registration uses Git 2.31 or newer.

## Find your NDD folder

The README's download commands use `nap-driven-development` in your home folder.
These commands open it from any terminal location:

**Mac:**

```bash
cd "$HOME/nap-driven-development"
```

**Windows:**

```powershell
Set-Location -LiteralPath "$env:USERPROFILE\nap-driven-development"
```

If you downloaded NDD elsewhere or extracted a ZIP, substitute its actual path.
Look for the folder containing `install.sh`, `install.ps1` and `skills/`.
If the path does not exist, locate that download in Finder/File Explorer before
continuing. A machine-wide search can find several clones or old ZIP copies;
there is no unique universal path for existing downloads. These instructions
do not move your existing copy or create a global command.

Install, update and uninstall use this NDD source folder. Run chat commands such
as `ndd-setup` and `ndd-init` in your own project instead.

## Options and locations

| Bash | PowerShell | Meaning |
|---|---|---|
| `--codex` | `-Codex` | Install for Codex |
| `--claude` | `-Claude` | Install for Claude Code |
| `--all` | `-All` | Select both agents |
| `--dry-run` | `-DryRun` | Preview without changes |
| `--replace` | `-Replace` | Accepted for compatibility; replacement is automatic |
| `--uninstall` | `-Uninstall` | Remove NDD for the selected agents |
| `--keep-source` | `-KeepSource` | Keep the source clone during uninstall |
| `--link` | `-Link` | Link skills to this checkout for development |
| `--codex-dir PATH` | `-CodexDir PATH` | Select a custom Codex skills directory |
| `--claude-dir PATH` | `-ClaudeDir PATH` | Select a custom Claude skills directory |

Defaults are `~/.agents/skills` for Codex and `~/.claude/skills` for Claude Code.
`CLAUDE_CONFIG_DIR` changes the Claude configuration root. `CODEX_HOME` helps
agent detection but does not change the Codex skills destination.

Custom paths must be actual directories your agent loads. Use the same paths
for updates and uninstall. For redirected parent folders, pass the real path;
the installer refuses to follow parent symlinks or junctions.

Link mode loads skills directly from the checkout, so pulling changes updates
what the agent uses immediately. Keep that checkout in place. Normal installation
copies the skills and works without the downloaded folder.

## Windows execution policy

If Windows blocks a script you have inspected, use this process-only override
with your chosen target (`-Codex`, `-Claude` or `-All`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -All
```

This does not change persistent policy. On a managed computer, follow your
organization's installation policy.

## Replacing existing skills

Install and update automatically replace all seven NDD skill directories at the
selected destinations, including local edits and existing directories without
receipts. Unrelated skills and project files are preserved. Use `--dry-run` /
`-DryRun` to preview. The old `--replace` / `-Replace` option is no longer needed.

Receipts live beside the skills directory in `<skills-directory>.ndd-kit`.
Successful installs retain no backups and delete backups left by earlier installations.
Previous skills and receipts are held temporarily under `backups/` only to restore
them if installation fails. Failed recovery retains these files for manual repair.
Uninstall deletes all installation state; an existing skill without valid ownership
information still blocks uninstall.

## Interrupted installation or removal

1. Make sure no installer is still running.
2. Inspect the reported paths and backups. For an interrupted update, restore the
   affected skill and its matching receipt if needed; preserve any newer edits.
3. Remove a stale `lock` in `<skills-directory>.ndd-kit` only after confirming
   no installer is active. Keep staging files until recovery is complete.
4. Preview again, then retry. On Windows, close processes holding files in a
   source clone that could not be removed.

## Uninstall

Use `--uninstall` / `-Uninstall` with your original agent and destination options.
Removal deletes selected NDD skills (including local edits) and their
`<skills-directory>.ndd-kit` metadata. It preserves agent applications, project
files and unrelated skills.

Single-agent removal keeps the other agent's installation, the source folder and
project prefix registry. Full removal (`--all` / `-All`) also cleans registered
project prefixes and may delete the running source clone, as described below.
Use the same `NDD_STATE_DIR` used during setup if it was customized.

Earlier installations included a terminal `ndd-help` command. Updating removes its
launchers; remove any manually added `ndd-help/scripts` PATH entry yourself.
Chat help remains available as `$ndd-help` or `/ndd-help`.

## Source clone cleanup

Full uninstall can delete only the clone containing the running installer.
It must be a standalone clone of `avkaz/nap-driven-development`, with Git available,
no local changes (including untracked or ignored files), no linked worktrees and
no unpublished history, stashes or reflog entries. The check uses local
remote-tracking refs; it does not fetch. Hidden index changes also prevent cleanup.

ZIP folders, forks and clones that fail these checks are kept with a reason.
Other downloads are never searched. Use `--keep-source` / `-KeepSource` to keep
the clone intentionally. Preview shows the source path and proposed action.

## Project registry

Setup records each project's location and saved prefix in `~/.ndd/projects`.
Full uninstall removes only the registered local `ndd.prefix` value when it still
matches. Failed or inaccessible entries are kept with a warning, and removal
continues. Single-agent uninstall keeps the registry and project settings.

For projects with [private specs](setup.md#private-specs), full uninstall also
removes `ndd.specsRoot`, the `ndd-specs` links in every worktree of the repository
and the `/ndd-specs` line in `.git/info/exclude`. It then asks whether to delete
the private specs folder permanently. Answer `y` to delete it; any other answer,
or running without a terminal, keeps the folder and prints its path. Only a
folder directly inside `~/.ndd/specs` is ever deleted. Preview lists these actions
without asking or changing anything.

Successful records are removed, followed by the registry folders if empty.
Moved projects need setup again; stale records may need manual cleanup.
`NDD_STATE_DIR` overrides `~/.ndd`; use the same value for setup and uninstall.
