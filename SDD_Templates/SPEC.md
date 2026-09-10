# SPEC.md — [Feature Name]
# Location : specs/[NNN-feature-name]/spec.md
# Committed : YES
# Status    : DRAFT → REVIEWED → APPROVED → IN PROGRESS → DONE
# Author    : [Name] | Date: [DATE]
# Branch    : feature/[NNN-feature-name]
#
# PURPOSE: Define WHAT the feature does and WHY — not HOW.
# HOW is answered in PLAN.md.
# EVERY acceptance criterion must trace to a verifiable test.
# ─────────────────────────────────────────────────────────────

---

## 1. Overview

### 1.1 Problem Statement
[What problem does this feature solve? One paragraph.]

### 1.2 Proposed Solution
[High-level description of the solution. Two to three sentences.]

### 1.3 Success Criteria
[How do we know this feature is done and working? One sentence.]

---

## 2. Functional Requirements

### 2.1 Core Behaviour
[Describe what the feature does in plain language — no technical details yet.]

FR-01: [The system shall...]
FR-02: [The system shall...]
FR-03: [The system shall...]

### 2.2 User Flows
[Who does what, in what sequence]

**Flow 1 — [Name]:**
1. [Actor] [action]
2. System [response]
3. [Actor] [next action]

---

## 3. Acceptance Criteria
*Each criterion: testable, binary (pass/fail), observable (Swagger / log / test)*
*No "should", "mostly", or "approximately"*

| ID    | Given | When | Then | Verified By |
|-------|-------|------|------|-------------|
| AC-01 | A valid request with memberId PT001234 | POST /api/eligibility/check is called | Response is HTTP 200 with status ELIGIBLE | Swagger |
| AC-02 | [Given] | [When] | [Then] | [How verified] |
| AC-03 | [Given] | [When] | [Then] | [How verified] |
| AC-04 | [Given] | [When] | [Then] | [How verified] |
| AC-05 | [Given] | [When] | [Then] | [How verified] |
| AC-06 | [Given] | [When] | [Then] | [How verified] |
| AC-07 | [Given] | [When] | [Then] | [How verified] |
| AC-08 | Any eligibility check | Is executed | One audit log entry written with correlationId + status, no PHI | Log inspection |
| AC-09 | Any generated code | Is scanned | No PHI field names appear in any ILogger call | /hipaa-check COMPLIANT |
| AC-10 | All code changes | dotnet build is run | Zero errors, zero warnings | Build output |

---

## 4. API Contract

### 4.1 Endpoint
```
[HTTP VERB] /api/[route]
Content-Type: application/json
```

### 4.2 Request Schema
```json
{
  "fieldName": "example value",
  "fieldName2": "example value",
  "optionalField": "example value"
}
```

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| [field] | string | Yes | [rules] | [notes] |
| [field] | string | No | [rules] | Generated if not provided |

### 4.3 Response Schema
```json
{
  "fieldName": "example value",
  "nestedObject": {
    "nestedField": "example value"
  },
  "arrayField": ["item1"],
  "errorCode": null,
  "errorMessage": null
}
```

### 4.4 Error Responses

| HTTP Status | Error Code | Trigger |
|-------------|------------|---------|
| 200 | [ERR-001] | [condition — returned in body, not as HTTP error] |
| 400 | — | Malformed request body |
| 500 | SYS-001 | Unhandled internal error |

---

## 5. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | [e.g. Response time < 1s for local lookup] |
| Security | [e.g. No PHI in logs or error messages] |
| Compliance | [e.g. HIPAA audit trail for every check] |
| Reliability | [e.g. Graceful error response on DB failure] |

---

## 6. Constraints
*What MUST be respected — derived from CLAUDE.md*

1. [e.g. Zero modification to existing controllers, services, or entities]
2. [e.g. Route follows /api/[controller] convention from CLAUDE.md section 6]
3. [e.g. All new services registered as AddScoped in Program.cs]
4. [e.g. EF Core LINQ only — no raw SQL]
5. [e.g. No PHI in ILogger calls — CLAUDE.md section 4.1]
6. [e.g. No new NuGet packages without updating CLAUDE.md section 9]

---

## 7. Non-Goals
*MINIMUM 4 entries — what this spec explicitly does NOT include*
*Every item is something the requirements document mentions or implies*

- ❌ [Feature deferred to Phase 2 — e.g. Real-time health plan API calls]
- ❌ [Integration out of scope — e.g. Caching of eligibility results]
- ❌ [UI not in this spec — e.g. React UI changes]
- ❌ [Performance feature not asked for — e.g. Retry logic with backoff]
- ❌ [Security feature in separate spec — e.g. Role-based access control]

---

## 8. Test Data
*Exact records that must exist for ACs to pass*

| ID | Field2 | Field3 | Field4 | Expected AC Result |
|----|--------|--------|--------|--------------------|
| [PT001234] | [1985-03-15] | [ACTIVE] | [CIGNA] | ELIGIBLE (AC-01, AC-03) |
| [PT001236] | [1978-11-08] | [INACTIVE] | [CIGNA] | INELIGIBLE (AC-04) |
| [UNKNOWN] | [any] | [N/A] | [N/A] | ERROR MBR-001 (AC-05) |

---

## 9. Open Questions
*Claude writes here when uncertain — human resolves before PLAN.md is written*

| ID | Question | Tag | Assumption | Status |
|----|----------|-----|------------|--------|
| OQ-01 | [Question] | [BLOCKING] | N/A — must resolve | OPEN |
| OQ-02 | [Question] | [NON-BLOCKING] | [Assumption made] | OPEN |
