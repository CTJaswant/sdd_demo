# PLAN.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/plan.md
# Committed : YES
# Status    : DRAFT
# Author    : Claude Code | Date: 2026-09-10
# Depends on: spec.md (blocking questions resolved), design-note.md DRAFT
#
# PURPOSE: Define HOW the feature will be built.
#          Answers: architecture decisions, file changes, data model, API design.
#          SPEC.md says what. PLAN.md says how.
#          TASKS.md breaks this into executable steps.
#
# CONSTITUTION CHECK: Every decision here must comply with CLAUDE.md.
#   Before approving this plan ask:
#   ✓ Does every new file follow naming conventions in CLAUDE.md section 5?
#   ✓ Does the route follow CLAUDE.md section 6?
#   ✓ Does DI registration follow CLAUDE.md section 7?
#   ✓ Does data access follow CLAUDE.md section 2.1?
#   ✓ Are all compliance rules in CLAUDE.md section 4 respected?
# ─────────────────────────────────────────────────────────────

---

## Scope Note

This plan is **backend-only**, per this task's explicit file scope (`EligibilityController.cs`; `Entities.cs`, `Dtos.cs`, `PriorAuthDbContext.cs`, `Program.cs`). design-note.md also calls for frontend wiring (`api/client.ts`, `types/index.ts`, `NewAuthorizationPage.tsx` step 4) to satisfy FR-08/AC-11 — that work is **not** covered here and is called out as a gap in Section 7 (Risks).

---

## 1. Technical Approach

The endpoint is implemented as a single new controller, `EligibilityController`, injecting only `PriorAuthDbContext` — no service/interface layer, per design-note.md's "K2 simplicity" decision. This mirrors the existing `AuthorizationsController` pattern in this codebase, which also embeds create/lookup logic directly in the controller rather than behind a service abstraction.

The action performs two EF Core primary-key lookups (`Members.FindAsync`, `HealthPlans.FindAsync`), an in-memory ordinal string comparison of `plan_code` values, and writes one audit row to a new `eligibility_checks` table before returning the result. Because this repo has no EF Core migrations, the new table is added by hand to `database/init.sql` (consistent with how every other table in this schema was created) and requires a `docker compose down -v && docker compose up -d` reset to apply in development — there is no migration step.

All new code is additive: one new controller file, and append-only edits to the four modified files. No existing controller, entity, DTO, or route is touched, and no new NuGet package is required.

---

## 2. Files to Change

### 2.1 New Files — Create

| File | Purpose | Pattern Reference |
|------|---------|-------------------|
| `backend/PriorAuth.API/Controllers/EligibilityController.cs` | `POST /api/eligibility/check` — lookup, compare, audit, respond | Read `AuthorizationsController.cs` first (inline-logic controller pattern, hand-mapped DTOs) |

### 2.2 Existing Files — Modify (additive only)

| File | Change | Risk |
|------|--------|------|
| `backend/PriorAuth.API/Models/Entities.cs` | Append `EligibilityCheck` class (new class at end of file — existing classes untouched) | Low — additive only |
| `backend/PriorAuth.API/DTOs/Dtos.cs` | Append `EligibilityCheckRequest` and `EligibilityCheckResponse` records | Low — additive only |
| `backend/PriorAuth.API/Data/PriorAuthDbContext.cs` | Add `DbSet<EligibilityCheck> EligibilityChecks` property; no new `OnModelCreating` FK config needed (no relationships) | Low — additive only |
| `backend/PriorAuth.API/Program.cs` | **No functional change expected.** Listed per this task's scope, but per design-note.md's no-service-layer decision there is no new `AddScoped<...>` line to add — `EligibilityController` is picked up automatically by the existing `AddControllers()`/`MapControllers()` calls. This entry exists to force an explicit verification step (see Section 8) rather than to introduce a change. | None — verification only |
| `database/init.sql` | Add `CREATE TABLE eligibility_checks (...)` (see Section 3.2) | Low — additive only; requires `docker compose down -v` to apply (destructive to *dev* data only, see Section 7) |

