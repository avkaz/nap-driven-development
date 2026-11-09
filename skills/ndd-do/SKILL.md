---
name: ndd-do
description: Implement and verify all remaining tasks in an approved, current NDD plan, or one explicitly selected task. Invoke explicitly with ndd-do; do not start from an unapproved or stale plan.
argument-hint: "<feature id | path to plan.md> [task id]"
disable-model-invocation: true
---

# ndd-do

Respect applicable global, project and nested instructions (`AGENTS.md`,
`CLAUDE.md` and scoped rules), following the host's instruction precedence.
If an unresolved conflict blocks the requested work, explain the specific
contradiction and pause the affected work; do not silently bypass or rewrite rules.

By default, complete all remaining tasks in the approved plan in order, including
final verification. An explicit task id (for example `001 T2`) limits this invocation
to that task; do not silently execute its unfinished prerequisites. Honor an
explicit smaller scope or stopping point. Do not pause merely because a task ended.
A fresh session is optional; spec, plan and recorded evidence carry the context.

## Before editing

1. Read applicable instructions, the spec, plan and Git status if available.
   Follow the [project context and overview rules](../ndd-setup/references/project-context.md)
   for optional project documents, relevant changed constraints and progress.
   Reconcile a relevant context conflict before implementation; a matching task
   digest alone does not establish agreement with changed project rules.
   Reuse earlier findings; inspect code/tests relevant to the selected work and
   recheck changed files or uncertain assumptions instead of repeating broad scans.
   Preserve unrelated changes. A manifest or project templates are not required. If legacy NDD files exist, follow the
   [existing-project guidance](../ndd-setup/references/project-state.md).
   Resolve the feature with the shared
   [prefix and identifier rules](../ndd-setup/references/feature-ids.md): `001`
   uses the current user's confirmed prefix; a qualified id/full folder name/path
   selects an explicit feature. Report the resolved path and task id; explain
   missing feature files or task ids without creating setup files.
   If the spec is already done, report it (refresh a relevant existing overview
   entry from recorded evidence if needed) without implementation unless the user
   requests a new revision through `ndd-spec`.
2. Require spec status `approved` or `in-progress` and no unresolved
   `[NEEDS CLARIFICATION]`. Recompute the spec digest with the installed read-only helper:
   `bash <installed-skills>/ndd-plan/scripts/spec-digest.sh <spec-path>`;
   on Windows use `powershell -NoProfile -File <installed-skills>/ndd-plan/scripts/spec-digest.ps1 -Path <spec-path>`
   (`pwsh` when appropriate). Quote paths. These helpers hash the spec body,
   excluding frontmatter. This check does not require loading `ndd-plan/SKILL.md`;
   load that skill only when planning is requested. Require equality with the plan's `spec_digest`. Missing metadata,
   a failed helper or a mismatch blocks implementation; return to spec/plan
   review. Do not silently update the digest or grant approval yourself.
3. Require plan status `approved`. A clear approval of the displayed current
   plan in this conversation can be recorded now, after the digest check;
   a bare `ndd-do 001` is not retrospective approval.
   If all tasks are checked, honor an investigation-only plan's stopping point;
   otherwise perform outstanding final acceptance checks instead of inventing a task.
4. Start with the requested task or first unchecked one. Respect prerequisites;
   don't repeat a checked task without an explicit reason. State its AC scope
   (and R ids for legacy documents).
   Inspect verification commands for external effects before execution.
   Continue through remaining tasks without new approval within the approved
   scope. Before each task confirm the gates still hold; reuse the digest result
   only while the spec body is unchanged in this invocation. Re-read/recompute
   when documents change or work resumes in a new invocation. Stop for a genuine
   blocker, changed scope/approach, invalid approval/digest or an action requiring
   separate authorization, not for routine transitions.

## Implement and verify

- For investigation tasks, follow the shared
  [investigation and evidence rules](../ndd-setup/references/investigation.md).
  Run the planned checks and record findings before dependent implementation.
  Unsupported hypotheses and inconclusive checks leave the investigation open.
- Choose the verification method first. For bugs, reproduce the symptom and
  add a meaningful regression test where feasible. For other work, use suitable
  tests, builds, static checks or a documented manual check; do not manufacture
  a failing test for a documentation edit or already-covered behaviour.
- Implement the smallest coherent change. Keep existing architecture and
  dependencies unless an approved requirement justifies a change.
- Run focused checks during implementation and required project checks at the
  end. Reuse passing results while relevant code, dependencies, configuration
  and test inputs remain unchanged; rerun affected checks after relevant changes.
  Do not rerun an identical suite just to close another checkbox. Never skip
  required final checks, weaken tests or hide failures. Fix failures within scope;
  report unrelated blockers without changing unrelated code.
- On a behavioural contradiction, stop and propose a spec correction. Once
  approved, revise the spec and review the affected plan before continuing.
  Small implementation details within approved scope can go in Decisions.
  Changes to approach, scope, dependencies or external effects require review.
- Check off a task only when its required checks meet the planned outcome.
  A specific expected failure can establish a defect reproduction for an
  investigation task; it cannot establish a successful implementation. Record a
  concise result in the plan: task/AC, command or observation, outcome and relevant limitation.
  Include relevant tool/method deviations, not an inventory of routine tools.
  Use one short entry per check or group of tasks; update evidence without
  appending repetitive logs. Preserve useful failure details and prior results.
  If blocked, leave it unchecked and record what remains. Set the spec to
  `in-progress` when implementation starts. Refresh the relevant existing
  overview entry at that transition and when a blocker is recorded.
- An investigation-only plan stops at findings and the next planning step;
  record its evidence and task progress as usual unless explicitly read-only.
  Do not start unplanned implementation or mark its spec done.
- When all implementation-plan tasks are complete, verify every AC against the
  assembled feature, run required final project checks, and review the diff for
  unintended changes.
  Mark the spec `done` only when that evidence is recorded. Missing tools,
  unperformed manual checks or pre-existing failures are not passing results.
- Refresh relevant task links/statuses in an existing project overview before
  stopping, including after an explicit single task. Preserve partial progress:
  one finished task does not complete its spec or the whole capability. Follow
  the shared aggregation rules; do not rewrite product scope or create an overview.

Report briefly what changed, what was verified and what remains unresolved,
with a suggested commit message. Do not repeat the spec/plan or narrate routine steps.
Do not commit, push, deploy, change shared data or run production workflows
unless separately authorized. Recommend committing code and its spec/plan
updates together; with [private specs](../ndd-setup/references/private-specs.md),
recommend committing only the code. Stop after the requested task(s).

When a diagram helps explain a change or a blocker, use the
[rounded Unicode diagram style](../ndd-setup/references/diagrams.md).
