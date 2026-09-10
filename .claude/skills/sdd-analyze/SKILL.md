---
name: sdd-analyze
description: Cross-artifact consistency check. Use after tasks.md is written,
             before implementation starts. Verifies spec, plan, and tasks
             are aligned and constitution-compliant. Catches conflicts early.
---

# SDD Analyze Workflow

## Purpose
Verify all three artifacts — spec.md, plan.md, tasks.md — are consistent
with each other and with CLAUDE.md before the first line of code is generated.

## Step 1 — Read All Artifacts
1. CLAUDE.md
2. specs/[NNN]/spec.md
3. specs/[NNN]/plan.md
4. specs/[NNN]/tasks.md

## Step 2 — Spec ↔ Plan Consistency

For each functional requirement in SPEC.md section 2:
- Is it addressed in PLAN.md?
- Does PLAN.md introduce anything not in SPEC.md?

For each AC in SPEC.md section 3:
- Is there at least one task in TASKS.md that covers it?
- Which task? State the task number.

For each non-goal in SPEC.md section 7:
- Does PLAN.md include any design that implements it? Flag as SCOPE_CREEP.
- Does TASKS.md include any task that implements it? Flag as SCOPE_CREEP.

## Step 3 — Plan ↔ Tasks Consistency

For each file listed in PLAN.md section 2:
- Is there a corresponding task in TASKS.md?
- Does the task reference the correct pattern file?

For the dependency order in PLAN.md section 6:
- Does TASKS.md respect this order?
- Are there tasks that could run in parallel (no shared file dependencies)?

## Step 4 — Constitution Compliance

Check PLAN.md and TASKS.md against CLAUDE.md:
- Naming conventions respected?
- Route pattern correct?
- DI pattern correct?
- No PHI in planned log calls?
- No new packages introduced without CLAUDE.md update?

## Step 5 — Output

```
=== ANALYSIS REPORT ===

SPEC ↔ PLAN:
  ACs with no task coverage: [list or NONE]
  Plan items not in spec: [list or NONE]
  Scope creep in plan: [list or NONE]

PLAN ↔ TASKS:
  Files in plan with no task: [list or NONE]
  Dependency order violations: [list or NONE]
  Parallelisable tasks: [list or NONE]

CONSTITUTION COMPLIANCE:
  Violations: [list or NONE]

OVERALL: READY TO IMPLEMENT / ISSUES FOUND
  If issues: list what must be fixed before starting implementation.

=== END REPORT ===
```

Does not modify any file. Analysis only.