*(`database/init.sql` was not in the task's literal file list but is added here because `EligibilityCheck` has no backing table without it — the entity would fail at runtime otherwise. This is the minimum necessary to make the four listed files functional, not additional scope.)*

### 2.3 Files — Do Not Touch

| File | Reason |
|------|--------|
| `backend/PriorAuth.API/Controllers/LookupControllers.cs` (`MembersController`, `ProvidersController`, `SitesController`, `HealthPlansController`, `DiagnosisCodesController`, `ProcedureCodesController`) | Existing controllers — read only as pattern reference; task instruction: do not touch any existing controller |
| `backend/PriorAuth.API/Controllers/AuthorizationsController.cs` | Existing controller — read only as pattern reference |
| `backend/PriorAuth.API/Models/Entities.cs` — existing classes (`HealthPlan`, `ProcedureCode`, `DiagnosisCode`, `Member`, `Provider`, `Site`, `Authorization`, `AuthorizationProcedure`, `AuthorizationDiagnosis`) | Task instruction: do not touch any existing entity — only append `EligibilityCheck` |
| `backend/PriorAuth.API/DTOs/Dtos.cs` — existing records (`HealthPlanDto`, `ProcedureCodeDto`, `DiagnosisCodeDto`, `MemberDto`, `ProviderDto`, `SiteDto`, `CreateAuthorizationRequest`, `ProcedureRequest`, `AuthorizationSummaryDto`, `AuthorizationDetailDto`, `ProcedureSummary`) | Task instruction: do not touch any existing DTO — only append new records |
| `frontend/**` | Out of scope for this plan (see Scope Note) |

---

## 3. Data Model

### 3.1 New Entity

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

No `patientId`, `healthPlanId`, or `errorCode` columns — narrowed audit schema per design-note.md §"Data Handling Design". spec.md §9 OQ-02 has been updated to match this schema. No navigation properties, no FK relationships — this table stands alone.

### 3.2 Database Migration

- [x] New table required: `eligibility_checks`
- [ ] Migration needed: **NO** — this repo uses no EF Core migrations (CLAUDE.md "Backend commands"); schema changes are made directly in `database/init.sql`.
- Addition to `database/init.sql`:
```sql
CREATE TABLE eligibility_checks (
    id SERIAL PRIMARY KEY,
    correlation_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_source VARCHAR(20) NOT NULL DEFAULT 'LOCAL_DB'
);
```
- Apply via: `docker compose down -v && docker compose up -d` (full reseed — standard workflow for any `init.sql` change in this repo, per CLAUDE.md).

---

## 4. API Design

### 4.1 Controller
```
Class    : EligibilityController
Route    : [Route("api/[controller]")]           → api/eligibility
Action   : [HttpPost("check")]                    → POST /api/eligibility/check
Returns  : ActionResult<EligibilityCheckResponse>
Injects  : PriorAuthDbContext only (constructor)  — no service/interface, per design-note.md
```

### 4.2 Request → Response Flow
```
Request arrives (EligibilityCheckRequest: patientId, healthPlanId, correlationId?)
  → Validate: patientId non-empty, healthPlanId > 0, correlationId (if present) is a valid GUID
    → invalid → HTTP 400
  → correlationId = request.correlationId ?? Guid.NewGuid()   (FR-06)
  → member = await _db.Members.FindAsync(patientId)
  → if member == null:
        status = ERROR, errorCode = MBR-001                    (FR-04, precedence — spec.md OQ-07)
    else:
        healthPlan = await _db.HealthPlans.FindAsync(healthPlanId)
        → if healthPlan == null:
              status = ERROR, errorCode = PLN-001                (FR-04)
          → else:
              status = (member.PlanCode == healthPlan.PlanCode)  ? ELIGIBLE : INELIGIBLE
                        (ordinal string equality; NULL member.PlanCode → INELIGIBLE — FR-02/FR-03, plan_code field per spec.md OQ-01)
  → write ONE EligibilityCheck row: { CorrelationId, Status, CheckedAt = DateTime.UtcNow, DataSource = "LOCAL_DB" }
    (no patientId/healthPlanId/errorCode persisted — design-note.md narrowed schema)
  → await _db.SaveChangesAsync()
  → return 200 OK, EligibilityCheckResponse { status, patientId, healthPlanId, correlationId, checkedAt, errorCode, errorMessage }
  → on unhandled exception (e.g. DB unavailable):
        catch → log correlationId + exception type only (no request body, no PHI)
        → return HTTP 500, SYS-001
```

### 4.3 Error Handling

| Condition | Error Code | HTTP Status | Response |
|-----------|------------|-------------|----------|
| Member (`patientId`) not found | `MBR-001` | 200 | Status = ERROR in body |
| Health plan (`healthPlanId`) not found, member found | `PLN-001` | 200 | Status = ERROR in body |
| Both member and health plan not found | `MBR-001` (member-not-found precedence — spec.md OQ-07) | 200 | Status = ERROR in body |
| Malformed request (missing/invalid `patientId`/`healthPlanId`, or non-GUID `correlationId`) | — | 400 | ASP.NET Core model validation error |
| Unhandled exception | `SYS-001` | 500 | Generic error — no details, no PHI |

---

## 5. Frontend Plan

**Not in scope for this plan** (see Scope Note above). design-note.md identifies the required frontend changes (`api/client.ts` — `eligibility.check()` method; `types/index.ts` — response type; `NewAuthorizationPage.tsx` wizard step 4 — trigger + display, non-blocking per FR-05/FR-08). These satisfy spec.md AC-11 and must be captured in a follow-up plan before the feature is complete end-to-end — tracked as a risk in Section 7.

---

## 6. Dependency Order
*Tasks.md will use this — defines what can run in parallel*

```
Step 1: Model Layer        — Entities.cs (+ EligibilityCheck) and Dtos.cs
                              (+ EligibilityCheckRequest/Response) additions,
                              plus the eligibility_checks table in database/init.sql
        No dependencies. Start here.
        ↓
Step 2: Data Layer         — PriorAuthDbContext.cs (add DbSet<EligibilityCheck>)
        Depends on: Step 1 (EligibilityCheck entity must exist)
        ↓
Step 3: Controller         — EligibilityController.cs (+ Program.cs verification —
                              no change expected, confirm no registration is needed)
        Depends on: Steps 1 and 2 (entity, DTOs, and DbSet must all exist)
```

Frontend work (Step 4 in design-note.md's ordering) is deferred — out of scope for this plan, see Section 5.

---

## 7. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `database/init.sql` change requires `docker compose down -v` (destructive reset) to take effect in dev | High (certain, by design) | Document as a required TASKS.md step; communicate before running, since it wipes all locally seeded/created authorizations, not just this feature's data |
| Program.cs is listed as a file to modify, but no functional change is actually needed under the no-service-layer decision | Medium | Treat as a verification checklist item (Section 8), not a code change — avoids introducing an unnecessary/unused `AddScoped` line just to produce a diff |
| Frontend wiring (client.ts, types, wizard UI) is out of scope for this plan, but required for spec.md FR-08/AC-11 | High (known gap) | Track explicitly as a follow-up plan/task before declaring the feature complete; do not mark AC-11 done from backend work alone |
| No seed member has a NULL `plan_code` (spec.md OQ-03, still OPEN) — AC-05 has no natural test record | Medium | Add a synthetic test-only member row, or mock the repository/DbContext in a unit test, per design-note.md Test Strategy |
| Ordinal (case-sensitive) `plan_code` comparison assumed (spec.md OQ-04, still OPEN) | Low (seed data is consistently upper-case) | Add a unit test asserting exact-case seed values; revisit comparison logic if OQ-04 is resolved differently by a human reviewer |
| New route `/api/eligibility/check` is not covered by existing CORS config by name, only by origin | Low | No action needed — `AddCors` policy in `Program.cs` is origin-based (`localhost:5173`/`:3000`), not route-based, so the new route inherits it automatically |

---

## 8. Constitution Compliance Check

Before this plan is approved, verify each item:

- [x] All new files follow naming conventions — CLAUDE.md §5 / spec.md Constraint §6.10 (`EligibilityController.cs`, `EligibilityCheckRequest`/`EligibilityCheckResponse`, `EligibilityCheck` entity)
- [x] Route follows pattern — CLAUDE.md §6 (`POST /api/eligibility/check`, matches CLAUDE.md's own worked example verbatim)
- [x] DI uses AddScoped only — CLAUDE.md §7 — **N/A by design, not a violation:** no service is introduced, so no `AddScoped`/`AddSingleton`/`AddTransient`/manual `new` call is added at all. Verify during implementation that `Program.cs` genuinely needs no new line, per Section 2.2/Section 7.
- [x] No raw SQL — CLAUDE.md §2.1 — both lookups are `FindAsync` (EF Core primary-key reads); comparison is in-memory, not a SQL join
- [x] No PHI in audit logs — CLAUDE.md §4.1 — `eligibility_checks` stores only `correlation_id`, `status`, `checked_at`, `data_source`; no `patient_id`, `health_plan_id`, name, DOB, contact, or SSN fields
- [x] No new packages added without updating CLAUDE.md §9 — none required; uses existing EF Core/ASP.NET Core stack only
- [x] All non-goals from SPEC.md section 7 are absent from this plan — verified individually:
  1. Real-time payer/health-plan API integration — absent (`DataSource` is a hardcoded literal `"LOCAL_DB"`; no `HttpClient` or external call introduced)
  2. Blocking PA submission on INELIGIBLE — absent (no change to `AuthorizationsController` or its create flow)
  3. Date-based eligibility (effective/termination dates) — absent (no date fields in the comparison logic beyond `checked_at` audit timestamp)
  4. Benefit-level/procedure-specific coverage eligibility — absent (no `procedure_code`/`diagnosis_code` referenced anywhere in this plan)
  5. Caching of eligibility results — absent (no cache, e.g. `IMemoryCache`, introduced)
  6. RBAC/authentication changes — absent (no `[Authorize]` attribute or auth middleware change)
