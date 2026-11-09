# Testing NDD

## Automated checks

From the repository root, use Python 3.13 (the version configured in CI):

```bash
python3 -m unittest discover -s tests -v
```

On Windows:

```powershell
python -m unittest discover -s tests -v
```

Python is needed for development checks, not for using the installed skills.
Tests use temporary projects and installation paths. They cover installation,
updates, rollback, removal, project registration, spec checksums and ZIP contents.
They do not install into your real agent folders or clean your real project registry.

On every push and pull request, the same suite compares the main help command
table with the skills discovered from `skills/*/SKILL.md`. Each skill must appear
exactly once for both Codex and Claude Code, with matching commands in each row.
Missing, obsolete or duplicate commands fail CI; adding a skill requires updating
`skills/ndd-help/assets/help.md`.

The CI workflow (`.github/workflows/ci.yml`) configures macOS, Ubuntu and
Windows runs, including Windows PowerShell and PowerShell 7. Some checks are
platform-specific and may be skipped. To select another PowerShell executable:

```bash
NDD_TEST_POWERSHELL=/absolute/path/to/pwsh python3 -m unittest discover -s tests -v
```

Check the actual test output and CI run for results; this page does not maintain
a separate count of passing tests or claim end-to-end agent compatibility.

## Checking the agent workflow

Unit tests cannot verify how an agent follows skill instructions. For a manual
check, use a disposable project and record the agent version, OS and actual result:

1. Run setup, confirm a prefix, then repeat setup. Check that it preserves project
   instructions and reuses the saved value without rewriting it. Outside Git,
   check that the prefix remains session-only.
2. Create a small spec, approve it, create a plan and approve it. Confirm that an
   unapproved draft does not allow implementation.
3. With two independent unchecked tasks, call `ndd-do <id>` and confirm it
   continues through both and final checks. In a fresh fixture, call
   `ndd-do <id> T2`: only T2 runs; missing prerequisites are reported.
   Change the spec body and confirm the stale plan stops implementation until
   reviewed. A failed verification must leave affected work incomplete.
4. Resume in a new session or the other agent. Confirm that progress is preserved
   and completion requires the final acceptance checks.

Use disposable installation paths for manual uninstall checks too. Preview first;
verify that single-agent removal keeps shared settings and full removal cleans
registered prefixes while skipping failed entries. Check source-clone removal
on the target OS, including open-file failures on Windows.

## Help and review acceptance

Use the [help/review scenarios](help-review-validation.md) on macOS and Windows
in both Claude Code and Codex. Record observations separately from automated
checks. Distribution tests verify metadata/resources; installer tests also cover
a synthetic four-skill layout with genuine installer-generated receipts,
upgrade/reinstall to seven skills, missing resources, automatic replacement of
existing NDD skill names and local edits, and removal of retained backups.
Installer checks also verify that updates remove legacy terminal help launchers
while preserving the chat reference, including after source removal. Automated
checks do not prove that either agent follows the help or review instructions.

## Compact workflow checks

In disposable projects, verify these observations in both agents; automated text
checks cannot prove them:

- A small CSV fix produces an AC-only spec and a short plan with AC references in
  tasks, no duplicate requirements/edge-case lists or coverage table. Length
  guidelines are ceilings, not padding targets; material risks are not omitted.
- Simple plan tasks stay on one line. A task with several actions uses a short
  title and ordinary bullets under one task checkbox; ordered substeps appear
  only when needed. Tools/method is present only for consequential execution
  choices, without invented commands, empty fields or repeated verification.
  Execution records relevant deviations without a routine tool inventory;
  task selection and completion still use the parent T ids and checkboxes.
- Both approvals remain necessary. Review accepts the compact shape and the
  existing legacy example without inventing structural defects.
- Default execution continues between tasks; an explicit task stops after it.
  A scope change, stale digest, missing prerequisite or separate authorization
  still stops dependent work. A failed required check cannot yield `done`.
- Context already established is reused, while changed files/assumptions are
  rechecked. Passing checks are reused only for unchanged relevant inputs;
  required final checks still run. Record actual commands to check repetition.
- Spec/plan are offered for approval as a file path plus at most five key points,
  not pasted into chat. Results contain concise evidence and
  limitations rather than repeated summaries. Resume preserves earlier progress.

The example consistency test covers both compact task-based AC references and
legacy coverage tables, including real spec-body checksums. Native agent behavior
and latency improvements require observations; shorter instructions alone do not
prove either.

## Investigation and evidence checks

Use disposable projects; these scenarios require behavioral observation, not
checks for particular wording in a generated plan:

- A routine, understood change gets no investigation task or scratch directory.
- A material uncertainty is checked during planning or becomes an explicit first
  task with a question, inputs, expected observation and dependent tasks.
  An investigation-only plan identifies unmet delivery ACs instead of inventing
  implementation tasks or claiming complete coverage.
- Spec/plan probes execute only within their scratch exception; application and
  permanent test files remain unchanged. Existing scratch files/ignore rules are
  preserved; no installation, live writes or notifications are inferred from it.
- A real, expected reproduction failure can complete investigation. An unrelated
  exception, missing tool/input, zero exit with irrelevant assertions or only an
  LLM explanation cannot; dependent work remains blocked.
