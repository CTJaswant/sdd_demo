# TASKS.md — [Feature Name]
# Location : specs/[NNN-feature-name]/tasks.md
# Committed : YES
# Status    : READY → IN PROGRESS → DONE
# Author    : [Name] | Date: [DATE]
# Depends on: plan.md APPROVED
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

## Progress

- Phase 1 — Model Layer     : [ ] Not started
- Phase 2 — Data Layer      : [ ] Not started
- Phase 3 — Controller      : [ ] Not started
- Phase 4 — Frontend        : [ ] Not started
- Phase 5 — Verification    : [ ] Not started

---

## Phase 1 — Model Layer
*No dependencies — start here*
*Pattern references: read Entities.cs and Dtos.cs before any task*

---

### Task 1.1 — Add [StatusEnum]
**File:** `backend/PriorAuth.API/Models/Entities.cs`
**Action:** Add enum at the bottom of the file

```
Add this enum:
public enum [StatusEnum]
{
    [VALUE1],
    [VALUE2],
    [VALUE3],
    [VALUE4]
}
```

**Done when:** `dotnet build` passes with zero errors
**AC covered:** AC-02
**Status:** [ ] Done

---

### Task 1.2 — Add [AuditEntity]
**File:** `backend/PriorAuth.API/Models/Entities.cs`
**Action:** Add entity class after existing entities

```
Add entity following the [Table][Column] pattern from existing entities.
Fields: Id (int PK), [Field1] (string), [Field2] (string?), 
        [StatusField] ([StatusEnum]), [DateField] (DateTime), [SourceField] (string)
```

**Done when:** `dotnet build` passes
**AC covered:** AC-08
**Status:** [ ] Done

---

### Task 1.3 — Add [FeatureRequest] DTO
**File:** `backend/PriorAuth.API/DTOs/Dtos.cs`
**Action:** Add record at the bottom of the file

```
Add request record from SPEC.md section 4.2.
Use record type matching existing DTO pattern.
All nullable fields declare ?.
```

**Done when:** `dotnet build` passes
**AC covered:** AC-01
**Status:** [ ] Done

---

### Task 1.4 — Add [FeatureResponse] DTO
**File:** `backend/PriorAuth.API/DTOs/Dtos.cs`
**Action:** Add record after the request record

```
Add response record from SPEC.md section 4.3.
Include all fields from SPEC.md section 4.3.
Use [StatusEnum] for the status field.
```

**Done when:** `dotnet build` passes
**AC covered:** AC-01, AC-02, AC-06, AC-07
**Status:** [ ] Done

**→ Run /spec-review after this task. AC-02 should show PASS.**

---

## Phase 2 — Data Layer
*Depends on: Phase 1 complete*
*Pattern reference: read PriorAuthDbContext.cs before starting*

---

### Task 2.1 — Register [AuditEntity] in DbContext
**File:** `backend/PriorAuth.API/Data/PriorAuthDbContext.cs`
**Action:** Two additions only

```
1. Add DbSet<[AuditEntity]> property
2. Add configuration in OnModelCreating:
   - [AuditEntity] is standalone — no FK constraints
   - No changes to existing configurations
```

**Done when:** `dotnet build` passes
**AC covered:** AC-08
**Status:** [ ] Done

**→ Run /spec-review after this task.**

---

## Phase 3 — Controller
*Depends on: Phases 1 and 2 complete*
*Pattern reference: read MembersController.cs before starting*
*Run in a WORKTREE — feature/[NNN]-[feature-name]-controller*

---

### Task 3.1 — Create [Feature]Controller
**File:** `backend/PriorAuth.API/Controllers/[Feature]Controller.cs` ← NEW FILE
**Action:** Create new controller

```
Route: [Route("api/[controller]")]
Action: [HttpPost("[action]")]
Inject: PriorAuthDbContext via constructor

Implement lookup logic from SPEC.md section 2 flow:
  Condition 1 → return [ERROR_CODE_1]
  Condition 2 → return [ERROR_CODE_2]
  Condition 3 → return [INELIGIBLE/STATUS]
  All match   → return [ELIGIBLE/STATUS] with details

Audit log — ONE ILogger entry per call:
  _logger.LogInformation("[Feature] check: {CorrelationId} {Status}", correlationId, status)
  NO PHI fields in the log call.

Generate correlationId: Guid.NewGuid().ToString() if not in request.
```

