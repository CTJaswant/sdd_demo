# TASKS.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/tasks.md
# Committed : YES
# Status    : IN PROGRESS
# Author    : Claude Code | Date: 2026-09-10
# Depends on: plan.md DRAFT (§3.1 note updated to reflect spec.md OQ-02 sync)
#
# PURPOSE: Dependency-ordered, executable task list.
#          Each task is small enough for one Claude Code session.
#          Each task has a clear done condition.
#          Claude executes these in order — one task per session.
#
# RULES:
#   - Never skip a task
#   - Never combine tasks from different phases
#   - Mark [x] when done before starting the next task
#   - Run /spec-review after every phase
#   - Run /hipaa-check after Phase 3
# ─────────────────────────────────────────────────────────────

---

## Regeneration Note

This file was regenerated from the current plan.md (2026-09-10). plan.md's substance is unchanged from the version this file was originally derived from — only its §3.1 note was edited to reflect that spec.md §9 OQ-02 now matches the implemented audit schema. Task content below is therefore identical to the prior tasks.md, **except** that Phase 1's completion status is carried forward from the actual state of the code (Tasks 1.1/1.3/1.4 already executed and build-verified this session; Task 1.2 partially done) — regenerating this file does not roll back real progress already made.

---

## Scope Note

plan.md is backend-only (see its Scope Note). Phase 4 (Frontend) is therefore listed as **deferred / out of scope**, not as executable tasks — generating frontend tasks here would invent work beyond what plan.md specifies. spec.md AC-11 cannot be closed until a follow-up plan covers `api/client.ts`, `types/index.ts`, and `NewAuthorizationPage.tsx`.

---

## Progress

- Phase 1 — Model Layer     : [x] Done (DB schema applied via psql — native Postgres, not Docker; see Notes in eval.md)
- Phase 2 — Data Layer      : [x] Done
- Phase 3 — Controller      : [x] Done
- Phase 4 — Frontend        : DEFERRED — out of scope for this plan (see Scope Note)
- Phase 5 — Verification    : [x] Done — 11/11 blocking ACs PASS, AC-11 N/A (deferred)

---

## Phase 1 — Model Layer
*No dependencies — start here*
*Pattern references: read `Entities.cs`, `DTOs/Dtos.cs`, and `database/init.sql` before any task (plan.md §2.1, §3.1, §3.2)*

---

### Task 1.1 — Add `EligibilityCheck` entity
**File:** `backend/PriorAuth.API/Models/Entities.cs`
**Pattern reference:** Existing `[Table]`/`[Column]` entities in this file (e.g. `HealthPlan`) — read before starting
**Action:** Append the following class at the end of the file. Do not modify any existing class.

```csharp
[Table("eligibility_checks")]
public class EligibilityCheck
{
    [Key, Column("id")]
    public int Id { get; set; }

    [Column("correlation_id")]
    public Guid CorrelationId { get; set; }

    [Column("status")]
    public string Status { get; set; } = string.Empty;

    [Column("checked_at")]
    public DateTime CheckedAt { get; set; } = DateTime.UtcNow;

    [Column("data_source")]
    public string DataSource { get; set; } = "LOCAL_DB";
}
```
(plan.md §3.1 — exact schema, no `patientId`/`healthPlanId`/`errorCode` columns; matches spec.md §9 OQ-02)

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-08 (audit record schema), AC-09 (no PHI fields on the entity)
**Status:** [x] Done — build verified 0 errors/0 warnings

---

### Task 1.2 — Add `eligibility_checks` table to `database/init.sql`
**File:** `database/init.sql`
**Pattern reference:** Existing `CREATE TABLE` blocks in this file (e.g. `health_plans`) — read before starting
**Action:** Append at the end of the file (do not modify any existing `CREATE TABLE` or `INSERT` statement):

```sql
CREATE TABLE eligibility_checks (
    id SERIAL PRIMARY KEY,
    correlation_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_source VARCHAR(20) NOT NULL DEFAULT 'LOCAL_DB'
);
```
(plan.md §3.2)

**Done when:** `docker compose down -v && docker compose up -d` completes, `docker compose ps` shows `pa_db` healthy, and the table exists in the running database
**AC covered:** AC-08 (backing store for the audit record)
**Status:** [x] Done — with a deviation: this environment runs Postgres as a native Windows service (Docker is not installed here), so `docker compose down -v && up -d` could not be run. Applied the identical `CREATE TABLE` DDL directly via `psql` instead, non-destructively (no existing data was wiped). Verified via `\dt` and a live end-to-end request. See CLAUDE.md "Patterns Added" and eval.md Notes.

---

### Task 1.3 — Add `EligibilityCheckRequest` DTO
**File:** `backend/PriorAuth.API/DTOs/Dtos.cs`
**Pattern reference:** Existing request record `CreateAuthorizationRequest` — read before starting
**Action:** Append at the end of the file:

