# CLAUDE.md
# Location : ./CLAUDE.md  (project root)
# Committed : YES — never changes once approved
# Purpose   : Non-negotiable governing principles for this codebase.
#             Every spec, plan, and task must comply with this document.
#             Claude reads this before every action in every session.
#
# HOW TO FILL IN:
#   Read the actual codebase first. Every rule must be derived from evidence.
#   Nothing invented. Nothing aspirational. Only what is true today.
# ─────────────────────────────────────────────────────────────────────────

---

## 1. Project Identity

**Name:** [Project name]
**Domain:** [e.g. Healthcare — HIPAA regulated]
**Description:** [One paragraph — what the system does, who uses it]
**Stack:** [e.g. React 18 + TypeScript | ASP.NET Core 8 | PostgreSQL 18]

---

## 2. Architectural Principles
*Derived from reading the codebase — not invented*

### 2.1 Backend
- **Controller pattern:** [e.g. Thin controllers — zero business logic — confirmed from MembersController.cs]
- **Data access:** [e.g. EF Core LINQ queries — no raw SQL — confirmed from PriorAuthDbContext.cs]
- **DI pattern:** [e.g. AddScoped only — confirmed from Program.cs]
- **DTO pattern:** [e.g. C# record types — all in one Dtos.cs file — confirmed from DTOs/Dtos.cs]
- **Entity pattern:** [e.g. [Table][Column] annotations — nullable ? on all nullable props]
- **Configuration:** [e.g. All values from IConfiguration — no hardcoded strings]

### 2.2 Frontend
- **Component pattern:** [e.g. Functional components with hooks — no class components]
- **API calls:** [e.g. All fetch calls in api/client.ts only — nowhere else]
- **Types:** [e.g. All TypeScript interfaces in types/index.ts — mirror backend DTOs exactly]
- **Styling:** [e.g. Plain CSS in index.css — no CSS-in-JS]

---

## 3. Quality Standards

### 3.1 Code Quality
- Every new file must follow the naming convention in section 5
- Every new service must be registered in Program.cs before use
- Zero raw SQL — EF Core LINQ only
- Zero hardcoded configuration values
- Build must pass with zero errors and zero warnings at all times

### 3.2 Testing Standards
- [e.g. Unit tests for all service-layer logic]
- [e.g. Integration tests for all API endpoints]
- [e.g. Tests must pass before any PR is merged]

---

## 4. Compliance Rules
*Non-negotiable — violation blocks PR*

### 4.1 HIPAA
**NEVER log these fields in any ILogger call:**
[LIST ALL PHI FIELD NAMES — e.g.]
- dateOfBirth, memberId, firstName, lastName
- phone, emailAddress, addressLine1, addressLine2
- city, state, zipCode, memberCode, ssn

**NEVER hardcode:** connection strings, API keys, passwords, tokens

**ALWAYS write:** one structured audit log entry per sensitive operation
- Must contain: correlationId + timestamp + operation result
- Must NOT contain: any PHI field listed above

**ALWAYS generate:** correlationId if not provided — use Guid.NewGuid()

---

## 5. Naming Conventions
*Confirmed from reading existing files — not invented*

| Artifact | Pattern | Confirmed from |
|---|---|---|
| Controller | `[Domain]sController.cs` | `MembersController.cs` |
| DTO (request) | `[Feature]Request` record | `DTOs/Dtos.cs` |
| DTO (response) | `[Feature]Response` record | `DTOs/Dtos.cs` |
| EF Entity | `[Domain]` class with `[Table]` | `Models/Entities.cs` |
| React page | `[Name]Page.tsx` | `pages/DashboardPage.tsx` |
| React component | `[Name].tsx` | `components/SearchSelect.tsx` |
| API client method | added to `api` object in `client.ts` | `api/client.ts` |
| TypeScript type | added to `types/index.ts` | `types/index.ts` |

---

## 6. Route Conventions
*Confirmed from existing controllers*

```
Pattern  : /api/[controller]/[action]
Attribute: [Route("api/[controller]")]
Examples : GET  /api/members
           POST /api/authorizations
           POST /api/eligibility/check  ← new feature
```

---

## 7. Dependency Injection Rules
*Confirmed from Program.cs*

```csharp
// ONLY this pattern — no exceptions
builder.Services.AddScoped<IInterface, Implementation>();

// NEVER
builder.Services.AddSingleton<...>()   // stateful — concurrency bugs
builder.Services.AddTransient<...>()   // new DB connection per call
new MyService()                         // bypasses DI entirely
```

---

## 8. What Claude Must Do When Uncertain

1. STOP generation immediately
2. Write the uncertainty to `OPEN_QUESTIONS.md` tagged `[BLOCKING]` or `[NON-BLOCKING]`
3. `[BLOCKING]`     — Do not proceed. Surface to the human.
4. `[NON-BLOCKING]` — State assumption explicitly. Continue. Flag for review.

**Never resolve ambiguity silently.**
**Never pick one interpretation without surfacing the alternatives.**

---

## 9. Approved Packages
*No additions without updating this section*

### Backend
[LIST FROM *.csproj — e.g.]
- Npgsql.EntityFrameworkCore.PostgreSQL 8.0.4
- Swashbuckle.AspNetCore 6.6.2
- Microsoft.EntityFrameworkCore.Design 8.0.4

### Frontend
[LIST FROM package.json — e.g.]
- react 18.3.1
- react-router-dom 6.26.0
- typescript 5.5.3
