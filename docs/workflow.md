# Workflow and approvals

Each task (a feature, bug or other change) has two core files: `spec.md` describes
the agreed behaviour; `plan.md` contains implementation tasks, progress and
verification results.

| Step | What happens |
|---|---|
| `ndd-setup` | Check readiness and confirm your task prefix |
| `ndd-init [idea or request]` | Optional, new or existing project: capture goals, capabilities and rules |
| `ndd-spec <idea>` | Write or revise the spec and resolve open questions |
| Approve the spec | Confirm the current requirements in chat |
| `ndd-plan <id>` | Create a technical plan with tasks and checks |
| Approve the plan | Confirm the current approach and task scope in chat |
| `ndd-do <id>` | Complete all remaining approved tasks and verification |
| `ndd-help` | Show commands, workflow and ID rules, with no setup required |
| `ndd-review [feature] [mode]` | Optional review of spec, plan or implementation |

Workflow: setup → init (optional, any project) → spec → approve → plan → approve → do + verify.
Init can be skipped in any project; its documents are not a prerequisite for task work.

Use `/` before commands in Claude Code and `$` in Codex. A short id such as `001`
uses your [setup prefix](setup.md#your-prefix); a qualified id or full path selects
an explicit feature.

New NDD work uses `ndd-specs/`. Existing NDD documents in `specs/` or an explicitly
selected root remain supported without migration. Commands use one selected root
for tasks and project context; with multiple NDD roots, specify the root or full
task path. Short IDs and latest-task review do not merge results across roots.

The agent records your approval in the documents. Calling the next command alone
does not approve a draft. An explicit “approve this plan and implement it” can
cover both actions without another confirmation.

After presenting a spec ready for approval, the agent offers **Approve spec and
continue with Plan <id>**, using the resolved feature ID. Selecting it records
spec approval and starts `ndd-plan` for that feature. **Approve spec only** saves
approval without starting a plan; the agent then offers **Continue with Plan <id>**.
**Request changes** keeps the spec unapproved. Interactive choices appear where
the host supports them; otherwise a short chat reply selects the action.
No selection means no approval or transition. Planning still ends with a separate
plan approval; continuing does not authorize implementation.

## Optional project context

For a new or existing project, optional `ndd-init` can create any combination of
`ndd-specs/project/spec.md`, `features.md` and
`rules.md`, beside task folders. It first discusses the need, recommends documents,
then shows the chosen drafts for one approval. Rules-only and overview-only
requests are valid. For an existing project, the agent studies relevant documents
and code, summarizes its understanding and asks about material gaps. Existing
rules are linked from a selected `rules.md`, preserving their original scope.
Repeating init preserves unselected documents and task paths.
[See the init conversation and examples](init.md).

Spec, plan and do use existing project context and synchronize related task
links/statuses in an existing overview as part of their work. They do not create
a missing overview or change product scope, stages or rules. Review reports
inconsistencies without synchronization. Progress is derived from task documents
and verification; completion requires coverage of the whole described capability.
Manual edits are picked up on later relevant invocations, not by a background job.

`project/` is excluded from task numbering and latest-task selection. Its spec
is not an executable task and cannot be passed to plan/do as an implementation
plan. Choose a concrete feature, bug or other change instead.

## Compact documents

For an ordinary task, the spec is a goal plus an AC checklist, usually 150–300
words or fewer. Criteria include observable behaviour and relevant edge/failure
cases; there is no separate repeated requirements list. Add exclusions or open
questions only when needed.

The plan is a short approach plus tasks and checks, usually 100–250 words or fewer.
Each task names its AC coverage and verification, so no separate coverage table is
needed. Risks, rollback and decisions appear only when material. These are length
guidelines, not quotas: complex changes can need more detail. Existing R/AC specs
and longer plans remain valid without conversion or renumbering.

Keep simple tasks on one line. For longer tasks, use a short title and action
bullets under the task's checkbox, followed by verification. Number substeps only
when their order matters. An optional Tools/method bullet names consequential
choices such as browser automation, database access or bounded fixture capture;
omit it when the actions or verification already explain the method. Use verified
tools, flag availability gaps, and avoid empty fields or inventories of routine
file reading/editing. Results record checks, outcomes, relevant deviations and
limitations. The [CSV export plan](../examples/002-csv-export/plan.md) shows both
one-line and expanded tasks.

Spec creation inspects current behaviour; planning explores implementation details.
Implementation reuses those findings and rechecks changed files and assumptions.
Saved specs and plans are not pasted into chat: the agent gives the file path and
a few key points for approval. Ask for a section if you want it in chat.

## Investigation when needed

Add investigation only when an unresolved question could change the requirements
or approach. Resolve planning uncertainty with a bounded experiment, or propose
an investigation-only plan if substantial work is needed. When the approach is
credible but needs confirmation, make investigation the first task:

```markdown
- [ ] T1 (AC1): **Determine why quoted CSV fields are split incorrectly**
  - Exercise the existing parser with a sanitized quoted-comma fixture.
  - Tools/method: existing parser tests; an isolated scratch probe if needed.
  - Verify: record the command, fixture, expected and actual fields, and the
    finding supported by the result. Reproduce the specific failure before fixing it.
- [ ] T2 (AC1): **Correct quoted-field handling**
  - Depends on T1 supporting the planned approach; revise the plan if it does not.
  - Verify: the regression fixture and required project checks pass after the fix.
```

Reasoning identifies hypotheses; executed checks or actual recorded observations
support testable findings. A script's existence or exit code alone is insufficient.
Keep concise evidence in the spec/plan, separating expected reproduction failures
from broken experiments. Missing tools or inconclusive results leave investigation
and dependent work incomplete. Confirmed findings allow the approved work to
continue; a material scope/approach change needs renewed approval.

Optional `.ndd-sandbox/` scripts are local scratch work, not a security boundary.
Spec and plan may use them for bounded investigation without changing application
code or permanent tests. Reuse existing checks first, preserve existing scratch
files, keep them out of Git and retain reproducible sanitized evidence. See the
[shared investigation rules](../skills/ndd-setup/references/investigation.md).
An investigation-only plan does not complete delivery criteria or mark a feature
done. Executing it still records evidence and task progress unless the user
explicitly requests read-only work. These are agent instructions, not a mechanical
execution gate or a new runner.

## Optional review

Use `ndd-review 001` to review the latest available stage of that feature. An
explicit `spec`, `plan` or `code` mode overrides detection and can come before or
after the feature. Without an ID, review proposes the highest number for your
confirmed prefix and waits for your confirmation; it does not select by date.

Review reads relevant files without editing them or running tests/builds. It
reports findings and limitations in chat, including stale plan checksums or
missing approvals, without changing them. It can review drafts and completed work.

Afterward choose whether to save `review.md` beside the feature's spec/plan.
For an existing report, choose replace, extend or do not save. Extend maintains
one checklist with stable finding IDs, preserves comments and adds new problems
without duplicates. Verified corrections become `[x] F1 — fixed` with date and
evidence; unchecked or out-of-scope findings are not silently closed. A changed
file requires a fresh choice before saving. No answer means no write.

## When requirements change

The plan stores a checksum of the spec body. This does not cover external project
documents: relevant changed project requirements/rules must also be reconciled
before affected implementation, even when the task checksum still matches.
If the spec body changes, implementation stops for review and an updated plan.
Status changes and line-ending differences
do not invalidate it; edits to the body do, including wording changes.

Changed requirements need spec approval again. Revise the affected tasks while
keeping completed work and evidence that remain valid. Changes to the approach
or scope need plan approval; small implementation decisions within approved scope
can be recorded in the plan.

If the code violates the agreed spec, fix the bug. Do not change the spec simply
to make it match the bug.

## Verification and continuing work

Each acceptance criterion needs a task and a final check. Checks can be tests,
builds or a recorded manual observation, depending on the change. Failed or missing
checks leave the task incomplete. A planned, specific reproduction failure may
complete an investigation task, but never proves the implementation passes.
The feature is marked `done` only after all
acceptance criteria, required project checks and the final diff are verified.

`ndd-do 001` completes all remaining tasks in order and final verification.
`ndd-do 001 T2` limits execution to T2; unfinished prerequisites are reported,
not silently implemented. A completed task alone is not a reason to pause.
Stop for a blocker, scope change, stale approval/checksum or an action requiring
separate authorization. Continue in another session or agent using the same spec, plan and recorded results. No fresh session
is required. Commit, push, deployment and production actions need separate authorization.

Use focused checks during implementation, then required final project checks.
Reuse passing results only while relevant code, configuration, dependencies and
inputs are unchanged; rerun affected checks after changes. Record concise results
instead of repeating execution logs. A final response states changes, verification
and unresolved issues.

See the compact [CSV export example](../examples/002-csv-export/spec.md) and its
[plan](../examples/002-csv-export/plan.md).
