# EVAL.md — Verification Evidence
# Location : specs/[NNN-feature-name]/eval.md
# Committed : YES
# Purpose   : Evidence that generated code satisfies the spec.
#             Written by the human reviewer — not by Claude.
#             PR cannot be raised until every BLOCKING item is PASS.
# Feature   : [Feature Name]
# Author    : [Name] | Date: [DATE]

---

## PR Gate — Complete Last

- [ ] Build PASS (Task 5.1 AC-10)
- [ ] All blocking ACs PASS or GAP — zero FAIL
- [ ] /eval-run → eval statement satisfied (no FAIL on a case central to it)
- [ ] /guardrail-check → no FAIL; every adversarial test in guardrails.md section 3 shows BLOCKED, not BYPASSED
- [ ] /hipaa-check → COMPLIANT
- [ ] /spec-review → zero FAIL
- [ ] CLAUDE.md updated with new patterns
- [ ] This EVAL.md committed to the branch

---

## 1. Build

```
[PASTE dotnet build OUTPUT]
```

Errors   : [N]
Warnings : [N]
Result   : PASS / FAIL

---

## 2. AC Results

| ID    | Criterion | Result | Evidence |
|-------|-----------|--------|----------|
| AC-01 | HTTP 200 for valid request | PASS / FAIL / GAP | |
| AC-02 | Status enum values correct | PASS / FAIL / GAP | |
| AC-03 | [Seed record 1] → [expected] | PASS / FAIL / GAP | |
| AC-04 | [Seed record 2] → [expected] | PASS / FAIL / GAP | |
| AC-05 | Unknown ID → ERROR + code | PASS / FAIL / GAP | |
| AC-06 | Timestamp in ISO 8601 | PASS / FAIL / GAP | |
| AC-07 | dataSource = "[SOURCE]" | PASS / FAIL / GAP | |
| AC-08 | Audit log per check | PASS / FAIL / GAP | |
| AC-09 | No PHI in logs | PASS / FAIL / GAP | See /hipaa-check |
| AC-10 | Build: 0 errors, 0 warnings | PASS / FAIL / GAP | See build above |

**GAP** = verified at runtime but not statically — acceptable for PR with note.

---

## 3. Eval Set Results (/eval-run Output)

```
[PASTE FULL /eval-run OUTPUT HERE]
```

- Eval statement (from eval-set.md section 1) satisfied : YES / NO / PARTIAL
- Cases requiring runtime verification (GAP) resolved    : YES / NO / N-A

---

## 4. Guardrail Check Results (/guardrail-check + Adversarial Test Summary)

```
[PASTE FULL /guardrail-check OUTPUT HERE]
```

Adversarial test results (copy from guardrails.md section 3):

| Guardrail ID | Result | Notes |
|-----------------|----------|---------|
| | BLOCKED / BYPASSED | |

- Any BYPASSED results : YES / NO — if YES, this guardrail is not enforced. Do not raise the PR.

---

## 5. /spec-review Output

```
[PASTE FULL OUTPUT]
```

---

## 6. /hipaa-check Output

```
[PASTE FULL OUTPUT]
```

Overall: COMPLIANT / NON-COMPLIANT

---

## 7. Deviations from Spec

[Anything Claude generated that differs from SPEC.md.
Was it correct gap-fill (spec was silent) or wrong (must change)?]

| Deviation | File | Correct or Wrong | Action |
|-----------|------|------------------|--------|
| | | | |

---

## 8. Open Questions Resolved

| ID    | Resolution |
|-------|------------|
| OQ-01 | |
| OQ-02 | |

---

## 9. CLAUDE.md Updates

[New patterns added to CLAUDE.md from this session:]

- [ ] [Pattern — file where it first appears]
