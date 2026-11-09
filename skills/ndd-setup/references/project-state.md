# Existing projects and output locations

New NDD projects need no manifest, instruction block or project-local template.
The default document location is `ndd-specs/PREFIX-NNN-feature-slug/{spec,plan}.md`, created
only when a task specification is requested. Optional `project/` documents live
beside task folders; follow [project context rules](project-context.md). Task specs
and plans use the installed kit's `ndd-setup/assets` templates; generated task documents are independent of
the templates afterwards. Updating NDD does not rewrite those documents.
The confirmed personal prefix is a local Git setting, not a tracked project file;
see [prefixes and feature identifiers](feature-ids.md).

## Choose the document root

Use the same root for setup, init, spec, plan, do and review:

0. Read `git config --local --no-includes --get ndd.specsRoot`. A saved value selects
   the [private specs](private-specs.md) folder for every command, including
   `project/`. Report a read error or missing folder; never fall back to
   `ndd-specs/`. If this worktree lacks the `ndd-specs` link, remind once to run
   `ndd-setup`; do not create it.
1. Honor an explicit safe document path or root selected by the user, and the
   project's applicable location instructions. An explicit existing task path
   selects its containing root for related project context; it does not move files.
2. Otherwise honor an existing legacy manifest's location using [legacy compatibility](legacy-project.md).
3. Without a selected location, inspect `ndd-specs/` and `specs/` only enough to
   identify existing NDD work. Use task metadata/content and NDD context already
   established by the user or project instructions; a folder name, `spec.md` or
   `project/` alone is not evidence of NDD ownership. Preserve recognizable
   legacy NDD tasks even when they lack current approval metadata.
   If exactly one root contains established NDD work, keep using it, including
   `specs/`. Existing project context alone can establish a root when its NDD
   purpose is clear. If both contain NDD work or ownership is uncertain, ask for
   the root or full task path before creating documents or resolving short IDs.
4. With no existing NDD root, use `ndd-specs/`. An unrelated `specs/` is left
   untouched and does not block this choice. If `ndd-specs/` itself is occupied
   by unrelated content, ask for another project-relative location.

Report the selected root and reuse it within the task. Number and resolve tasks
only in that root; do not merge roots or fall back to the other after a missing
ID. Init's `project/` folder and overview updates use the same root as the task.
Do not create a manifest or remember a root in new configuration; private mode's
`ndd.specsRoot` is the only saved root. Existing
documents, IDs, links and templates remain in place; renaming or moving them
requires a separate explicit request.

Read [legacy compatibility](legacy-project.md) only when `.ndd-kit.json`,
legacy templates/instruction blocks, unprefixed tasks, old plans missing approval
metadata, or an uninstall question are actually encountered. Do not load it for
an ordinary current-format task. Do not move, migrate or delete legacy files.
