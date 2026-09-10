---
name: hipaa-check
description: Scan generated code for HIPAA violations. Use after generating
             any code that handles patient data. Must return COMPLIANT
             before any PR is raised. Checks PHI in logs, hardcoded
             credentials, and missing audit entries.
---

# HIPAA Check Workflow

## PHI Fields — Never in Log Statements
dateOfBirth, memberId, firstName, lastName, phone, emailAddress,
addressLine1, addressLine2, city, state, zipCode, memberCode, ssn

## Step 1 — Scan Logging Calls
Find ILogger calls containing any PHI field above.
Flag each: HIPAA_VIOLATION — file, line, field name.

## Step 2 — Scan for Hardcoded Credentials
Find connection strings, API keys, passwords as string literals.
Flag each: CREDENTIAL_EXPOSURE — file, line.

## Step 3 — Verify Audit Entries
For each sensitive operation method:
- One log entry per call? YES/NO
- Contains correlationId (not patient ID)? YES/NO
- Contains operation result? YES/NO
- Contains NO PHI field? YES/NO
Flag missing/non-compliant: AUDIT_GAP.

## Step 4 — Output

```
=== HIPAA CHECK ===
HIPAA_VIOLATIONS:     [NONE or file:line — field — description]
CREDENTIAL_EXPOSURE:  [NONE or file:line — description]
AUDIT_GAPS:           [NONE or method — what is missing]

OVERALL: COMPLIANT / NON-COMPLIANT
=== END ===
```

Does not fix. Reports only. PR blocked until COMPLIANT.
