---
name: eval-run
description: Run the cases in EVAL_SET.md against generated code and report
             PASS/FAIL/GAP per case, plus whether the eval statement as a
             whole is satisfied. Use on Wednesday/Thursday of the AIFE cycle,
             after generation, before filling EVAL.md. Does not fix.
---

# Eval Run Workflow

## Step 1 — Load the Eval Set

Read EVAL_SET.md in the project root.
If not found: stop and report:
`EVAL_SET.md not found. Create it before running /eval-run.`

Extract the Eval Statement (section 1) and every case from section 2 with its
ID, input, expected output, and Traces To reference.

---

## Step 2 — Evaluate Each Case

For every case, assign exactly one status:

- `PASS` — Running this input through the generated code/API produces the
           expected output. State how you verified it (code trace, or note
           that it requires a live Swagger/runtime call).
- `FAIL` — Output differs from expected. State the actual vs expected result.
- `GAP`  — Cannot be verified without a live runtime call (needs Swagger, a
           running database, etc.). Flag for the human to run manually.

If a case's Traces To column references a Guardrail ID, also check that
/guardrail-check's result for that same ID agrees — do not mark a case PASS
here if guardrail-check marked the underlying rule FAIL.

---

## Step 3 — Check the Eval Statement As a Whole

Re-state the Eval Statement from EVAL_SET.md section 1. Confirm: do the
aggregate case results satisfy it? If any case central to the statement is
FAIL, the feature does not yet meet its own definition of correct — say so
plainly, even if individual SPEC.md ACs are independently passing. The eval
statement is the holistic check; individual ACs are not a substitute for it.

---

## Step 4 — Output the Report

```
=== EVAL RUN REPORT ===
Generated: [timestamp]
Eval Statement: "[paste from EVAL_SET.md section 1]"

CASE RESULTS:
  EV-01: [PASS/FAIL/GAP] — [reason]
  EV-02: [PASS/FAIL/GAP] — [reason]
  [... all cases]

EVAL STATEMENT SATISFIED: YES / NO / PARTIAL — [explain]

CASES REQUIRING RUNTIME VERIFICATION (GAP):
  [List, or "NONE"]

RECOMMENDED ACTIONS BEFORE PROCEEDING:
  [List FAILs to fix, or "Ready to record in EVAL.md section 4."]

=== END REPORT ===
```

This check does not fix anything. Paste this report into EVAL.md section 4
(Eval Set Results) as the evidence record.
