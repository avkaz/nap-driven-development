# Project setup

Run `/ndd-setup` in Claude Code or `$ndd-setup` in Codex, inside your project.
It checks project rules, installed skills and available verification commands,
then confirms a personal prefix for feature names.

`ndd-help` works before setup too, including outside Git, and writes nothing.
Use `/ndd-help` in Claude Code or `$ndd-help` in Codex.

After setup, any new or existing project can optionally use `ndd-init` to capture
its goals, capabilities and/or links to existing rules; see
[project context](init.md). It creates only the documents you choose and approve.
You can always skip init and use `ndd-spec` for the next change. Setup reads
existing project context without creating or updating it.

## What setup changes

After you confirm a prefix, setup saves `ndd.prefix` in the repository's local
Git config and records the project and value in `~/.ndd/projects`. Both agents
share these settings. Neither is committed or pushed. If you choose
[private specs](#private-specs), setup also makes the local changes listed there.

Setup creates no tracked project files, instruction blocks, templates or empty
specs folders. Existing `AGENTS.md` and `CLAUDE.md` stay unchanged unless you
approve a specific fix for a real conflict. Project checks are inspected, not run.

Repeat setup reuses a valid saved prefix. If its registry record is missing,
setup adds it; unchanged settings and records are left alone. A save or registration
failure is reported rather than treated as successful setup.

## Your prefix

Setup suggests a prefix from your Git author name, or asks you to supply one.
Use 2–16 lowercase letters or digits, starting with a letter, such as `ak`.
Choose different prefixes for teammates.

With `ak`, new features are named `ak-001-feature`, `ak-002-feature`, and so on.
`ndd-plan 001` and `ndd-do 001` select your feature; `ndd-plan iv-001` explicitly
selects another prefix. You can also give the full feature path. Ambiguous matches
require clarification.

A new clone needs setup again; you can use the same personal prefix. Changing
it affects future features and does not rename existing documents.

## Without Git

Installing the skills does not require a project repository or create Git config.
When setup runs outside a Git repository, it offers a prefix for the current
conversation only. It does not initialize Git, create a config file or register
that session-only choice. An unreadable existing config is reported as an error.

## Task documents

New NDD work defaults to `ndd-specs/`. An established NDD root in `specs/` or a
project-specific location is reused without moving files. An unrelated `specs/`
does not block the new default. If both roots contain NDD work, setup asks which
to use; explicit task paths remain available.

The first `ndd-spec` creates `ndd-specs/PREFIX-NNN-feature/spec.md`;
`ndd-plan` adds `plan.md` beside it. Optional `ndd-review` can save `review.md` there after
your choice. These ordinary project files can be committed unless ignored.
Compact templates come from the installed skills; existing longer documents
remain supported without migration. Updating NDD does not rewrite existing
documents.

If your project uses another location, provide an explicit feature path.

## Private specs

On the first setup in a Git repository, setup asks whether specs are **shared** or
**private**. Shared is the default described above: specs live in `ndd-specs/`
and are committed with the code. Choose private when you use NDD for yourself in a
team repository and your specs must not reach the shared repository.

Private mode keeps all specs in one folder outside the project,
`~/.ndd/specs/<project>`, and makes these local changes:

| Change | Where | Committed |
|---|---|---|
| Path to the private folder | `ndd.specsRoot` in local Git config | no |
| `/ndd-specs` ignore line | `.git/info/exclude` (not `.gitignore`) | no |
| `ndd-specs` link to the folder, for your editor | project root | no (ignored) |

All NDD commands read and write that folder directly. Because it is outside the
project, the same specs stay with you when you switch branches, and `git clean`
cannot delete them. Specs are not part of your commits or pull requests.

A linked worktree (`git worktree add`) shares the setting, so NDD works there at
once; only the `ndd-specs` link is missing. Run setup in the worktree to add it.
A new clone or computer needs setup again; it offers to reuse the existing folder.
Setup does not install Git hooks for this, because team hook managers such as
Husky (`core.hooksPath`) or Git LFS can silently skip or conflict with them.

Projects that already commit NDD documents stay shared. Repeat setup reports the
current mode; ask it explicitly to switch an existing project to private specs.
Full uninstall removes the setting, links and ignore line, and asks whether to
delete the private folder; see [uninstall](installation.md#uninstall).
Setup reports actual conflicts with project rules and suggests a resolution;
it does not replace those rules or change permissions to make NDD work.

Next: [workflow and approvals](workflow.md).
