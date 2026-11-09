# Private specs

Private mode keeps NDD documents out of the shared repository. They live in one
folder outside the project, found through local Git config, and appear in the
project through an ignored `ndd-specs` link for the user's editor. All branches
and linked worktrees of the clone use the same folder.

## Ask once

On the first setup in a Git repository (no saved `ndd.prefix` and no
`ndd.specsRoot`), after the prefix, ask whether specs are **shared** (default:
`ndd-specs/` inside the project, committed with the code) or **private** (only on
this machine, never committed). Shared mode writes nothing extra. On repeat setup,
report the current mode and switch only when the user asks. Private mode needs Git.

Do not enable private mode when the project already tracks NDD documents in Git;
the team uses NDD in the repository, so explain that instead. Untracked NDD work
in `ndd-specs/` can move into the private folder after explicit approval; never
overwrite existing files during the move.

## Enable

Explain all writes below, then perform them after confirmation:

1. Folder: `~/.ndd/specs/<repository-folder-name>`. `NDD_STATE_DIR` replaces
   `~/.ndd`, as for the registry. The name is one path segment of letters, digits,
   `.`, `_` or `-`. If the folder exists, ask whether it holds this project's
   specs (for example, from an earlier clone) and reuse it, or choose another name.
2. Save its absolute path with `git config --local ndd.specsRoot '<path>'`, using
   forward slashes on Windows, and read it back.
3. Add a `/ndd-specs` line to `info/exclude` in the common Git directory
   (`git rev-parse --git-common-dir`) unless present. Never edit `.gitignore`.
4. Create the link in the worktree root, unless `ndd-specs` already links to the folder:
   - Windows: `New-Item -ItemType Junction -Path '<project>\ndd-specs' -Target '<folder>'`
   - macOS/Linux: `ln -s '<folder>' '<project>/ndd-specs'`

   If anything else occupies `ndd-specs`, stop and ask.
5. Register the project as described in [prefix setup](prefix-setup.md); full
   uninstall finds private specs through that record.

## Repeat setup

With `ndd.specsRoot` saved, verify the folder exists and recreate a missing link or
exclude line without asking again; leave the config unchanged. This covers a new
linked worktree, where the link is absent. A new clone runs setup again and reuses
the existing folder by name.

## Working with private specs

Commands read and write the folder from `ndd.specsRoot` directly, never through the
link. A user path through `ndd-specs/` maps to the same path inside that folder.
Links from private documents to project files are resolved from the project root.
Private documents are not in the repository: do not recommend committing them or
reference their paths in code, commits or pull requests.

## Uninstall

Full uninstall removes `ndd.specsRoot`, `ndd-specs` links to the folder in every
worktree of the repository and the `/ndd-specs` exclude line. It then asks whether
to delete the folder itself; without an answer (no terminal), the folder is kept
and its path reported. Only a folder directly inside `~/.ndd/specs` can be deleted.
