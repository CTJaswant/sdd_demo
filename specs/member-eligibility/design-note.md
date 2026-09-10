# DESIGN-NOTE.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/design-note.md
# Committed : YES
# Status    : DRAFT
# Author    : Claude Code | Date: 2026-09-10
# Depends on: spec.md DRAFT (blocking questions resolved), risk-classification.md COMPLETE
#
# PURPOSE   : Capture the technical design decisions, security and
#             privacy considerations, audit implications, and approval
#             gates BEFORE task breakdown and implementation.
# ─────────────────────────────────────────────────────────────

---

## Feature

Member Eligibility Check (Phase 1)

---

## Summary of Approach

Add a single new `EligibilityController` with one action, `POST /api/eligibility/check`, that performs the member/health-plan lookup and the plan-code comparison **directly in the controller, injecting `PriorAuthDbContext` only** — no separate service class or interface layer. This follows the "K2" simplicity decision for this feature and mirrors existing precedent in this codebase: `AuthorizationsController` already embeds its create/lookup logic directly rather than delegating to a service layer. The check is a synchronous, local EF Core LINQ lookup only (primary-key lookups against `members` and `health_plans`) — no external payer API calls in Phase 1. Every check writes exactly one `EligibilityCheck` audit record and returns a response containing no PHI fields beyond the identifiers the caller itself supplied.

**Deviation from spec.md, flagged here per CLAUDE.md §8:** spec.md Constraint §6.3 assumed a service registered as `AddScoped<IInterface, Implementation>`. This design supersedes that with a controller-only implementation, per this task's explicit key decision. No DI registration is needed in `Program.cs` beyond what already exists (`AddDbContext<PriorAuthDbContext>`). Recorded as an open item below for spec.md to be amended.

---

## Components Affected

**New files:**
- `backend/PriorAuth.API/Controllers/EligibilityController.cs` — new controller, `[Route("api/[controller]")]`, `[HttpPost("check")]` action. Contains the lookup, comparison, audit-write, and response-shaping logic inline (no service class).

**Modified files:**
- `backend/PriorAuth.API/DTOs/Dtos.cs` — append `EligibilityCheckRequest` and `EligibilityCheckResponse` records (CLAUDE.md §5 pattern: all DTOs live in this one file).
- `backend/PriorAuth.API/Models/Entities.cs` — append `EligibilityCheck` entity, `[Table("eligibility_checks")]`.
- `backend/PriorAuth.API/Data/PriorAuthDbContext.cs` — add `DbSet<EligibilityCheck> EligibilityChecks`.
- `database/init.sql` — add `CREATE TABLE eligibility_checks (...)` (no EF migrations in this repo — schema changes go here, per CLAUDE.md "Backend commands").
- `frontend/src/api/client.ts` — add an `eligibility.check(patientId, healthPlanId)` method (the only place `fetch` is called, per CLAUDE.md architecture notes).
- `frontend/src/types/index.ts` — add a type mirroring `EligibilityCheckResponse`.
- `frontend/src/pages/NewAuthorizationPage.tsx` — wizard step 4 (member selection): trigger the check once both a member and health plan are selected, display the ELIGIBLE/INELIGIBLE/ERROR result, do not block "Next" (FR-08, FR-05).

**Explicitly NOT modified** (spec.md Constraint §6.1):
- `MembersController.cs`, `HealthPlansController.cs`, `AuthorizationsController.cs`
- `Member`, `HealthPlan`, `Authorization` entities and their existing columns
- `Program.cs` — no new service registration, since there is no service class

---

## Data Handling Design

