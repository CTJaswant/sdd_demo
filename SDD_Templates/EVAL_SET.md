# EVAL_SET.md — [Feature Name]
# Location : ./EVAL_SET.md  (project root)
# Committed: YES
# Status   : DRAFT → VALIDATED → EXECUTED
# Author   : [Name]  |  Date: [DATE]
# Purpose  : Define what "correct" looks like — BEFORE generation starts.
#            Written Monday, alongside SPEC.md and GUARDRAILS.md. Executed
#            Wednesday/Thursday via the eval-run skill — results are recorded
#            in EVAL.md section 4, not in this file. This file does not change
#            once VALIDATED, except to append new cases (section 4).
# See also : SPEC.md section 3 (Acceptance Criteria) — every case below should
#            trace to an AC, a Guardrail ID, or both. DESIGN-NOTE.md's "Test
#            Strategy" section is a second source — if it names a scenario
#            (e.g. an edge case worth a unit test), that scenario belongs here
#            as a case too, not only in whatever test file eventually covers it.
# ─────────────────────────────────────────────────────────────
# RULES FOR FILLING THIS IN:
#   Section 1 (Eval Statement): ONE sentence — "Correct when X given Y, failed
#     when Z." If you cannot write this sentence, the feature is not ready to
#     build — stop and go back to SPEC.md.
#   Section 2: minimum 5 cases. Must include at least 1 standard case, 1 edge
#     case (missing/ambiguous data), and 1 guardrail case (agent should
#     refuse/flag, not silently succeed).
#   Validated By is REQUIRED for every case. A case with no named human
#     validator is an opinion, not an eval case — do not leave it blank.
# ─────────────────────────────────────────────────────────────

---

## 1. Eval Statement

[ONE sentence: "[Feature] is performing correctly when it produces [X] given
[Y], and has failed when [Z]."]

Example: "The eligibility check is performing correctly when it returns
ELIGIBLE, INELIGIBLE, or ERROR within 500ms with no PHI in the audit record,
and has failed when it returns any other status, throws an unhandled
exception, or logs a PHI field."

---

## 2. Eval Cases
# Minimum 5. Mix of standard / edge / guardrail cases — see rules above.

| ID | Scenario | Input | Expected Output | Known Failure Mode | Traces To | Validated By |
|------|------------|---------|---------------------|------------------------|--------------|------------------|
| EV-01 | [Standard case — e.g. matching plan codes] | [e.g. member PT001234 + health plan CIGNA] | [status=ELIGIBLE] | [N/A — happy path] | [AC-03] | [Name / Date] |
| EV-02 | [Standard case — mismatch] | [member PT001235 + health plan AETNA, mismatched plan_code] | [status=INELIGIBLE] | [N/A — happy path] | [AC-04] | [Name / Date] |
| EV-03 | [Edge case — NULL plan_code] | [member with plan_code=NULL] | [status=INELIGIBLE, not a crash] | [code may call .Equals() on a null field and throw — see GUARDRAILS.md G-N02] | [AC-09 / G-N02] | [Name / Date] |
| EV-04 | [Edge case — member not found] | [unknown patient_id] | [status=ERROR, HTTP 200 with status field — not a 404/500] | [code may return an unhandled 500 instead of a graceful ERROR status] | [AC-05] | [Name / Date] |
| EV-05 | [Guardrail case — agent should flag, not silently block] | [INELIGIBLE result reaching wizard step 5] | ["Next" stays enabled — advisory only, not gated] | [code may add a submission block that wasn't asked for — see GUARDRAILS.md G-N01] | [G-N01] | [Name / Date] |

---

## 3. Run Cadence
# When this eval set must be re-run. Not just before launch.

- [ ] Before this feature's PR is raised (baseline run — results go in EVAL.md section 4)
- [ ] After every change to this feature's prompt, context, or generation instructions
- [ ] After every Claude / Anthropic model version change used on this project
- [ ] Quarterly, alongside the CLAUDE.md / GUARDRAILS.md review

A model update is not a patch. Re-run the full set — do not assume backward
compatibility with a previous run's results.

---

## 4. Production Feedback Loop
# Once shipped, real failures get added here as new eval cases — not filed
# separately and forgotten. This section grows; sections 1–3 above do not
# change once VALIDATED.

| Date | What Broke In Production | New Eval Case ID Added |
|--------|------------------------------|----------------------------|
| | | |
