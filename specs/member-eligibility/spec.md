# SPEC.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/spec.md
# Committed : YES
# Status    : DRAFT
# Author    : Claude Code | Date: 2026-09-10
# Branch    : feature/member-eligibility
#
# PURPOSE: Define WHAT the feature does and WHY — not HOW.
# HOW is answered in PLAN.md.
# EVERY acceptance criterion must trace to a verifiable test.
# ─────────────────────────────────────────────────────────────

---

## Risk Classification

Risk Level: **Medium** (see `Specs/member-eligibility/risk-classification.md`).
Involves PHI/identity data and affects audit/compliance evidence — privacy and audit evidence review required. Tech lead, QA/validation, and product owner review are the required human gates before implementation proceeds.

---

## 1. Overview

### 1.1 Problem Statement
Non-clinical intake agents creating prior authorization (PA) requests have no way to verify, at the point of intake, whether the member they selected is actually enrolled in the health plan they selected. Because the wizard does not check this, mismatches between member and plan are only discovered after submission, causing rework.

### 1.2 Proposed Solution
Add a local, database-only eligibility check to step 4 (member selection) of the PA request wizard. When an agent has selected both a member and a health plan, the system compares the member's `plan_code` to the health plan's `plan_code` and returns one of three statuses: ELIGIBLE, INELIGIBLE, or ERROR. The check is advisory — it does not block PA creation — and every check is recorded in an audit log containing no PHI.

### 1.3 Success Criteria
The agent can trigger an eligibility check from wizard step 4 and receive ELIGIBLE, INELIGIBLE, or ERROR within 500ms, with one PHI-free audit record written per check, zero `dotnet build` warnings, and a COMPLIANT result from `/hipaa-check`.

---

## 2. Functional Requirements

