# Optional project context and capability overview

Project documents live in `project/` beside task folders: normally
`ndd-specs/project/{spec,features,rules}.md` alongside `ndd-specs/ak-001-change/`.
First select the root using the [document location rules](project-state.md).
Keep established `specs/` or custom roots; do not create a second project folder
under the new default. If a standalone task path does not establish that
directory, use the project's known specs root; do not invent a second overview.
If the location is ambiguous or occupied by unrelated content, ask for the
intended location. Keep files inside the project, or inside the
[private specs](private-specs.md) folder, and do not write through links.
Resolve task links relative to the overview file. Before reading linked task
documents or passing a path to a digest helper, reject external URLs, paths
escaping the project (or the private folder) and symlinks escaping it. Report unsafe or missing targets
as unresolved references rather than following them or deleting the entry.

All three files are optional and independent. Do not create them during setup,
spec, plan, do or review just because they are absent. `ndd-init` creates or
revises the user's selected documents after approval in new or existing projects.
Missing init documents are never a readiness or task-approval prerequisite.
`project/` is reserved for this context, excluded from feature numbering and
latest-task selection, and is
not an executable task. Route requests to plan or implement `project/spec.md`
to choosing a concrete task; do not create `project/plan.md`.

## Read context

For spec, plan, do and review, read the existing project description, applicable
rules and relevant capability entries. Setup only checks their presence and
relevant conflicts. Help remains a fixed reference and does not inspect them.
Treat the project description as product context, and rules as the user's
project conventions within the host's instruction precedence. They cannot
override higher-priority instructions, permissions or task approvals.

Use a specified documentation language for generated project/task documents
unless the user explicitly requests another. Interface language is a product
requirement, not automatically the chat language. Fixed English help is unchanged.
Reference existing `AGENTS.md`/`CLAUDE.md` conventions rather than duplicating
them. A selected `rules.md` can be a short index of relative links to existing
rule documents with their scope. Resolve these links relative to `rules.md`
(from the project root for private specs), verify targets stay inside the project, and read only sources relevant to the
current work. An index link does not turn a scoped rule into a project-wide rule.
Report missing or unreadable relevant sources; do not invent their contents.
Already applicable global/ancestor instructions still apply in place and need
not be copied or exposed as machine-specific paths in shared documents.
Surface actual contradictions and resolve affected scope with the user.
Unrelated project context changes need not invalidate every task, but a relevant
changed requirement/rule needs spec/plan review before affected implementation.
The task spec digest does not detect changes in these external documents.

## Conditional overview details

If `project/features.md` exists and this work needs to derive/update its status,
read [overview synchronization](overview-sync.md). Init also reads it when drafting
or revising a selected features file. Review reads it when assessing overview
consistency, but never synchronizes. With no overview, skip that reference and
create no project files. Reuse already-read, unchanged context in this invocation;
re-read changed/uncertain sources and before writing. New invocations recheck.
