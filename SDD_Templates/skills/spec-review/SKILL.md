---
name: spec-review
description: Check generated code against SPEC.md acceptance criteria.
             Use after every generation task. Reports PASS/FAIL/GAP per AC.
             Does not fix — reports only. Run after every phase in TASKS.md.
---

# Spec Review Workflow

## Step 1 — Load Spec
Read `specs/[NNN]/spec.md`. List every AC, constraint, and non-goal.
If not found: stop. Report "spec.md not found."

## Step 2 — Inventory Generated Files
List files created or modified this session.
For each: which AC does it implement?
Untraced file (no AC): flag as UNTRACED.

## Step 3 — Check Each AC
- `PASS`    — code satisfies it. State how.
- `FAIL`    — code does not satisfy it. State what is missing.
- `GAP`     — requires runtime verification (Swagger, log).
- `NOT_YET` — files not generated yet.

## Step 4 — Check Constraints
Each constraint in SPEC.md section 6:
- RESPECTED or VIOLATED — if violated: file and line.

## Step 5 — Check Non-Goals
Scan generated code for anything in SPEC.md section 7.
If found: flag as SCOPE_CREEP — file, what was generated, which non-goal.

## Step 6 — Output

```
=== SPEC REVIEW ===
AC-01: [PASS/FAIL/GAP/NOT_YET] — [reason]
AC-02: [PASS/FAIL/GAP/NOT_YET] — [reason]
[all ACs]

CONSTRAINTS: [RESPECTED / VIOLATED — detail]
SCOPE CREEP: [NONE or file:line — non-goal violated]
SPEC GAPS:   [NONE or assumption made — spec was silent]

ACTION: [what must be fixed / "Ready for next phase"]
=== END ===
```

Does not fix. Reports only.
