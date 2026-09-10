# TASKS.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/tasks.md
# Committed : YES
# Status    : READY
# Author    : Claude Code | Date: 2026-09-10
# Depends on: plan.md DRAFT
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

## Scope Note

plan.md is backend-only (see its Scope Note). Phase 4 (Frontend) is therefore listed as **deferred / out of scope**, not as executable tasks — generating frontend tasks here would invent work beyond what plan.md specifies. spec.md AC-11 cannot be closed until a follow-up plan covers `api/client.ts`, `types/index.ts`, and `NewAuthorizationPage.tsx`.

---

## Progress

- Phase 1 — Model Layer     : [ ] Not started
- Phase 2 — Data Layer      : [ ] Not started
- Phase 3 — Controller      : [ ] Not started
- Phase 4 — Frontend        : DEFERRED — out of scope for this plan (see Scope Note)
- Phase 5 — Verification    : [ ] Not started

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
(plan.md §3.1 — exact schema, no `patientId`/`healthPlanId`/`errorCode` columns)

**Done when:** `dotnet build` passes with zero errors, zero warnings
**AC covered:** AC-08 (audit record schema), AC-09 (no PHI fields on the entity)
**Status:** [ ] Done

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
**Status:** [ ] Done

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
**Status:** [ ] Done

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
**Status:** [ ] Done

**→ Run /spec-review after this task.**

---

## Phase 2 — Data Layer
*Depends on: Phase 1 complete*
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
**Status:** [ ] Done

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
**Status:** [ ] Done

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
| AC-01 | patientId `PT001234`, healthPlanId `1` (Cigna, plan_code=CIGNA) | HTTP 200, status ELIGIBLE | [ ] |
| AC-02 | patientId `PT001235`, healthPlanId `1` (Cigna, plan_code=CIGNA) | HTTP 200, status INELIGIBLE | [ ] |
| AC-03 | patientId `PT999999` (unknown), healthPlanId `1` | HTTP 200, status ERROR, errorCode MBR-001 | [ ] |
| AC-04 | patientId `PT001234`, healthPlanId `9999` (unknown) | HTTP 200, status ERROR, errorCode PLN-001 | [ ] |
| AC-05 | member with NULL plan_code (test-only record, per spec.md OQ-03) vs any health plan | HTTP 200, status INELIGIBLE | [ ] |
| AC-06 | missing patientId or healthPlanId | HTTP 400 | [ ] |
| AC-08 | any valid or ERROR check | One `eligibility_checks` row written with correlationId, status, checkedAt, dataSource | [ ] |
| AC-09 | any generated code for this feature | `/hipaa-check` returns COMPLIANT | [ ] |
| AC-10 | all code changes | `dotnet build` — zero errors, zero warnings | [ ] |
| AC-12 | patientId `PT999999` AND healthPlanId `9999` (both unknown) | HTTP 200, status ERROR, errorCode MBR-001 (precedence) | [ ] |
| AC-11 | N/A — frontend deferred, see Phase 4 | Not testable until follow-up plan | [ ] N/A |
| AC-07 | any valid check | Response returned within 500ms (manual timing) | [ ] |

**Status:** [ ] Done

---

### Task 5.2 — Final skill checks

```
/hipaa-check    → must show OVERALL STATUS: COMPLIANT
/spec-review    → must show no FAIL results (AC-11 expected GAP/DEFERRED, not FAIL)
```

| Check | Result | Pass? |
|-------|--------|-------|
| /hipaa-check | COMPLIANT / NON-COMPLIANT | [ ] |
| /spec-review | FAIL count: [N] | [ ] |

**Status:** [ ] Done

---

### Task 5.3 — Fill EVAL.md

Open `Specs/member-eligibility/eval.md`
Fill in: build output, AC results (Task 5.1 table), `/spec-review` paste, `/hipaa-check` paste. Note AC-11 as deferred, not failed.

**Done when:** All blocking ACs (AC-01–AC-10, AC-12) are PASS. EVAL.md committed.
**Status:** [ ] Done

---

### Task 5.4 — Update CLAUDE.md

Add new patterns introduced by this feature to CLAUDE.md.

```
## Patterns Added — 2026-09-10
- Inline-controller-no-service pattern for eligibility checks: EligibilityController.cs
- Narrowed, PHI-free audit table pattern (correlationId + status + checkedAt + dataSource only): eligibility_checks / EligibilityCheck
```

**Done when:** CLAUDE.md committed with new patterns.
**Status:** [ ] Done