### 2.1 Core Behaviour
When an intake agent has chosen a member and a health plan in the wizard, they can request an eligibility check. The system looks up the member and the health plan by their identifiers. If either does not exist, the result is ERROR. If both exist, the system compares the member's plan code to the health plan's plan code: an exact match is ELIGIBLE; anything else (a different code, or the member's plan code being absent) is INELIGIBLE. The result is shown to the agent, who may proceed with PA creation regardless of the result. Every check — regardless of outcome — produces exactly one audit record containing a correlation ID, a timestamp, and the result, but no member or provider identifying/demographic data.

FR-01: The system shall provide an endpoint that accepts a member identifier and a health plan identifier and returns an eligibility status.
FR-02: The system shall return ELIGIBLE when the member exists, the health plan exists, and the member's `plan_code` equals the health plan's `plan_code` (case-sensitive exact match, per CLAUDE.md §4.1 no invented normalization rules).
FR-03: The system shall return INELIGIBLE when the member exists, the health plan exists, and the member's `plan_code` does not equal the health plan's `plan_code` — including when the member's `plan_code` is NULL.
FR-04: The system shall return ERROR when the member is not found, the health plan is not found, or both. When both are missing, the system shall check the member first and return error code `MBR-001` (member-not-found takes precedence over health-plan-not-found).
FR-05: The system shall not block or alter PA request submission based on the eligibility result — the check is advisory only.
FR-06: The system shall write exactly one audit record per eligibility check, containing a correlation ID, a UTC timestamp, and the result status, and shall generate a correlation ID via `Guid.NewGuid()` if the caller does not supply one.
FR-07: The system shall not include any PHI field (per CLAUDE.md §4.1) in the audit record, in any log entry, or in any error message produced by this feature.
FR-08: The frontend shall surface the eligibility check as part of wizard step 4 (member selection), displaying the result to the agent without preventing further progress through the wizard.

### 2.2 User Flows

**Flow 1 — Eligible member:**
1. Agent selects a member and a health plan in wizard step 4.
2. System calls the eligibility endpoint with the member's `patientId` and the health plan's `healthPlanId`.
3. System finds both records; member's `plan_code` matches the health plan's `plan_code`.
4. System returns ELIGIBLE and writes one audit record.
5. Agent sees an ELIGIBLE indicator and continues the wizard.

**Flow 2 — Ineligible member (plan mismatch):**
1. Agent selects a member and a health plan in wizard step 4.
2. System calls the eligibility endpoint.
3. System finds both records; member's `plan_code` does not match (or is NULL).
4. System returns INELIGIBLE and writes one audit record.
5. Agent sees an INELIGIBLE indicator but can still proceed to submit the PA request.

**Flow 3 — Member or plan not found:**
1. Agent selects a member/plan combination where one identifier does not resolve to a record (e.g., stale selection).
2. System calls the eligibility endpoint.
3. System cannot find the member and/or the health plan.
4. System returns ERROR (no PHI in the error body) and writes one audit record.
5. Agent sees an ERROR indicator but can still proceed to submit the PA request.

---

## 3. Acceptance Criteria
*Each criterion: testable, binary (pass/fail), observable (Swagger / log / test)*
*No "should", "mostly", or "approximately"*

| ID    | Given | When | Then | Verified By |
|-------|-------|------|------|-------------|
| AC-01 | A valid request with patientId `PT001234` and healthPlanId for Cigna (`plan_code = CIGNA`) | POST /api/eligibility/check is called | Response is HTTP 200 with status ELIGIBLE | Swagger |
| AC-02 | A valid request with patientId `PT001235` (`plan_code = AETNA`) and healthPlanId for Cigna (`plan_code = CIGNA`) | POST /api/eligibility/check is called | Response is HTTP 200 with status INELIGIBLE | Swagger |
| AC-03 | A request with a patientId that does not exist in `members` | POST /api/eligibility/check is called | Response is HTTP 200 with status ERROR and an error code, no HTTP 4xx/5xx | Swagger |
| AC-04 | A request with a healthPlanId that does not exist in `health_plans` | POST /api/eligibility/check is called | Response is HTTP 200 with status ERROR and an error code | Swagger |
| AC-05 | A member whose `plan_code` is NULL, checked against any health plan | POST /api/eligibility/check is called | Response is HTTP 200 with status INELIGIBLE | Swagger |
| AC-06 | A malformed request body (missing patientId or healthPlanId) | POST /api/eligibility/check is called | Response is HTTP 400 | Swagger |
| AC-07 | Any valid eligibility check | Is executed | Response is returned within 500ms | Manual timing / test |
| AC-08 | Any eligibility check (ELIGIBLE, INELIGIBLE, or ERROR) | Is executed | Exactly one audit record is written with correlationId, timestamp, and status | Log/DB inspection |
| AC-09 | Any generated code for this feature | Is scanned | No PHI field names (per CLAUDE.md §4.1) appear in any ILogger call or audit record | `/hipaa-check` COMPLIANT |
| AC-10 | All code changes for this feature | `dotnet build` is run | Zero errors, zero warnings | Build output |
| AC-11 | Wizard step 4 with a member and health plan selected | Agent triggers the eligibility check in the UI | Result (ELIGIBLE/INELIGIBLE/ERROR) is displayed and the agent can still advance the wizard | Manual UI test |
| AC-12 | A request where both patientId and healthPlanId do not exist | POST /api/eligibility/check is called | Response is HTTP 200 with status ERROR and errorCode `MBR-001` (member-not-found takes precedence) | Swagger |

---

## 4. API Contract

### 4.1 Endpoint
```
POST /api/eligibility/check
Content-Type: application/json
```

### 4.2 Request Schema
```json
{
  "patientId": "PT001234",
  "healthPlanId": 1,
  "correlationId": null
}
```

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| patientId | string | Yes | Non-empty | Member's `patient_id` (e.g. `PT001234`) |
| healthPlanId | integer | Yes | Positive integer | `health_plan_id` from `health_plans` |
| correlationId | string (GUID) | No | Valid GUID if provided | Generated via `Guid.NewGuid()` if omitted |

### 4.3 Response Schema
```json
{
  "status": "ELIGIBLE",
  "patientId": "PT001234",
  "healthPlanId": 1,
  "correlationId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "checkedAt": "2026-09-10T14:32:00Z",
  "errorCode": null,
  "errorMessage": null
}
```

| Field | Type | Notes |
|-------|------|-------|
| status | string | One of `ELIGIBLE`, `INELIGIBLE`, `ERROR` |
| patientId | string | Echoed from request |
| healthPlanId | integer | Echoed from request |
| correlationId | string | Echoed if supplied, else generated |
| checkedAt | string (ISO-8601 UTC) | Server timestamp of the check |
| errorCode | string \| null | Populated only when status is ERROR |
| errorMessage | string \| null | Populated only when status is ERROR; must not contain PHI |

### 4.4 Error Responses

| HTTP Status | Error Code | Trigger |
|-------------|------------|---------|
| 200 | `MBR-001` | Member (`patientId`) not found — returned in body as status ERROR, not as HTTP error. Takes precedence when both member and health plan are not found. |
| 200 | `PLN-001` | Health plan (`healthPlanId`) not found and the member was found — returned in body as status ERROR |
| 400 | — | Malformed request body (missing/invalid `patientId` or `healthPlanId`, or `correlationId` present but not a valid GUID) |
| 500 | `SYS-001` | Unhandled internal error (e.g. database unavailable) |

---

## 5. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Response time under 500ms for the local DB lookup (per intent.md Success Criteria) |
| Security | No PHI in logs, audit records, or error messages (CLAUDE.md §4.1) |
| Compliance | One structured, PHI-free audit record per check, containing correlationId + timestamp + result (CLAUDE.md §4.1) |
| Reliability | Database/lookup failure returns HTTP 500 with `SYS-001` rather than an unhandled exception; does not block wizard progression |

---

## 6. Constraints
*What MUST be respected — derived from CLAUDE.md*

1. Zero modification to existing controllers, services, or entities (`Member`, `HealthPlan`, `MembersController`, `HealthPlansController` stay untouched — new endpoint lives in its own controller/service).
2. Route follows `/api/[controller]` convention — `/api/eligibility/check` (CLAUDE.md §6).
3. New eligibility service registered as `AddScoped<IInterface, Implementation>` in `Program.cs` (CLAUDE.md §7) — no `AddSingleton`, no `AddTransient`, no manual `new`.
4. EF Core LINQ only — no raw SQL (CLAUDE.md §2.1, §3.1).
5. No PHI in any `ILogger` call — CLAUDE.md §4.1 field list applies in full.
6. No hardcoded connection strings, API keys, or tokens (CLAUDE.md §4.1).
7. No new NuGet or npm packages without updating CLAUDE.md §9 (this feature is scoped to require none).
8. Build must pass with zero errors and zero warnings (CLAUDE.md §3.1).
9. The audit table (`eligibility_checks`) is added as a new EF Core entity in `Models/Entities.cs` plus a matching `CREATE TABLE` in `database/init.sql`, following this repo's documented convention for entity changes (CLAUDE.md "Backend commands": no EF migrations — edit `init.sql` directly, then reset the DB volume with `docker compose down -v && docker compose up -d`). It must not modify the existing `authorizations`, `members`, or `health_plans` table definitions.
10. Naming for new artifacts follows CLAUDE.md §5: `EligibilityController.cs`, `EligibilityCheckRequest`/`EligibilityCheckResponse` records in `DTOs/Dtos.cs`, `EligibilityCheck` entity in `Models/Entities.cs`.

---

## 7. Non-Goals
*MINIMUM 4 entries — what this spec explicitly does NOT include*

- ❌ Real-time payer/health-plan API integration — explicitly deferred to Phase 2 (intent.md).
- ❌ Blocking PA submission when the result is INELIGIBLE — check is advisory only (intent.md).
- ❌ Date-based eligibility (effective/termination date checking) — explicitly out of scope (intent.md).
- ❌ Benefit-level or procedure-specific coverage eligibility — explicitly out of scope (intent.md).
- ❌ Caching of eligibility results across requests — not mentioned in intent.md, not required by success criteria.
- ❌ Role-based access control / authentication changes on this endpoint — not mentioned in intent.md; existing app has no auth layer to extend.

---

## 8. Test Data
*Exact records that must exist for ACs to pass — sourced from `database/init.sql`*

| patientId | plan_code (member) | healthPlanId | plan_code (health plan) | Expected AC Result |
|-----------|--------------------|--------------|--------------------------|---------------------|
| PT001234 | CIGNA | 1 (Cigna Health, plan_code=CIGNA) | CIGNA | ELIGIBLE (AC-01) |
| PT001235 | AETNA | 1 (Cigna Health, plan_code=CIGNA) | CIGNA | INELIGIBLE (AC-02) |
| PT999999 (does not exist) | N/A | 1 | CIGNA | ERROR MBR-001 (AC-03) |
| PT001234 | CIGNA | 9999 (does not exist) | N/A | ERROR PLN-001 (AC-04) |
| PT999999 (does not exist) | N/A | 9999 (does not exist) | N/A | ERROR MBR-001 (AC-12) |

Note: no existing member in `database/init.sql` has a NULL `plan_code` (AC-05) — a test-only record or a mocked scenario is required for that case; this is flagged in Open Questions (OQ-03).

---

## 9. Open Questions
*Claude writes here when uncertain — human resolves before PLAN.md is written*

| ID | Question | Tag | Assumption | Status |
|----|----------|-----|------------|--------|
| OQ-01 | `health_plans` has two similar-looking code columns: `plan_code` and `ins_plan_code`. intent.md says "health plan's `plan_code`" — is that literally the `plan_code` column, or was `ins_plan_code` intended? | [BLOCKING] | **RESOLVED from seed data, not just wording.** `database/init.sql` shows `health_plans.plan_code` values (`CIGNA`, `AETNA`, `UHC`, ...) exactly matching `members.plan_code` values, while `ins_plan_code` holds a distinct insurer billing code (`CIG001`, `AET001`, `UHC001`, ...) that never appears on `members`. Confirmed: the match uses `health_plans.plan_code`. | RESOLVED |
| OQ-02 | intent.md requires "one DB record per check" for audit but does not specify a schema, table name, or retention policy for this audit table. Additionally, this repo has no EF migrations — does adding a table require a destructive DB reset? | [NON-BLOCKING] → **RESOLVED** | Per CLAUDE.md's own "Backend commands" section (no migrations — edit `database/init.sql` directly, then reset the DB volume), the resolution is: add an `EligibilityCheck` EF entity + `eligibility_checks` table via `database/init.sql`, applied with `docker compose down -v && docker compose up -d`. Minimal schema: `id` (serial PK), `correlation_id` (uuid/text), `checked_at` (timestamptz), `patient_id` (text), `health_plan_id` (int, nullable — may not resolve), `status` (text: ELIGIBLE/INELIGIBLE/ERROR), `error_code` (text, nullable). No PHI fields per CLAUDE.md §4.1. See Constraint §6.9. | RESOLVED |
| OQ-03 | intent.md's INELIGIBLE definition includes "member.plan_code = NULL" but no seed member currently has a NULL `plan_code`, so AC-05 has no natural test record. | [NON-BLOCKING] | Assumed a test-only member row (or a unit test with a mocked repository) will be used to exercise the NULL-plan_code path rather than modifying seed data. | OPEN |
| OQ-04 | intent.md does not specify whether the match in "member.plan_code = health_plan.plan_code" is case-sensitive. Seed values are all upper-case, so this may never surface, but the comparison rule isn't stated. | [NON-BLOCKING] | Assumed exact, case-sensitive string equality (ordinal comparison), consistent with EF Core LINQ default behavior and no normalization logic mentioned anywhere in the inputs. | OPEN |
| OQ-05 | intent.md's Success Criteria says "System returns ELIGIBLE, INELIGIBLE, or ERROR within 500ms" but doesn't state whether this is measured server-side (API response time) or end-to-end (including UI round-trip). | [NON-BLOCKING] | Assumed server-side API response time (from request received to response sent), since that is what an ASP.NET Core API can directly guarantee and test. | OPEN |
| OQ-06 | intent.md doesn't specify the HTTP method/route naming, only implies a check operation. CLAUDE.md §6 shows the example route `POST /api/eligibility/check` directly, so this one is treated as settled rather than open — included here only for traceability. | [NON-BLOCKING] | Used `POST /api/eligibility/check` per CLAUDE.md §6's own worked example. | RESOLVED |
| OQ-07 | When both `patientId` and `healthPlanId` fail to resolve, which error code takes precedence? | [NON-BLOCKING] → **RESOLVED** | Member-not-found (`MBR-001`) takes precedence, since the member is the primary subject of "member eligibility." Reflected in FR-04, §4.4, and AC-12. | RESOLVED |