```csharp
public record EligibilityCheckRequest(
    string PatientId,
    int HealthPlanId,
    string? CorrelationId
);
```
(spec.md §4.2 / plan.md §4.2 — `CorrelationId` nullable, matches "generated if not provided")

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-06 (request shape backs the 400-on-malformed-body check), AC-01, AC-02, AC-03, AC-04, AC-12 (request shape required for every check call)
**Status:** [x] Done — build verified 0 errors/0 warnings

---

### Task 1.4 — Add `EligibilityCheckResponse` DTO
**File:** `backend/PriorAuth.API/DTOs/Dtos.cs`
**Pattern reference:** Existing response record `AuthorizationSummaryDto` — add after the request record from Task 1.3
**Action:**

```csharp
public record EligibilityCheckResponse(
    string Status,
    string PatientId,
    int HealthPlanId,
    string CorrelationId,
    DateTime CheckedAt,
    string? ErrorCode,
    string? ErrorMessage
);
```
(spec.md §4.3 / plan.md §4.2 — field list and nullability exactly as specified)

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-01, AC-02, AC-03, AC-04, AC-12 (response shape carries the `status`/`errorCode` fields these ACs assert on)
**Status:** [x] Done — build verified 0 errors/0 warnings

**→ Run /spec-review after this task.** (Already run this session — see spec-review report: AC-10 PASS, all others NOT_YET pending Phase 2/3.)

---