**Done when:** `dotnet build` passes
**AC covered:** AC-01, AC-03, AC-04, AC-05, AC-08
**Status:** [ ] Done

---

### Task 3.2 — Register in Program.cs
**File:** `backend/PriorAuth.API/Program.cs`
**Action:** One line addition only

```
Add inside the services registration block:
builder.Services.AddScoped<[IService], [ServiceImpl]>();
(if no separate service — DbContext injection needs no AddScoped)
```

**Done when:** `dotnet build` passes. `dotnet run` starts without error.
**AC covered:** AC-10
**Status:** [ ] Done

**→ Run /hipaa-check. Must show COMPLIANT before Phase 4.**
**→ Run /spec-review. All ACs should be PASS or GAP — no FAIL.**

---

## Phase 4 — Frontend (optional)
*Depends on: Phase 3 complete and API running*
*Pattern reference: read api/client.ts and types/index.ts before starting*

---

### Task 4.1 — Add TypeScript types
**File:** `frontend/src/types/index.ts`
**Action:** Add at the bottom

```
Add interfaces mirroring SPEC.md section 4.2 and 4.3 exactly.
Match backend DTO field names — camelCase.
All nullable fields declare | null.
```

**Done when:** TypeScript compiles with no errors
**Status:** [ ] Done

---

### Task 4.2 — Add API client method
**File:** `frontend/src/api/client.ts`
**Action:** Add to the api object

```
Add [featureName] property to the api object:
  [methodName]: ([params]) =>
    post<[ResponseType]>('[route]', { [fields] })
```

**Done when:** TypeScript compiles with no errors
**Status:** [ ] Done

---

### Task 4.3 — Create [Feature] UI component
**File:** `frontend/src/components/[FeatureName].tsx` ← NEW FILE
**Action:** Create component

```
Functional component. TypeScript props interface.
Loading state. Error state. Data state.
Calls api.[featureName].[methodName] on [trigger].
Shows [status] with appropriate colour coding.
No hardcoded API URLs — use relative path via Vite proxy.
```

**Done when:** Component renders without console errors
**Status:** [ ] Done

---

## Phase 5 — Verification
*Run after all implementation phases complete*

---

### Task 5.1 — Runtime AC verification
Test each AC in Swagger (`http://localhost:5000/swagger`):

| AC | Test Input | Expected | Pass? |
|----|------------|----------|-------|
| AC-01 | [valid request] | HTTP 200 | [ ] |
| AC-03 | memberId: [ID1] | [EXPECTED] | [ ] |
| AC-04 | memberId: [ID2] | [EXPECTED] | [ ] |
| AC-05 | memberId: UNKNOWN | ERROR [CODE] | [ ] |
| AC-06 | any valid request | [field] in ISO 8601 | [ ] |
| AC-07 | any valid request | dataSource = "[SOURCE]" | [ ] |
| AC-08 | any request | log entry in terminal | [ ] |

**Status:** [ ] Done

---

### Task 5.2 — Final skill checks

```
/hipaa-check    → must show OVERALL STATUS: COMPLIANT
/spec-review    → must show no FAIL results
```

| Check | Result | Pass? |
|-------|--------|-------|
| /hipaa-check | COMPLIANT / NON-COMPLIANT | [ ] |
| /spec-review | FAIL count: [N] | [ ] |

**Status:** [ ] Done

---

### Task 5.3 — Fill EVAL.md

Open `specs/[NNN-feature-name]/eval.md`
Fill in: build output, AC results, /spec-review paste, /hipaa-check paste

**Done when:** All blocking ACs are PASS. EVAL.md committed.
**Status:** [ ] Done

---

### Task 5.4 — Update CLAUDE.md

Add new patterns introduced by this feature to CLAUDE.md.

```
## Patterns Added — [DATE]
- [Pattern name]: [description] — [file where it appears]
```

**Done when:** CLAUDE.md committed with new patterns.
**Status:** [ ] Done
