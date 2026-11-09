---
name: ndd-review
description: Review an NDD specification, plan or implementation against its task documents. Invoke explicitly with ndd-review; report findings in chat and offer optional saving without fixing code or granting approvals.
argument-hint: "[feature id | feature document path] [spec | plan | code]"
disable-model-invocation: true
---

# ndd-review

Respect applicable global, project and nested instructions (`AGENTS.md`,
`CLAUDE.md` and scoped rules), following the host's instruction precedence.
If an unresolved conflict blocks the requested work, explain the specific
contradiction and pause the affected work; do not silently bypass or rewrite rules.

Review in the user's language, respecting applicable project instructions.
Read relevant optional context using the
[project context and overview rules](../ndd-setup/references/project-context.md).
Report material conflicts or stale overview entries without updating them. This
command reviews task specs/plans/code, not the project folder as an executable task.
Review is optional and is allowed for draft, in-progress and done features.
It never grants approval or replaces verification in `ndd-do`.

## Select the feature and stage

1. Read the [feature ID rules](../ndd-setup/references/feature-ids.md) and,
   when applicable, [existing-project guidance](../ndd-setup/references/project-state.md)
   from this loaded installation. Report missing required resources; never borrow
   them from another installation or the source clone.
2. Accept an optional feature and an optional `spec`, `plan` or `code` mode in
   either order: `001 spec` and `spec 001` are equivalent. A mode alone is valid.
   Preserve paths with spaces as one feature argument. Clarify conflicting or
   ambiguous arguments. Reject an unknown mode with the three allowed values;
   do not interpret a missing explicitly selected feature as permission to choose another.
3. Resolve an explicit feature using the shared rules: bare number with the
   confirmed prefix, qualified ID, full folder name or feature document path.
   Require one match. Keep the resolved feature inside the current project;
   reject paths escaping it, including through links. Do not scan unrelated roots,
   create missing documents, guess a prefix or change Git settings.
4. Without a feature, select the largest **numeric** number for the current
   confirmed prefix in the project's specs location. For `ak`, prefer `ak-010`
   over `ak-009`, ignoring `iv-100`. Do not use timestamps or directory order.
   Show its ID, title and path and ask whether to review it; wait for confirmation.
   If multiple features share the maximum number, list candidates and ask for an
   explicit full name/path. If there is no prefix, ask for a qualified ID or setup;
   if there are no matching specs, report that and offer explicit selection or
   `ndd-spec`. Refusal or silence does not authorize analysis. An unambiguous
   explicit feature needs no additional selection confirmation.
5. Every mode requires `spec.md`; if it is missing, report that and stop.
   Honor an explicit mode. Otherwise inspect the feature's documents and evidence
   of implementation: spec only → `spec`; spec and plan without implementation →
   `plan`; spec, plan and related implementation → `code`. Partial implementation
   can be reviewed with its boundaries stated. An old codebase, checked task,
   `done` status or clean Git diff alone does not prove implementation. If the
   stage or implementation boundary is unclear, ask a specific question.
6. Before analysis, report the resolved feature path, mode and scope. For code,
   use the user's selected files/change/range and relevant project evidence.
   Never equate the entire working diff or latest commit with this feature by
   default. Clarify mixed changes or an unclear comparison base. Outside Git,
   review explicitly selected files and note the lack of history.

Accept compact specs with AC ids only and plans with AC coverage directly in
tasks. Missing R ids, a coverage table or optional sections are not defects.
Also support existing longer R/AC documents without requiring conversion.
Judge missing behaviour or verification, not document length or template shape.

## Analyze without changes

Read relevant documents, code and tests; use only read-only inspection commands.
Do not execute tests, builds, installs, project scripts, hooks or other commands
with side effects. Do not edit code, spec, plan, task checkboxes, approvals,
configuration or instruction files. No commit, push or automatic fixes. Only
saving the displayed report after the separate choice below may write a file.

- **spec:** Check clarity, contradictions, boundaries, material edge cases and
  testable acceptance criteria against the relevant project context.
- **plan:** Require spec and plan. Check coverage of requirements and acceptance
  criteria, dependencies, verification, feasibility and unnecessary complexity.
  If a document is missing, stop this mode without creating it.
- **code:** Require spec and plan for an NDD conformance review. If either is
  missing, report the limitation without a conformance conclusion. Review the
  selected implementation and tests against both: defects, regressions, error
  paths, concrete security risks and verification gaps.

When a plan is present, recompute the spec body digest with this installation's
[read-only Bash helper](../ndd-plan/scripts/spec-digest.sh) on macOS/Linux or
[PowerShell helper](../ndd-plan/scripts/spec-digest.ps1) on Windows. Pass the
quoted spec path (PowerShell uses `-Path`). Compare it with `spec_digest`.
A missing/failed helper, absent metadata or mismatch is an explicit limitation;
never invent or update the digest. Flag missing approvals and unperformed checks.
These do not prevent reviewing a draft, but they are not successful gates.
Distinguish previously recorded test results from checks performed now;
review itself does not run tests.

## Report and offer saving

Show the report in chat first: feature, mode, checked scope, result and limitations.
Order confirmed findings by severity. Each finding needs a stable `F1`, `F2`, …
identifier, severity, concrete scenario and consequence, document/code location,
verification method, and R/AC linkage where relevant. Use `[ ]` for open findings.
Separate hypotheses, missing evidence and optional suggestions from defects.
Do not present stylistic preferences without practical consequences as defects.
When none are found, say "No confirmed problems found in the reviewed scope",
not a guarantee of correctness.

Then offer to save `review.md` beside the selected spec and plan, or leave the
report in chat. If a report already exists, offer **replace**, **extend**, or
**do not save**; a generic yes does not authorize replacing existing content.
No answer means no write. For a confirmed save, use the bundled
[report template](assets/review.md) and follow the
[report update rules](references/report-updates.md). After saving, give the path
only; do not repeat the report. Missing saving resources
leave the report in chat with an incomplete-installation notice.

When a diagram helps explain a finding, use the
[rounded Unicode diagram style](../ndd-setup/references/diagrams.md).
