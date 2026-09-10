# PLAN.md — [Feature Name]
# Location : specs/[NNN-feature-name]/plan.md
# Committed : YES
# Status    : DRAFT → REVIEWED → APPROVED
# Author    : [Name] | Date: [DATE]
# Depends on: spec.md APPROVED
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

## 1. Technical Approach

[Two to three paragraphs describing the overall technical approach.
What architectural pattern will be used? Why?
What existing patterns in the codebase does this follow?]

---

## 2. Files to Change

### 2.1 New Files — Create
| File | Purpose | Pattern Reference |
|------|---------|-------------------|
| `[path/NewFile.cs]` | [What it does] | Read [existing file] first |
| `[path/NewFile.cs]` | [What it does] | Read [existing file] first |

### 2.2 Existing Files — Modify
| File | Change | Risk |
|------|--------|------|
| `[path/Entities.cs]` | Add [Entity] class | Low — additive only |
| `[path/Dtos.cs]` | Add [Request] and [Response] records | Low — additive only |
| `[path/DbContext.cs]` | Add DbSet + OnModelCreating config | Low — additive only |
| `[path/Program.cs]` | Add [N] AddScoped line(s) | Low — additive only |

### 2.3 Files — Do Not Touch
| File | Reason |
|------|--------|
| `[path/MembersController.cs]` | Existing feature — read only as pattern |
| `[path/AuthorizationsController.cs]` | Existing feature — read only as pattern |
| [any other existing file] | Not in scope — CLAUDE.md constraint |

---

## 3. Data Model

### 3.1 New Entity
```csharp
[Table("[table_name]")]
public class [EntityName]
{
    [Key, Column("[id_column]")]
    public int Id { get; set; }

    [Column("[field_column]")]
    public string [Field] { get; set; } = string.Empty;

    [Column("[nullable_column]")]
    public string? [NullableField] { get; set; }

    [Column("[date_column]")]
    public DateTime [DateField] { get; set; }
}
```

### 3.2 Database Migration
- [ ] New table required: `[table_name]`
- [ ] Migration needed: YES / NO
- [ ] If YES — migration script: `[filename]`

---

## 4. API Design

### 4.1 Controller
```
Class    : [Domain]Controller
Route    : [Route("api/[controller]")]
Action   : [HttpPost("[action]")]
Returns  : ActionResult<[ResponseDto]>
Injects  : [DbContext or service via constructor]
```

### 4.2 Request → Response Flow
```
Request arrives
  → Validate required fields
  → [Step 1 — e.g. Look up member in DB]
  → [Step 2 — e.g. Check policy status]
  → [Step 3 — e.g. Check procedure coverage]
  → Write audit log (correlationId + status only — no PHI)
  → Return [ResponseDto]
```

### 4.3 Error Handling
| Condition | Error Code | HTTP Status | Response |
|-----------|------------|-------------|----------|
| [condition] | [ERR-001] | 200 | Status = ERROR in body |
| [condition] | [ERR-002] | 200 | Status = ERROR in body |
| Unhandled exception | SYS-001 | 500 | Generic error — no details |

---

## 5. Frontend Plan (if applicable)

### 5.1 New Files
| File | Purpose |
|------|---------|
| `[path/ComponentName.tsx]` | [What it shows] |

### 5.2 API Client Addition
```typescript
// Add to api object in api/client.ts
[featureName]: {
  [methodName]: ([params]) => post<[ResponseType]>('[route]', [body]),
}
```

### 5.3 TypeScript Types
```typescript
// Add to types/index.ts
export interface [RequestType] { ... }
export interface [ResponseType] { ... }
```

---

## 6. Dependency Order
*Tasks.md will use this — defines what can run in parallel*

```
Step 1: [Model Layer]     — Entities.cs + Dtos.cs additions
        No dependencies. Start here.
        ↓
Step 2: [Data Layer]      — DbContext.cs update
        Depends on: Step 1 (entity must exist)
        ↓
Step 3: [Controller]      — New controller file + Program.cs
        Depends on: Steps 1 and 2
        ↓
Step 4: [Frontend]        — Component + client.ts + types/index.ts
        Depends on: Step 3 (API must exist)
```

---

## 7. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| [e.g. Seed data for AC-03 not in DB] | Medium | Verify init.sql has PT001234 before testing |
| [e.g. EF migration needed for new table] | Medium | Run migration before dotnet run |
| [e.g. CORS not configured for new route] | Low | Already configured in Program.cs — new route inherits it |

---

## 8. Constitution Compliance Check

Before this plan is approved, verify each item:

- [ ] All new files follow naming conventions — CLAUDE.md section 5
- [ ] Route follows pattern — CLAUDE.md section 6
- [ ] DI uses AddScoped only — CLAUDE.md section 7
- [ ] No raw SQL — CLAUDE.md section 2.1
- [ ] No PHI in audit logs — CLAUDE.md section 4.1
- [ ] No new packages added without updating CLAUDE.md section 9
- [ ] All non-goals from SPEC.md section 7 are absent from this plan
