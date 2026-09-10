# Intent — Member Eligibility Check (Phase 1)

## Problem
Non-clinical agents creating prior authorization requests cannot verify 
if the selected member is enrolled in the chosen health plan. Requests 
are submitted blind, causing rework when plan mismatches are discovered later.

## Users
Non-clinical intake agents using the PA request creation wizard.

## Proposed Solution
Add eligibility verification to the PA wizard (step 4 — member selection).  
When agent selects a member and health plan, system checks if member's 
`plan_code` matches the health plan's `plan_code` and displays the result.

**Phase 1:** Local database lookup only. No real-time payer API calls.

## Definition of Eligibility (Phase 1)
| Status | Condition |
|--------|-----------|
| ELIGIBLE | Member exists AND member.plan_code = health_plan.plan_code |
| INELIGIBLE | Member exists AND plan_code mismatch (including NULL) |
| ERROR | Member not found OR health plan not found |

## Behavior
- **Advisory only** — agent sees result but can proceed with PA creation
- Every check is audited (one DB record per check)
- No PHI in logs or error messages

## Success Criteria
1. Agent can verify eligibility during PA request creation (wizard step 4)
2. System returns ELIGIBLE, INELIGIBLE, or ERROR within 500ms
3. Every check creates one audit record with correlationId, no PHI
4. Zero warnings on `dotnet build`; `/hipaa-check` returns COMPLIANT

## Non-Goals
- Real-time health plan API integration (Phase 2)
- Blocking submission on INELIGIBLE status
- Date-based eligibility (effective/termination dates)
- Benefit-level eligibility (procedure-specific coverage)