## Phase 2 — Data Layer
*Depends on: Phase 1 complete (Task 1.2's DB reset still pending — see note below)*
*Pattern reference: read `PriorAuthDbContext.cs` before starting (plan.md §2.2)*

---

### Task 2.1 — Register `EligibilityCheck` in `PriorAuthDbContext`
**File:** `backend/PriorAuth.API/Data/PriorAuthDbContext.cs`
**Pattern reference:** Existing `DbSet<T>` properties (e.g. `DbSet<Member> Members`) — read before starting
**Action:** One addition only:

```
Add: public DbSet<EligibilityCheck> EligibilityChecks { get; set; }
No OnModelCreating change — EligibilityCheck is standalone, no FK relationships (plan.md §2.2/§3.1).
No changes to any existing DbSet or existing OnModelCreating configuration.
```

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-08 (audit persistence path)
**Status:** [x] Done — build verified 0 errors/0 warnings

**→ Run /spec-review after this task.**

---

## Phase 3 — Controller
*Depends on: Phases 1 and 2 complete*
*Pattern reference: read `AuthorizationsController.cs` before starting — inline-logic controller pattern, hand-mapped DTOs, no service layer (plan.md §2.1, §1)*

---

### Task 3.1 — Create `EligibilityController`
**File:** `backend/PriorAuth.API/Controllers/EligibilityController.cs` ← NEW FILE
**Pattern reference:** `AuthorizationsController.cs`
**Action:** Implement exactly the flow in plan.md §4.1–§4.2 — no service/interface, inject `PriorAuthDbContext` only:

```
Route: [Route("api/[controller]")]
Action: [HttpPost("check")]

1. Validate patientId non-empty, healthPlanId > 0, correlationId (if present) is a valid GUID
   → invalid → HTTP 400 (model validation)
2. correlationId = request.CorrelationId ?? Guid.NewGuid()
3. member = await _db.Members.FindAsync(patientId)
   → null → status = ERROR, errorCode = MBR-001
   → else: healthPlan = await _db.HealthPlans.FindAsync(healthPlanId)
        → null → status = ERROR, errorCode = PLN-001
        → else: status = (member.PlanCode == healthPlan.PlanCode) ? ELIGIBLE : INELIGIBLE
                (ordinal string comparison; NULL member.PlanCode → INELIGIBLE)
4. Write ONE EligibilityCheck row: { CorrelationId, Status, CheckedAt = DateTime.UtcNow, DataSource = "LOCAL_DB" }
   — do NOT persist patientId, healthPlanId, or errorCode on this entity
5. await _db.SaveChangesAsync()
6. Return 200 OK with EligibilityCheckResponse { status, patientId, healthPlanId, correlationId, checkedAt, errorCode, errorMessage }
7. On unhandled exception: catch, log ONLY correlationId + exception type (no request body, no PHI) via ILogger, return HTTP 500 SYS-001
```

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-01, AC-02, AC-03, AC-04, AC-05, AC-06, AC-08, AC-09, AC-12
**Status:** [x] Done — build verified 0 errors/0 warnings

---

### Task 3.2 — Verify `Program.cs` needs no change
**File:** `backend/PriorAuth.API/Program.cs`
**Pattern reference:** CLAUDE.md §7 (AddScoped-only DI rule); existing `AddControllers()`/`MapControllers()` calls already in this file
**Action:**

```
Per plan.md §2.2 and design-note.md's no-service-layer decision:
confirm NO new AddScoped<IInterface, Implementation> line is needed,
since EligibilityController injects only PriorAuthDbContext (already registered).
Do NOT add a placeholder or unused service registration.
Verify only that EligibilityController is picked up by the existing
AddControllers()/MapControllers() registration.
```

**Done when:** `dotnet build` passes with zero errors, zero warnings; `dotnet run` starts without error; `POST /api/eligibility/check` appears in Swagger UI at `/swagger` with no `Program.cs` edit required
**AC covered:** AC-10 (build/run integrity); confirms plan.md §8 DI compliance item
**Status:** [ ] Done

**→ Run /hipaa-check. Must show COMPLIANT before Phase 4.**
**→ Run /spec-review. All ACs should be PASS or GAP — no FAIL.**

---

## Phase 4 — Frontend
**DEFERRED — out of scope for this plan.** plan.md's Scope Note and Section 5 explicitly exclude `api/client.ts`, `types/index.ts`, and `NewAuthorizationPage.tsx` changes from this plan. No tasks are generated here to avoid inventing work beyond what plan.md specifies. **spec.md AC-11 remains open** until a follow-up plan covers this phase.

---

## Phase 5 — Verification
*Run after Phases 1–3 complete (Phase 4 deferred)*

---

### Task 5.1 — Runtime AC verification
Test each backend AC in Swagger (`http://localhost:5000/swagger`), using spec.md §8 Test Data:

| AC | Test Input | Expected | Pass? |
|----|------------|----------|-------|
| AC-01 | patientId `PT001234`, healthPlanId `1` (Cigna, plan_code=CIGNA) | HTTP 200, status ELIGIBLE | [x] PASS |
| AC-02 | patientId `PT001235`, healthPlanId `1` (Cigna, plan_code=CIGNA) | HTTP 200, status INELIGIBLE | [x] PASS |
| AC-03 | patientId `PT999999` (unknown), healthPlanId `1` | HTTP 200, status ERROR, errorCode MBR-001 | [x] PASS |
| AC-04 | patientId `PT001234`, healthPlanId `9999` (unknown) | HTTP 200, status ERROR, errorCode PLN-001 | [x] PASS |
| AC-05 | member with NULL plan_code (test-only record, per spec.md OQ-03) vs any health plan | HTTP 200, status INELIGIBLE | [x] PASS — temp test record `PTTEST01` used and deleted after |
| AC-06 | missing patientId or healthPlanId | HTTP 400 | [x] PASS |
| AC-08 | any valid or ERROR check | One `eligibility_checks` row written with correlationId, status, checkedAt, dataSource | [x] PASS — 5 rows for 5 valid calls, verified via psql |
| AC-09 | any generated code for this feature | `/hipaa-check` returns COMPLIANT | [x] PASS — COMPLIANT |
| AC-10 | all code changes | `dotnet build` — zero errors, zero warnings | [x] PASS — verified 5× this session |
| AC-12 | patientId `PT999999` AND healthPlanId `9999` (both unknown) | HTTP 200, status ERROR, errorCode MBR-001 (precedence) | [x] PASS |
| AC-11 | N/A — frontend deferred, see Phase 4 | Not testable until follow-up plan | [ ] N/A — deferred |
| AC-07 | any valid check | Response returned within 500ms (manual timing) | [x] PASS — 10.9ms observed |

**Status:** [x] Done (AC-11 N/A — deferred to follow-up plan per Phase 4 scope)

---

### Task 5.2 — Final skill checks

```
/hipaa-check    → must show OVERALL STATUS: COMPLIANT
/spec-review    → must show no FAIL results (AC-11 expected GAP/DEFERRED, not FAIL)
```

| Check | Result | Pass? |
|-------|--------|-------|
| /hipaa-check | COMPLIANT | [x] |
| /spec-review | FAIL count: 0 (11/12 applicable ACs PASS; AC-11 NOT_YET — deferred, not failed) | [x] |

**Status:** [x] Done

---

### Task 5.3 — Fill EVAL.md

Open `Specs/member-eligibility/eval.md`
Fill in: build output, AC results (Task 5.1 table), `/spec-review` paste, `/hipaa-check` paste. Note AC-11 as deferred, not failed.

**Done when:** All blocking ACs (AC-01–AC-10, AC-12) are PASS. EVAL.md committed.
**Status:** [x] Done — all 11 blocking ACs PASS

---

### Task 5.4 — Update CLAUDE.md

Add new patterns introduced by this feature to CLAUDE.md.

```
## Patterns Added — 2026-09-10
- Inline-controller-no-service pattern for eligibility checks: EligibilityController.cs
- Narrowed, PHI-free audit table pattern (correlationId + status + checkedAt + dataSource only): eligibility_checks / EligibilityCheck
```

**Done when:** CLAUDE.md committed with new patterns.
**Status:** [x] Done — 3 patterns added (inline-controller-no-service, narrowed audit table, native-Postgres schema-apply workaround)
