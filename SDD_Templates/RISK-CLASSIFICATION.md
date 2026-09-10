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
| Does the change involve PHI or identity data? | TBD | Privacy/security review required if yes |
| Does it affect authentication or authorization? | TBD | Security review required if yes |
| Does it affect clinical, claims, billing, or payment logic? | TBD | Domain SME review required if yes |
| Does it affect audit logging or compliance evidence? | TBD | Audit evidence review required if yes |
| Does it introduce new external tool or MCP access? | TBD | Tool access review required if yes |
| Does it rely on production-like data? | TBD | Must use synthetic data in training |
| Is the change reversible? | TBD | Document rollback approach |
| Are tests sufficient to verify intended behavior? | TBD | Add tests before PR readiness |

---

## Risk Level

Choose one:

- [ ] Low
- [ ] Medium
- [ ] High
- [ ] Very High

---

## Required Human Review Gates

- [ ] Tech lead review
- [ ] Security review
- [ ] Privacy review
- [ ] Domain SME review
- [ ] QA / validation review
- [ ] Product owner review

---

## Claude May

- [ ] Draft the spec
- [ ] Draft the design note
- [ ] Implement scoped code changes
- [ ] Generate tests
- [ ] Generate documentation
- [ ] Generate evidence summary

## Claude May Not

- [ ] Finalize regulatory interpretation
- [ ] Approve PHI handling
- [ ] Approve security-sensitive logic
- [ ] Merge code without human review
