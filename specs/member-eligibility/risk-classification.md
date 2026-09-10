# RISK-CLASSIFICATION.md — [Feature Name]
# Location : specs/[NNN-feature-name]/risk-classification.md
# Committed : YES
# Status    : DRAFT → COMPLETE
# Author    : [Name] | Date: [DATE]
#
# PURPOSE   : Assess risk BEFORE writing the spec or plan.
#             Step 2 of the SDAD Golden Path — Classify.
#             Required by CLAUDE.md compliance rules.
#             Link this file from SPEC.md section Risk Classification.
#
# SOURCE    : Derived from sdad-golden-path.md Step 2 and
#             risk-classification-worksheet.md in the SDAD Golden Repo Kit.
# ─────────────────────────────────────────────────────────────

---

## Feature Name

[Feature name — same as spec.md]

---

## Risk Questions

| Question | Answer | Required Action |
|----------|--------|-----------------|
| Does the change involve PHI or identity data? | YES | Privacy/security review required if yes |
| Does it affect authentication or authorization? | NO | Security review required if yes |
| Does it affect clinical, claims, billing, or payment logic? | NO | Domain SME review required if yes |
| Does it affect audit logging or compliance evidence? | YES | Audit evidence review required if yes |
| Does it introduce new external tool or MCP access? | NO | Tool access review required if yes |
| Does it rely on production-like data? | NO | Must use synthetic data in training |
| Is the change reversible? | YES | Document rollback approach |
| Are tests sufficient to verify intended behavior? | YES | Add tests before PR readiness |

---

## Risk Level

Choose one:

- [ ] Low
- [X] Medium
- [ ] High
- [ ] Very High

---

## Required Human Review Gates

- [X] Tech lead review
- [ ] Security review
- [ ] Privacy review
- [ ] Domain SME review
- [X] QA / validation review
- [X] Product owner review

---

## Claude May

- [X] Draft the spec
- [X] Draft the design note
- [X] Implement scoped code changes
- [X] Generate tests
- [X] Generate documentation
- [X] Generate evidence summary

## Claude May Not

- [X] Finalize regulatory interpretation
- [X] Approve PHI handling
- [X] Approve security-sensitive logic
- [X] Merge code without human review
