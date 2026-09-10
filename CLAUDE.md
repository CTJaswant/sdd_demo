# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ABC Healthcare Prior Authorization intake app — React + ASP.NET Core 8 Web API + PostgreSQL. This is the **baseline/starting point** for an SDD (Spec-Driven Development) + Claude Code CLI workshop.

**Intentionally missing:** Member Eligibility verification. The workshop's exercise is to add this feature via Spec-Driven Development — a `SPEC.md` defines the feature, and this CLAUDE.md plus custom skills (`/spec-review`, `/hipaa-check`) govern/verify the implementation. If those files exist when you're working, follow them; they define the actual task at hand more precisely than this file does.

## Running the app (3 processes)

```bash
# 1. Database (Docker)
docker compose up -d
docker compose ps          # wait for pa_db to show "healthy"

# 2. Backend API
cd backend/PriorAuth.API
dotnet run                 # http://localhost:5000, swagger at /swagger

# 3. Frontend
cd frontend
npm install
npm run dev                 # http://localhost:5173
```

Verify the API/DB are up: `curl http://localhost:5000/api/healthplans` should return 6 health plans.

Reset the DB to reseed: `docker compose down -v && docker compose up -d`.

There are no automated tests in this repo currently.

### Frontend commands
- `npm run dev` — Vite dev server (port 5173), proxies `/api/*` to `http://localhost:5000` (see `frontend/vite.config.ts`)
- `npm run build` — `tsc && vite build` (type-checks then builds)
- `npm run preview` — preview the production build

### Backend commands (from `backend/PriorAuth.API`)
- `dotnet run` — start the API
- `dotnet build` — compile only
- EF Core is used, but there are no migrations — the schema is created entirely by `database/init.sql`, mounted into Postgres via `docker-entrypoint-initdb.d`. If you change `Models/Entities.cs`, update `database/init.sql` to match (and reset the DB volume) rather than adding EF migrations.

## Architecture

**Data flow:** PostgreSQL (`database/init.sql`) → EF Core entities (`Models/Entities.cs`) → Controllers project DTOs directly via `.Select()` projections (`DTOs/Dtos.cs`) → JSON → frontend `api/client.ts` → typed page components. Frontend types in `frontend/src/types/index.ts` are hand-kept in sync with backend DTOs ("Matches backend DTOs exactly" — no shared schema/codegen).

**Backend structure** (`backend/PriorAuth.API/`):
- `Models/Entities.cs` — all EF Core entities in one file, mapped with `[Table]`/`[Column]` attributes to snake_case Postgres columns.
- `Data/PriorAuthDbContext.cs` — single `DbContext`; all FK relationships (Authorization → Member/Provider/HealthPlan/Site/DiagnosisCode) configured in `OnModelCreating` with `DeleteBehavior.SetNull`.
- `Controllers/LookupControllers.cs` — one file holding all the simple lookup controllers (Members, Providers, Sites, HealthPlans, DiagnosisCodes, ProcedureCodes). These are search/list endpoints only — no create/update.
- `Controllers/AuthorizationsController.cs` — the one controller with real logic: create (with nested procedures/diagnoses), get list/detail (with `.Include()` chains), and status update. Response DTOs are hand-mapped in `MapToDetail()`, not via AutoMapper.
- Reference numbers are generated as `PA-{yyyyMMdd}-{random 5-digit}` in `AuthorizationsController.Create` — not guaranteed unique, no DB-level enforcement beyond the `reference_number UNIQUE` constraint (a collision would throw on save).
- CORS is locked to `http://localhost:5173` / `:3000` (`Program.cs`) — update if the frontend origin changes.
- **Note:** `appsettings.json`'s `DefaultConnection` (`Username=postgres;Password=password_123`) does not match `docker-compose.yml`'s Postgres credentials (`pa_user`/`pa_password`). Align these if the API can't connect to the DB.

**Frontend structure** (`frontend/src/`):
- `api/client.ts` — the only place `fetch` is called; all backend calls go through the `api` object, grouped by resource. Add new endpoints here, not ad hoc in components.
- `types/index.ts` — mirrors backend DTOs by hand, plus frontend-only concerns: `WizardState` (the New Request wizard's accumulated form state), `PROGRAMS` (clinical program list), `STATUS_COLORS`/`STATUS_BG` (status badge styling).
- `components/SearchSelect.tsx` — generic async search-and-select dropdown, reused across the wizard for provider/member/site/code lookups.
- `pages/NewAuthorizationPage.tsx` — the 6-step New Request wizard (Program → Provider → Health Plan → Member → Diagnosis & CPT → Site & Review), all steps live in this single component driven by `WizardState`.
- `pages/DashboardPage.tsx` / `AuthorizationDetailPage.tsx` — list view (with status filter) and detail view.
- Routing is defined directly in `App.tsx` (`/`, `/new`, `/authorization/:id`) — no nested routes or route config file.
- Styling is plain CSS (`index.css`), no CSS framework or CSS-in-JS.

## Domain model notes

- IDs are domain codes, not surrogate keys, for most master data: `patient_id` (`PT00xxxx`), `physician_id` (`PHYxxx`), `site_id` (`SITExxx`), `procedure_code`/`diagnosis_code` (real CPT/ICD-10 codes). Only `health_plans` and `authorizations` use serial integer IDs.
- An `Authorization` has one `primary_diagnosis` (FK to `diagnosis_codes`) plus a many-to-many-style `authorization_diagnoses` join table (with `is_primary` flag) — the primary diagnosis is effectively stored twice; keep both in sync when creating/updating.
- Status values are a fixed set enforced only in application code (`AuthorizationsController.UpdateStatus`), not a DB enum/check constraint: `PENDING`, `APPROVED`, `DENIED`, `CANCELLED`, `IN_REVIEW`.

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

---

## Patterns Added — 2026-09-10

- **Inline-controller-no-service pattern:** for small, single-endpoint features, logic (lookup, comparison, audit write, response shaping) lives directly in the controller action, injecting `PriorAuthDbContext` only — no service/interface layer, no `AddScoped` registration. Confirmed consistent with the existing `AuthorizationsController.cs` pattern. See `Controllers/EligibilityController.cs`.
- **Narrowed, PHI-free audit table pattern:** an audit trail can be satisfied with `correlation_id` + `status` + `checked_at` + `data_source` only — deliberately omitting request-supplied identifiers (e.g. `patient_id`, `health_plan_id`) to minimize identity-linkable data at rest, even when those identifiers aren't on CLAUDE.md §4.1's literal PHI list. See `eligibility_checks` / `EligibilityCheck` (`Models/Entities.cs`).
- **Native (non-Docker) Postgres environments:** this repo's documented `docker compose down -v && docker compose up -d` schema-reset workflow assumes Docker is installed. On a machine running PostgreSQL as a native service instead, apply new `CREATE TABLE` statements directly via `psql` against the existing database (matching the DDL already committed to `database/init.sql`) rather than attempting a Docker-based reset.