- **Request input handling:** `patientId` and `healthPlanId` arrive in the POST body and are used only in-memory, transiently, for two primary-key EF Core lookups (`_db.Members.FindAsync(patientId)`, `_db.HealthPlans.FindAsync(healthPlanId)`) and the resulting plan-code comparison (`member.PlanCode == healthPlan.PlanCode`, ordinal string equality — resolved field per spec.md OQ-01). They are never passed to `ILogger`, never written to a file, and never persisted into the audit record. Per the key decision **"PHI in request input only — not stored raw, not logged"**, they are permitted to be echoed back in the synchronous HTTP response body (spec.md §4.3), since that response returns directly to the same wizard session that submitted it — it is not a log, and not a persistent store.
- **EF Core LINQ only, no raw SQL** (CLAUDE.md §2.1/§3.1, spec.md Constraint §6.4) — both lookups are `FindAsync` primary-key reads; the comparison is an in-memory equality check, not a SQL join.
- **Audit persistence — narrowed per key decision:** the `EligibilityCheck` entity stores **only** `CorrelationId` (Guid), `Status` (string: `ELIGIBLE`/`INELIGIBLE`/`ERROR`), `CheckedAt` (UTC timestamp), and `DataSource` (string, `"LOCAL_DB"` for Phase 1 — reserved for `"PAYER_API"` in Phase 2). It does **not** store `patientId`, `healthPlanId`, `errorCode`, or any name/demographic field.
  - spec.md §9 OQ-02 has been updated to match this schema (it previously proposed including `patient_id`/`health_plan_id` in `eligibility_checks` for traceability; that draft no longer appears in spec.md).
- **DataSource field** is new relative to spec.md — it is not in the spec's API contract or audit description. It exists purely on the audit record (not in the API response) to make Phase 1 vs. Phase 2 checks distinguishable in the audit trail once real-time payer calls are added.

---

## Security / Privacy Considerations

Per `risk-classification.md`: this change involves PHI/identity data (YES) and affects audit/compliance evidence (YES) — both flagged as requiring review. It does not touch authentication/authorization, clinical/claims/billing logic, or external tool access (all NO).

Mitigations applied in this design:
1. **No PHI persisted anywhere new.** The `eligibility_checks` audit table carries only `correlationId`, `status`, `checkedAt`, `dataSource` — even a direct query or breach of this new table cannot link a check back to a specific member without cross-referencing application-level identifiers, which are themselves never logged (FR-07).
2. **Local-only lookup, Phase 1.** No external network call is made — member and health plan data never leave the local Postgres instance, eliminating third-party data-sharing risk for this phase (intent.md Phase 1 scope; spec.md Non-Goals).
3. **Request-scoped, non-persistent handling of identifiers.** `patientId`/`healthPlanId` exist only for the duration of the HTTP request/DB round trip — not cached, not written to disk, and excluded from any exception message surfaced to the caller (CLAUDE.md §4.1: never hardcode or log PHI-adjacent fields).
4. **Small, auditable surface area.** With no service/DI layer, all logic for this feature lives in one controller action, reducing the code surface a security reviewer needs to inspect end-to-end.

---

## Audit and Observability Considerations

- **Audit entry per check (FR-06):** exactly one `EligibilityCheck` row is written per call, containing `correlationId` + `checkedAt` + `status` + `dataSource` — satisfying CLAUDE.md §4.1's "ALWAYS write: one structured audit log entry per sensitive operation... Must contain: correlationId + timestamp + operation result."
- **Fields explicitly excluded** from the audit record and from any `ILogger` call: `patientId`, `healthPlanId`, `errorCode`, `errorMessage`, and every field on CLAUDE.md §4.1's PHI list. No full request or response payload is ever logged.
- **correlationId generation:** `Guid.NewGuid()` when the caller does not supply one (FR-06, CLAUDE.md §4.1 "ALWAYS generate: correlationId if not provided").
- **Unhandled-error path (`SYS-001`):** if the DB call throws, the exception is caught in the controller; any diagnostic logging includes only the correlationId and the exception's type/message — never the request body, never the `Data` dictionary — before returning HTTP 500.

---

## Test Strategy

This repo currently has no automated tests (CLAUDE.md) — this feature is expected to introduce the first ones for this endpoint.

