---
name: ndd-setup
description: Check project readiness for NDD and confirm a personal feature prefix saved in local Git config. Invoke explicitly with ndd-setup; preserve existing instructions and get approval before saving a prefix or resolving a blocking conflict.
disable-model-invocation: true
---

# ndd-setup

Respect applicable global, project and nested instructions (`AGENTS.md`,
`CLAUDE.md` and scoped rules), following the host's instruction precedence.
If an unresolved conflict blocks the requested work, explain the specific
contradiction and pause the affected work; do not silently bypass or rewrite rules.

Check readiness for the explicitly invoked NDD workflow and confirm a personal
feature prefix. Inspection is read-only; after confirmation, save the prefix
in local Git config and register the project in the shared NDD registry. Do not
create instruction blocks, imports, project templates, a manifest or an empty
specs folder; only confirmed private mode creates its folder and link. Task documents start with `ndd-spec`; optional project documents
start with `ndd-init`.
Invoke `ndd-setup` without flags.

This skill contains the standard `assets/spec.md` and `assets/plan.md`.
The other six NDD skills are siblings. Review also bundles its own report
template; help provides a short reference without requiring setup. Use this loaded
kit's actual location; never silently combine resources from different installations. Bundled
assets are the only templates: do not copy them into projects or select custom
project templates. If resources are missing, report the incomplete installation.

## Inspect

1. Identify the running agent, loaded kit location and project root (Git root when
   available, otherwise the current folder). Report relevant local changes.
   Do not initialize Git or create a branch.
2. Read applicable project/ancestor instructions and relevant scoped rules,
   overrides and imports. Read existing `AGENTS.md`/`CLAUDE.md` in place. Do not
   create or edit project or global instruction files simply to enable NDD.
3. Inventory relevant installed skills and command metadata, including duplicate
   NDD installations or other SDD tools. Read full bodies only to investigate a likely
   conflict. Inspect instruction/skill-loading settings and known user guidance
   in the configured agent homes. Directory presence alone does not prove that
   a skill loads. Report unavailable settings as unverified.
4. Inspect the project's documented test/build/lint commands without running
   jobs, hooks, migrations or installers. Do not scan auth caches, secrets,
   `.env`, conversation history or unrelated global files. Never dump environment
   variables or entire configuration files.
5. Select the output root with the
   [document location rules](references/project-state.md): default `ndd-specs/`,
   retaining an established `specs/` or custom root without moving documents.
   Resolve ambiguous roots or unrelated content before selecting a location.
   Setup leaves absent directories uncreated; init or the first task may create them.
   Preserve existing manifests, instruction blocks and copied templates.
   Check optional project documents using the
   [project context rules](references/project-context.md); do not create or synchronize them.

## Choose a personal prefix

Follow [prefix selection and feature identifiers](references/feature-ids.md).
Read the saved local `ndd.prefix`; if absent, suggest a prefix from the Git author
name. Explain its purpose, show the exact value and local storage, and let the user
accept or choose their own. Explain that setup also records the project and
prefix in `~/.ndd/projects` for cleanup during full uninstall. Save only their
confirmed choice, then use the bundled registry helper as described in the prefix
reference. Reuse an existing valid choice without rewriting Git config, and
register it if missing. Report registration failures as incomplete setup.

## Choose shared or private specs

Follow [private specs](references/private-specs.md). On the first setup in a Git
repository, ask whether specs are shared (committed with the code, the default)
or private (kept outside the repository on this machine). Private mode saves
`ndd.specsRoot`, adds a local exclude line and an `ndd-specs` link. Repeat setup
restores a missing link or exclude line without asking again.

## Resolve actual conflicts

Distinguish blocking contradictions from optional preferences. If the project's
rules allow the NDD workflow, its instructions need no edits. An existing stack,
formatter, testing framework or another SDD tool is not automatically a conflict.
NDD must respect project rules; its installation does not override them.

Prefer a compatible way of working, such as an explicitly requested output path,
over editing shared instructions. Show any real contradiction with a concise
quote, its effect and a recommended resolution. Do not edit a project's rules,
permissions, global guidance, hooks or agent configuration to bypass it.

If the user chooses an instruction edit to resolve a genuine blocker, first show
the exact minimal diff and obtain approval. Re-read before applying it; ask again
only if the proposed result materially changed. Preserve unrelated text and local
work, verify the approved diff, and report the change. No general NDD block or
personal global reminder is required.

## Report

State:
- whether NDD is ready, blocked, or partially unverified;
- which installed templates and output location will be used;
- the confirmed prefix and whether it was saved locally, reused or is session-only;
- shared or private specs, with the private folder and link status;
- any actual conflict and unresolved checks;
- exact changes, including registry status, or that nothing was written;
- the next invocation: `ndd-spec <idea>` for a task, or optional `ndd-init` to
  discuss project purpose, capabilities or rules (`/` in Claude Code, `$` in Codex).

A readiness report is not approval of a future spec or plan. Skills perform the
workflow when explicitly invoked; normal coding requests need not use NDD.
Repeated setup with an unchanged prefix and existing registry record must not
rewrite config or the record. Never commit or install globally.

When a diagram helps explain a conflict or workflow, use the
[rounded Unicode diagram style](references/diagrams.md). Skip diagrams that add no value.
