# GUARDRAILS.md — [Feature Name]
# Location : ./GUARDRAILS.md  (project root)
# Committed: YES
# Status   : DRAFT → APPROVED → STATICALLY ENFORCED → ADVERSARIALLY TESTED
# Author   : [Name]  |  Date: [DATE]
# Purpose  : Hard clinical/regulatory boundaries the agent must always or never
#            cross. Encoded from Step 1 of generation — never added after the
#            fact. A guardrail that can be bypassed by asking nicely, or by
#            calling the API directly instead of going through the UI, is not
#            a guardrail.
# See also : SPEC.md section 7 (Non-Goals) — every NEVER rule here should trace
#            back to one. DESIGN-NOTE.md (Security/Privacy, Audit and
#            Observability sections) — every MUST rule here should trace back
#            to a decision made there. EVAL_SET.md — guardrail cases (EV-0X)
#            should trace forward to a case here.
# ─────────────────────────────────────────────────────────────
# RULES FOR FILLING THIS IN:
#   NEVER rules: start from SPEC.md section 7 (Non-Goals). Every item there
#     is a candidate guardrail — "we don't build X" becomes "NEVER do X, even
#     if asked."
#   MUST rules: start from DESIGN-NOTE.md's "Data Handling Design", "Security
#     / Privacy Considerations", and "Audit and Observability Considerations"
#     sections. A decision made there ("audit log carries correlationId +
#     status only") becomes a MUST with a testable failure behaviour.
#   Every MUST and NEVER needs a stated Failure Behaviour: what the agent does,
#     and what the user sees, when the guardrail fires. Silent failure is not
#     allowed — the agent must surface the issue, not swallow it.
#   Minimum 1 MUST and 1 NEVER. If this feature touches PHI, at least one NEVER
#     must cross-reference the hipaa-check skill's PHI field list (section 5).
#   "Be careful with X" is not a guardrail. State exactly what triggers it and
#     exactly what happens when it fires.
#   Every NEVER rule must be adversarially tested (section 3) before Status can
#     move to ADVERSARIALLY TESTED. Untested guardrails are not enforced — they
#     are hopes.
# ─────────────────────────────────────────────────────────────

---

## 1. MUST — The Agent Must Always Do This

| ID | Guardrail | Trigger Condition | Failure Behaviour (what the agent does / what the user sees) | Source (SPEC.md ref) |
|----|-----------|--------------------|----------------------------------------------------------------|------------------------|
| G-M01 | [e.g. Verify both member and health plan exist before comparing plan codes] | [Before every eligibility check] | [If either is not found: return status=ERROR — no exception, no PHI in the response] | [SPEC.md §3 AC-05] |
| G-M02 | [State explicitly] | [State explicitly] | [State explicitly] | [SPEC.md §X] |
| G-M03 | [Add more rows as needed — do not pad with filler] | | | |

---

## 2. NEVER — The Agent Must Refuse, Regardless of What Is Asked

| ID | Guardrail | Trigger Condition | Failure Behaviour (what the agent does / what the user sees) | Source (SPEC.md ref) |
|----|-----------|--------------------|----------------------------------------------------------------|------------------------|
| G-N01 | [e.g. Never block PA submission on an INELIGIBLE eligibility result] | [Any wizard step that reads eligibilityStatus] | [Status renders as an advisory badge only — "Next" stays enabled regardless of status] | [SPEC.md §7 Non-Goal: "Blocking submission on INELIGIBLE status"] |
| G-N02 | [e.g. Never include a PHI field in a log, exception message, or error response] | [Any catch block / ILogger call touching member or patient data] | [Log correlationId + status + reason code only — see hipaa-check skill, section 5, for the full PHI field list] | [DESIGN-NOTE.md "Audit and Observability Considerations" / SPEC.md §6 constraint] |
| G-N03 | [Add more rows as needed] | | | |

---

## 3. Adversarial Test Log
# Required before this feature can be marked ADVERSARIALLY TESTED.
# For each NEVER rule above: deliberately try to make the code violate it.
# "Prompt the agent to do the thing it should refuse. If it complies, the
# guardrail isn't working." — Playbook Move 2.
#
# Two ways to fill this in:
#   (a) Run the `.claude/agents/guardrail-red-team` subagent — it covers
#       code-level guardrails (input validation, status gating, missing
#       checks) and can read code to look for a bypass. Paste its findings
#       below.
#   (b) For guardrails that only exist as instructions to a conversational
#       agent (no enforcing code to read), a human must do this by hand —
#       open a session and deliberately ask the agent to do the forbidden
#       thing. The subagent will tell you which rules fall into this category.

| Guardrail ID | Adversarial Attempt (what you tried) | Result | Tested By / Date |
|----------------|------------------------------------------|----------|----------------------|
| G-N01 | [e.g. Called POST /api/authorizations directly with eligibilityStatus=INELIGIBLE in the payload, bypassing the wizard, to see if the backend itself ever blocks on status] | [BLOCKED / BYPASSED] | [Name / Date] |
| G-N02 | [e.g. Forced a check on a member with plan_code=NULL and inspected the resulting log line for PHI] | [BLOCKED / BYPASSED] | [Name / Date] |

If any Result is BYPASSED: this guardrail is not enforced. Fix the code, re-test,
and only then move Status to ADVERSARIALLY TESTED. Do not raise a PR with an
open BYPASSED result.

---

## 4. Guardrail ↔ Spec Traceability
# Every Non-Goal in SPEC.md section 7 should map to a guardrail here, or have
# an explicit, stated reason why it doesn't need one (e.g. a scope limit with
# no enforceable runtime behaviour — there's no code yet to guard).
# MUST rules don't trace to a Non-Goal — they trace to a DESIGN-NOTE.md
# decision instead. Use the second table below for those.

| SPEC.md Non-Goal | Guardrail ID | or: Why No Guardrail Is Needed |
|---------------------|----------------|-------------------------------------|
| [Non-goal 1] | [G-N01] | |
| [Non-goal 2] | [G-N02] | |
| [Non-goal 3] | — | [e.g. "Phase 2 API integration — no code exists yet to guard against"] |

| DESIGN-NOTE.md Decision | Guardrail ID |
|----------------------------|------------------|
| [e.g. "Audit log: correlationId + status only"] | [G-N02] |
| [e.g. identity-verification decision] | [G-M01 / G-M02] |

---

## 5. Compliance Guardrails — Cross-Reference Only
# Do not duplicate the PHI field list here. The hipaa-check skill is the single
# source of truth for PHI / credential / audit rules. List only which
# Guardrail ID maps to which hipaa-check step.

| Guardrail ID | hipaa-check Coverage |
|-----------------|--------------------------|
| G-N02 | PHI-in-logs check (hipaa-check Step 1) |