- **Unit-level:** the ELIGIBLE/INELIGIBLE/ERROR decision itself (given a `Member` and a `HealthPlan`, or either being `null`) should be factored into a small pure/static helper method inside or alongside the controller — not a DI-registered service, but plain code — so the branching logic (spec.md FR-02/03/04) is testable without a live database. This is treated as consistent with "no separate service class," since it introduces no interface, no registration, and no injected dependency.
- **Integration-level:** exercise `POST /api/eligibility/check` end-to-end against the seeded Postgres data for AC-01, AC-02, AC-03, AC-04, AC-06, AC-12 (spec.md §8 Test Data table).
- **Test data:** exclusively the existing synthetic seed rows in `database/init.sql` (e.g. `PT001234`/`CIGNA` vs. health plan id 1/`CIGNA`) — confirmed synthetic only, consistent with `risk-classification.md` ("Does it rely on production-like data? NO — must use synthetic data").
- **AC-05 (NULL `plan_code`)** has no existing seed record (spec.md OQ-03, still OPEN) — needs either a new synthetic seed row or an in-memory/mocked member for the test; not resolved by this design note.
- **AC-07 (500ms) and AC-11 (UI)** remain manual/observational per spec.md — a lightweight stopwatch-based integration test for AC-07 is recommended if feasible within Phase 1, but is not mandated by this design.

---

## Rollback / Failure Handling

- **Additive only, per key decision.** This feature adds one controller, one entity, one DTO pair, one DB table, and small frontend additions. It modifies zero existing controllers, entities, columns, or DI registrations. Rollback is a straight revert of the commit(s) that introduced these files — no other feature's code or data path is touched.
- **DB rollback:** because `eligibility_checks` is created via `database/init.sql` (no EF migrations, per CLAUDE.md), removing the feature means deleting its `CREATE TABLE` block and running `docker compose down -v && docker compose up -d` — the standard reseed workflow already documented for this repo. No other table is affected by this reset beyond the normal full-reseed behavior that already applies to any `init.sql` change.
- **Runtime failure handling:** a DB/lookup failure is caught and returned as HTTP 500 `SYS-001` (spec.md §4.4) rather than propagating an unhandled exception. The frontend treats any non-ELIGIBLE/INELIGIBLE outcome (including ERROR) as "proceed allowed" (FR-05) — a failure in this feature degrades to "eligibility unknown," never a hard failure of the wizard.
- No feature flag is introduced — not required by spec.md, and unnecessary for a purely additive, non-blocking check.

---

## Open Questions

1. ~~**Audit schema mismatch with spec.md.**~~ **RESOLVED.** spec.md §9 OQ-02 has been updated to match this design's audit record (`correlationId`, `status`, `checkedAt`, `dataSource`) — the earlier draft schema including `patient_id`/`health_plan_id` no longer appears in spec.md.
2. **Approval-gate inconsistency in risk-classification.md.** Its Risk Questions state privacy/security review is required (PHI = YES) and audit evidence review is required, but its own "Required Human Review Gates" checklist leaves Security review and Privacy review unchecked. This design note formally adds Security review as a gate (per this task's explicit instruction); Privacy review is left for the human reviewer to confirm is/isn't also needed. [NON-BLOCKING]
3. **Carried forward from spec.md, unresolved:** OQ-03 (no seed member with NULL `plan_code`), OQ-04 (case-sensitivity of the plan-code match), OQ-05 (whether the 500ms budget is server-side only or end-to-end). All three affect this design's comparison logic and test strategy and remain OPEN. [NON-BLOCKING]
4. Whether a plain static/pure helper method for the ELIGIBLE/INELIGIBLE/ERROR decision (used only for unit-testability, not injected via DI) is consistent with "no separate service class." Assumed yes — a static helper is not a "service" in the DI sense this decision is ruling out. [NON-BLOCKING]

---

## Approval Gates

- [x] Architect / Tech lead review
- [x] Security review — added by this design note per the explicit key decision, correcting the gap noted in Open Question 2 above (risk-classification.md's risk answers justify it even though its own checklist left it unchecked)
- [ ] Privacy review — not designated as a gate by this task's instruction; risk-classification.md's risk answers (PHI = YES) would also justify one — left for human reviewer to confirm
- [ ] Domain SME review — not required (risk-classification.md: clinical/claims/billing/payment logic = NO)
- [x] QA / validation review — carried over from risk-classification.md's own checked gate
