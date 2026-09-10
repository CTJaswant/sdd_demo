# DESIGN-NOTE.md — [Feature Name]
# Location : specs/[NNN-feature-name]/design-note.md
# Committed : YES
# Status    : DRAFT → APPROVED
# Author    : [Name] | Date: [DATE]
# Depends on: spec.md APPROVED, risk-classification.md COMPLETE
#
# PURPOSE   : Capture the technical design decisions, security and
#             privacy considerations, audit implications, and approval
#             gates BEFORE task breakdown and implementation.
#             Step 5 of the SDAD Golden Path — Plan.
#             Produced alongside PLAN.md and TASKS.md.
#
# SOURCE    : Derived from design-note-template.md and sdad-golden-path.md
#             Step 5 in the SDAD Golden Repo Kit.
# ─────────────────────────────────────────────────────────────

---

## Feature

[Feature name — same as spec.md]

---

## Summary of Approach

[Describe the technical approach in plain language.
Two to three sentences. What pattern is being used and why.]

---

## Components Affected

[List every component, file, service, or system touched by this change.
Be specific — file paths where known.]

---

## Data Handling Design

[How is data read, written, transformed, or passed between components?
Identify any PHI or sensitive data fields and how they are handled.
Reference CLAUDE.md compliance rules where applicable.]

---

## Security / Privacy Considerations

[What are the security and privacy implications of this change?
Reference risk-classification.md answers.
State what was done to mitigate each identified risk.]

---

## Audit and Observability Considerations

[What audit log entries are written?
What fields are included? What fields are explicitly excluded?
Reference CLAUDE.md section 4 — HIPAA rules.
Confirm: correlationId used, no raw PHI, no full request/response payloads.]

---

## Test Strategy

[What tests will verify this change?
Unit tests for which logic?
Integration tests for which endpoints?
What test data will be used — confirm synthetic only.]

---

## Rollback / Failure Handling

[How is the change reversed if it causes a problem in production?
What happens if the new code fails — does it degrade gracefully?
Is the change additive (low rollback risk) or destructive (high rollback risk)?]

---

## Open Questions

[Anything unresolved that affects the design.
Link to OPEN_QUESTIONS.md entries where applicable.]

---

## Approval Gates

- [ ] Architect review
- [ ] Security review
- [ ] Privacy review
- [ ] Domain SME review
- [ ] QA / validation review
