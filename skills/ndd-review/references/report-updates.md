# Saving and updating a review

Save only after the user's choice, only to `review.md` in the selected feature.
Do not write through symlinks/junctions or a linked parent, or outside that feature.
For [private specs](../../ndd-setup/references/private-specs.md), write to the real
folder from `ndd.specsRoot`, not through the `ndd-specs` link.
Inspect the destination before offering save choices. Keep its observed content
(or absence) as the baseline, then re-read immediately before writing. If it has
changed or appeared since the choice, stop and agree on the action again; do not
silently merge, overwrite or lose another person's work. This is a conflict check,
not an atomic multi-editor guarantee. Report write errors and retain the chat report.

- **Create:** Use the bundled template, replacing placeholders with the displayed
  findings and actual scope. No findings means an empty checklist with a scoped
  no-findings statement, not invented F entries.
- **Replace:** Only an explicit replace choice permits replacing the whole file
  with the current report. Explain that prior findings/comments will be removed.
- **Extend:** Update one unified report, not an appended second dated report.
  Read the existing report before composing the update. Keep finding IDs and user
  comments, including resolved findings. Match a finding by problem, location and
  scenario; the same line alone is insufficient. Update rechecked findings and
  add genuinely new ones after the largest existing F number, without duplicates.
  If structure or IDs are ambiguous, clarify rather than discarding content.

Use `[ ] F1` for unresolved findings. Only mark `[x] F1 — fixed` after inspecting
concrete evidence that the problem was corrected. Keep its description, date and
brief evidence; never close it merely because it is absent from the latest report.
Tests are not run by review: cite inspected code or clearly attributed prior test
results without claiming execution. If a fixed issue recurs, reopen the same ID
and explain the new evidence. Keep out-of-scope findings, marking them "not
rechecked in this review" and retaining their previous date/evidence/status.
Update the report's date, feature, mode, scope and limitations to distinguish
this review from older evidence. Keep hypotheses and suggestions outside the
confirmed-defect checklist; preserve user comments in these sections too.

Show the intended update if extending changes the displayed report (for example,
reconciling IDs or closing earlier findings), and confirm any materially different
action. After writing, read back the file and report the saved path. Do not change
spec/plan statuses, approvals or task completion as a consequence of saving.
