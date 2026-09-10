---
name: guardrail-check
description: Check generated code against GUARDRAILS.md MUST/NEVER rules. Use
             after each generation step that touches a guardrailed file or
             behaviour. Reports PASS, FAIL, or NOT_STATIC per guardrail, and
             generates the adversarial test list a human or the
             guardrail-red-team subagent must still run. Does not fix.
             Does not perform the adversarial test itself.
---

# Guardrail Check Workflow

## Step 1 — Load Guardrails

Read GUARDRAILS.md in the project root.
If not found: stop and report:
`GUARDRAILS.md not found. Create it before running /guardrail-check.`

Extract every MUST (section 1) and NEVER (section 2) rule with its ID, trigger
condition, and failure behaviour.

---

## Step 2 — Static Enforcement Check

For every MUST and NEVER rule, inspect the generated code for this feature and
assign exactly one status:

- `PASS`       — Code structurally enforces this rule. State the file/line that does it.
- `FAIL`       — Code does not enforce this rule, or enforces it incorrectly. State what's missing.
- `NOT_STATIC` — This rule can only be verified by attempting the action (e.g. a
                 conversational agent being asked to violate it). Flag it for the
                 human adversarial test in GUARDRAILS.md section 3 — do not guess
                 at a result you cannot actually observe from code.

This is the same PASS/FAIL discipline as /spec-review, scoped to GUARDRAILS.md
instead of SPEC.md section 3.

---

## Step 3 — Generate the Adversarial Test List

For every NEVER rule, write ONE concrete adversarial attempt that should be
tried — the exact request, input, or bypass path. Be specific enough that
someone could carry it out without further interpretation.

Do not attempt the test yourself in this skill. Generating the test and
running it are different steps. Running it is recorded in GUARDRAILS.md
section 3 — either by a human, or by the `guardrail-red-team` subagent for
guardrails that are enforced by code (input validation, status gating) rather
than purely by conversational instruction.

---

## Step 4 — Cross-Check Against hipaa-check

If any NEVER rule overlaps a PHI/credential/audit concern: state that this
rule's compliance verification is owned by /hipaa-check, not duplicated here.
List the Guardrail ID ↔ hipaa-check step mapping from GUARDRAILS.md section 5.

---

## Step 5 — Output the Report

```
=== GUARDRAIL CHECK REPORT ===
Generated: [timestamp]

MUST RULES:
  G-M01: [PASS/FAIL] — [reason]
  G-M02: [PASS/FAIL] — [reason]

NEVER RULES:
  G-N01: [PASS/FAIL/NOT_STATIC] — [reason]
  G-N02: [PASS/FAIL/NOT_STATIC] — [reason]

ADVERSARIAL TESTS REQUIRED BEFORE PR (not yet run by this skill):
  G-N01 — [exact attempt to make]
  G-N02 — [exact attempt to make]

HIPAA-CHECK OVERLAP:
  [Guardrail ID] → owned by /hipaa-check [step]

RECOMMENDED ACTIONS BEFORE PROCEEDING:
  [List FAILs to fix. If none: "Static checks clean. Run the adversarial
  tests above (or the guardrail-red-team subagent) and record results in
  GUARDRAILS.md section 3 before PR."]

=== END REPORT ===
```

This check does not fix violations and does not run the adversarial tests
itself. Both are separate actions — human, or the guardrail-red-team subagent
— recorded in GUARDRAILS.md, not here.
