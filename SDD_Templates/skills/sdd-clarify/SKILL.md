---
name: sdd-clarify
description: Identify underspecified areas in SPEC.md through structured questioning.
             Use after spec.md is written, before plan.md is created.
             Surfaces ambiguities so PLAN.md is built on solid foundations.
---

# SDD Clarify Workflow

## Purpose
Find gaps in SPEC.md before they become bugs in the code.
Output is a prioritised list of questions — not answers.

## Step 1 — Read Artifacts
Read in this order:
1. CLAUDE.md — governing principles
2. specs/[NNN]/spec.md — the spec under review

## Step 2 — Check Completeness

For each section of SPEC.md, ask:

**Section 3 (AC):**
- Is every AC testable? Can it pass or fail?
- Is every AC binary? No "mostly" or "should"?
- Does every AC have a "verified by" that is achievable?
- Are there behaviours described in section 2 that have no corresponding AC?

**Section 4 (API):**
- Is every request field marked required or optional?
- Is every error condition covered in section 4.4?
- Are there response fields with no corresponding AC?

**Section 6 (Constraints):**
- Does every constraint trace to CLAUDE.md?
- Are there CLAUDE.md rules that this spec should reference but doesn't?

**Section 7 (Non-Goals):**
- Are there fewer than 4 entries? (flag — likely incomplete)
- Are there items in the requirements that could be misinterpreted as in-scope?

**Section 9 (Open Questions):**
- Are there BLOCKING questions unresolved?
- Are there assumptions that could affect the architecture?

## Step 3 — Check Constitution Compliance

Verify SPEC.md does not conflict with CLAUDE.md:
- Route convention
- Naming conventions
- Compliance rules (PHI, credentials)
- Approved packages

## Step 4 — Output

```
=== CLARIFICATION REPORT ===

BLOCKING QUESTIONS (must resolve before plan.md):
  1. [Question] — [why it blocks planning]

NON-BLOCKING QUESTIONS (can proceed, flag for review):
  1. [Question] — [assumption to make if proceeding]

CONSTITUTION CONFLICTS:
  [NONE] or [description of conflict]

MISSING ACS:
  [NONE] or [behaviour described in spec with no AC]

RECOMMENDATION:
  [Ready for plan.md] or [Resolve items X, Y before proceeding]

=== END REPORT ===
```

Does not modify any file. Questions only.