- Confirmed findings continue into approved dependent tasks automatically.
  Contradictory findings trigger review of the affected approach/scope. Completing
  investigation-only tasks leaves delivery incomplete and the spec not done.
  Explicit execution records evidence and completed investigation checkboxes;
  an explicit read-only request instead reports unrecorded progress without writes.
- Evidence records actual commands/procedures, inputs, relevant environment,
  expected/observed results and limitations. Unchanged reliable evidence is reused;
  unavailable temporary files or changed inputs are not silently treated as current.

## Spec-to-plan continuation

In a disposable project, check both interactive-choice and text-only hosts:

- A spec ready for approval offers approve-and-continue, approve-only and changes,
  with its actual qualified ID or unambiguous project-relative spec path.
- Approve-and-continue records approval and loads `ndd-plan` for that same feature;
  the plan remains a draft until separately approved. No implementation starts.
- Approve-only does not create a plan; a subsequent Continue with Plan selection
  does. Silence, a default selection or requesting changes does not grant approval.
- A clarifying spec offers no approval/continuation until its questions are resolved.
- Existing IDs and custom paths are preserved. Hosts without interactive choices
  accept a short chat reply without requiring the full skill command.

These are manual behavioral checks; packaging and metadata tests cannot verify
that a host displays a button or that an agent follows the transition correctly.

## Project initialization and overview updates

Use disposable projects to exercise these behavioral cases in both agents.
These scenarios are a manual checklist, not a claim that agent runs were performed.

| Case | Expected result |
|---|---|
| Empty folder, no Git/prefix; init with a product idea | Discuss purpose/users, recommend a minimal document set, show selected drafts, save only after approval; no setup/code/Git side effects. |
| Each of the seven nonempty combinations of spec/features/rules; also decline all | Exactly the chosen files; no mandatory spec, empty placeholders or repeated filename question after an explicit choice. Decline/silence writes nothing. |
| Rules only, chosen interface and documentation languages | No required product interview; languages remain distinct; existing agent instructions retain precedence. |
| Existing project with README, code and scoped rule files | Inspect relevant context, summarize evidenced behaviour, clarify inferred goals and gaps; a selected rules.md links to authoritative files without copying or broadening rules. |
| Existing capability without NDD task specs | Record observed behaviour and verification limitations; do not label it an idea, invent task links or claim verified completion. |
| Skip init in a new or existing project | Normal task workflow remains available; no requirement to create project documents. |
| Repeat init with existing notes, links and an unselected rules file | Selected changes shown together; notes/links and unselected files preserved, no new task plan or automatic implementation. |
| Alternative specs root, existing task folders, no project documents | Init uses a sibling project folder; task commands preserve existing paths and do not create project documents. |
| Fresh project or unrelated specs/ directory | New task/init documents use ndd-specs/; unrelated specs/ is untouched. Setup creates neither folder. |
| Established NDD tasks or project context only in specs/ | Reuse that root, including for new tasks and overview updates; do not create a parallel ndd-specs/ or migrate files. |
| NDD work in both roots; short ID or latest-task review | Ask for the root/full task path before resolving or writing. Explicit paths select their own root and overview; no cross-root fallback or combined numbering. |
| New spec unambiguously belongs to an existing capability | Add one relative link and draft progress; preserve stage, description and other links. Unclear mapping asks; unrelated bug need not enter the overview. |
| Spec approved, plan draft, plan approved, implementation starts | Progress moves from spec approved/planning needed to ready to in progress; approvals are not inferred from the overview. |
| Explicit single task completes; another remains or a required check fails | Neither spec nor capability is marked done; partial progress or blocker is shown. |
| All linked specs done but described capability has uncovered scope | Do not infer capability completion; retain partial status or request scope review. |
| Complete capability gets a new bug violating its described scope | Preserve completion history while showing the current limitation and linked fix. |
| Reopened spec, stale digest, missing target, missing verification evidence | Refresh affected progress honestly; no false ready/done. Do not approve/rewrite other tasks to match the overview. |
| Project rules change while the task digest still matches | Reconcile relevant changes before implementation; unrelated changes do not restart all tasks. |
| Review finds a stale overview; setup/help invoked | Review reports without syncing; setup does not sync; help does not inspect the project. |
| Concurrent edits, write failure, outside-project link or redirected path | Preserve concurrent work, reject unsafe traversal, report incomplete synchronization without discarding valid task work. |
| Plan/do/review explicitly targets project/spec.md; latest-task selection | Explain that project context is not an executable task; ignore project/ when selecting numbered tasks. |

Automated distribution and installer checks verify that init and its shared
reference ship, survive source removal, install/update/uninstall with the other
skills, and fail preflight without writes if required resources are missing.
They do not prove conversational or status-aggregation behavior.

## Current distribution

There is no kit VERSION file, numbered release or release changelog. Install from
the current main branch or its source ZIP. To build a reproducible local bundle:

```bash
python3 scripts/build_distribution.py
```

This writes `dist/ndd-kit.zip` and its SHA-256 file and does not publish anything.
The ZIP contains the current kit with no Git metadata; track a source commit or
archive checksum when reporting a problem. CI builds the same bundle as an artifact.
