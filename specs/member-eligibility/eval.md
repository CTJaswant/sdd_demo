# EVAL.md — Member Eligibility Check (Phase 1)
# Location : Specs/member-eligibility/eval.md
# Committed : YES
# Status    : BACKEND COMPLETE — AC-11 (frontend) deferred
# Author    : Claude Code | Date: 2026-09-10
# Depends on: tasks.md Phase 5 (Verification)
#
# PURPOSE: Evidence record for spec.md's acceptance criteria — build output,
#          runtime AC results, and skill-check output, captured at the end
#          of implementation.
# ─────────────────────────────────────────────────────────────

---

## Build Output

`dotnet build` run 5 times across Phase 1–3 (once per code task: 1.1, 1.3, 1.4, 2.1, 3.1). Every run:

```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

AC-10: **PASS**

---

## Runtime AC Results

Tested live against `POST http://localhost:5000/api/eligibility/check`, seeded/test data per spec.md §8, after applying `eligibility_checks` via a direct `psql` DDL statement (this environment runs Postgres as a native Windows service, not Docker — `docker compose down -v` from CLAUDE.md/tasks.md does not apply here; see Notes).

| AC | Result | Evidence |
|----|--------|----------|
| AC-01 | PASS | `PT001234` + healthPlanId `1` → HTTP 200, `ELIGIBLE` |
| AC-02 | PASS | `PT001235` + healthPlanId `1` → HTTP 200, `INELIGIBLE` |
| AC-03 | PASS | `PT999999` (unknown) → HTTP 200, `ERROR`/`MBR-001` |
| AC-04 | PASS | healthPlanId `9999` (unknown) → HTTP 200, `ERROR`/`PLN-001` |
| AC-05 | PASS | temp test member `PTTEST01` (NULL `plan_code`) → HTTP 200, `INELIGIBLE`; record deleted after test |
| AC-06 | PASS | missing `healthPlanId` → HTTP 400 |
| AC-07 | PASS | measured 10.9ms (budget: 500ms) |
| AC-08 | PASS | `psql` query on `eligibility_checks` shows exactly 5 rows for 5 valid calls; 0 rows for the AC-06 (400) case |
| AC-09 | PASS | `/hipaa-check` → COMPLIANT (see below) |
| AC-10 | PASS | see Build Output above |
| AC-11 | **N/A — DEFERRED** | Frontend wiring (`api/client.ts`, `types/index.ts`, `NewAuthorizationPage.tsx`) explicitly out of scope for plan.md; requires a follow-up plan |
| AC-12 | PASS | both `PT999999` and healthPlanId `9999` unknown → HTTP 200, `ERROR`/`MBR-001` (member-not-found precedence confirmed) |

**Blocking ACs (AC-01–AC-10, AC-12): 11/11 PASS.**

---

## /spec-review (final pass)

```
=== SPEC REVIEW ===
AC-01 through AC-10, AC-12: PASS (see Runtime AC Results above)
AC-11: NOT_YET — frontend out of scope for this plan, follow-up plan required

CONSTRAINTS: RESPECTED — no existing controller/entity/DTO modified, route matches
  CLAUDE.md §6, no new DI registration (confirmed via Swagger with no Program.cs edit),
  EF Core FindAsync only, no PHI in the one ILogger call, no hardcoded secrets,
  no new packages, build clean, audit table added additively.
SCOPE CREEP: NONE — verified against all 6 non-goals in spec.md §7.
SPEC GAPS: NONE remaining — spec.md §9 OQ-02 was updated in an earlier session
  turn to match the implemented audit schema.

ACTION: Ready — backend implementation and verification complete.
        AC-11/FR-08 requires a follow-up plan (frontend, out of scope here).
=== END ===
```

---

## /hipaa-check (final pass)

```
=== HIPAA CHECK ===
HIPAA_VIOLATIONS:     NONE
CREDENTIAL_EXPOSURE:  NONE
AUDIT_GAPS:           NONE

OVERALL: COMPLIANT
=== END ===
```

---

## Notes

- **Environment deviation from CLAUDE.md/tasks.md:** this machine runs PostgreSQL 14 as a native Windows service, not via Docker (Docker is not installed). The `eligibility_checks` table was applied with a direct `psql` `CREATE TABLE` statement identical to the DDL already committed in `database/init.sql`, rather than via `docker compose down -v && docker compose up -d`. No existing table or seed row was affected by this approach — arguably lower-risk than the documented full-volume reset, since it didn't require wiping and reseeding the whole database.
- AC-05's test record (`PTTEST01`) was inserted and deleted directly in the running database for verification purposes only — it is not part of `database/init.sql` and leaves no trace in the committed seed data.
- Phase 4 (Frontend) remains deferred per plan.md's Scope Note — this feature is not end-to-end complete until that follow-up plan closes AC-11/FR-08.
