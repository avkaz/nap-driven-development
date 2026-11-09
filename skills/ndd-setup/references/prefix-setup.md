# Prefix setup and registration

## Choose and remember a prefix

Setup runs these commands in the project, never in the NDD source checkout:

- Read only the repository-local value: `git config --local --no-includes --get-all ndd.prefix`.
  Exit status 1 with no value means unset. Report other errors; do not silently
  treat unreadable or malformed configuration as missing.
- A valid prefix is 2–16 lowercase ASCII letters or digits, starting with a letter.
  It contains no spaces, punctuation or path separators. For an invalid value or
  multiple values, show the issue and propose an explicitly approved correction.
- Reuse a single valid saved prefix. Do not ask again or rewrite it merely because
  the Git author name changed. A requested prefix change affects new features only.
- When unset, read `git config --get user.name` and suggest a short prefix such as
  `ak` for Alexey Kazakov. This is a suggestion, not proof of a GitHub login. If
  the name is unavailable or cannot produce a useful prefix, ask for one; do not
  read email addresses, credentials or OS account details to fill the gap.
- Explain that the prefix separates teammates' feature numbers, appears in shared
  document paths and can be changed by the user before saving. Show any visible
  matching feature folders and ask whether this is their own prefix or belongs
  to a teammate. Do not automatically claim another person's namespace.
- Show the exact value and explain both writes: the existing local Git
  configuration and a machine-local project record in `~/.ndd/projects`. Full
  NDD uninstall will remove that recorded prefix if its value is unchanged. Ask the user to accept or supply a different value. Validate and
  save their explicit choice; no second confirmation is needed for a valid custom
  value when this storage behaviour was already explained.
- Save using `git config --local ndd.prefix ak` (substitute the validated choice),
  then read it back. Re-read before writing; if the value changed concurrently,
  reconcile with the user. Do not rewrite the whole config, alter `user.name`,
  change global Git settings or create a tracked config file. If saving fails,
  report it; never claim that the next session will remember an unsaved value.

The key lives in the clone's existing Git config, normally `.git/config`. It is
shared by both agents in that clone and by linked worktrees, but is not committed
or pushed. A new clone/computer needs its own confirmation; recommend the same
prefix for the same person. Installation does not edit Git config; full uninstall
cleans up only registered, unchanged local `ndd.prefix` values.

Outside a Git repository, explain that the choice can only last for the current
conversation. Offer to use a confirmed prefix for that session; do not initialize
Git or create a fallback settings file. A declined choice produces no writes.

## Register the project after setup

After verifying the saved prefix (including a previously configured project),
run the helper from this loaded `ndd-setup` skill. Use its actual absolute path;
do not depend on the source checkout still existing. These helpers register an
already-saved value; they do not choose or change the prefix.

On macOS/Linux:

```bash
bash /path/to/ndd-setup/scripts/project-registry.sh register --project /path/to/project --prefix ak
```

On Windows:

```powershell
& 'C:\path\to\ndd-setup\scripts\project-registry.ps1' -Action Register -Project 'C:\path\to\project' -Prefix ak
```

Quote actual paths with spaces. Substitute the verified prefix. No second prompt
is needed when the user already confirmed the described setup. An existing valid
prefix can be registered on repeat setup without asking to choose it again.
If registration fails, report incomplete setup and the saved Git value; do not
claim that automatic uninstall cleanup is available or delete the saved value.

The shared registry is `~/.ndd/projects` on both agents. `NDD_STATE_DIR` overrides
its parent directory for isolated installations/tests; use the same override
for setup and uninstall. Do not create an alternative project-local registry.
Each record stores the project path, canonical common Git directory, the exact
key `ndd.prefix`, and its value. Linked worktrees share one record. Repeat setup
updates a changed confirmed prefix but does not rewrite an unchanged record.
No registry record is created for a session-only choice outside Git.

Full uninstall (both agents selected) cleans these records before removing
skills/state/source, together with each project's
[private specs](private-specs.md) settings. A missing prefix is already clean; an unavailable repository,
changed/multiple values, invalid record or Git write failure retains the record
with a warning and proceeds to the next project. NDD removal continues even if
some prefixes remain. A locked/unreadable registry or missing cleanup helper is
also reported and skipped; its data is left intact. Single-agent uninstall keeps
shared project settings and the registry. Moved repositories need setup again;
inspect and resolve stale records explicitly rather than scanning the machine.
