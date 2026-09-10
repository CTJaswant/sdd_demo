# SDD Templates — Spec-Driven Development with Claude Code CLI
## Inspired by github/spec-kit · Adapted for Claude Code CLI

---

## The SDD Workflow

Five artifacts. Five phases. Sequential.
Each artifact is a gate — you do not proceed until it is approved.

```
PHASE 1          PHASE 2        PHASE 3        PHASE 4        PHASE 5
───────────      ──────────     ──────────     ───────────    ──────────
CONSTITUTION  →  SPEC.md    →  PLAN.md    →  TASKS.md   →  IMPLEMENT
                                                              + EVAL.md

What it is:      WHAT          HOW            STEPS          EVIDENCE
Skill used:      /sdd-clarify  /sdd-analyze   /spec-review   /hipaa-check
                                              /hipaa-check
```

---

## Files in This Kit

```
sdd_templates/
│
├── CLAUDE.md          ← Phase 0 — project governing principles
├── SPEC.md                  ← Phase 1 — what the feature does
├── PLAN.md                  ← Phase 2 — how it will be built
├── TASKS.md                 ← Phase 3 — ordered executable steps
├── EVAL.md                  ← Phase 5 — verification evidence
├── OPEN_QUESTIONS.md        ← used throughout — ambiguity tracker
│
├── global_CLAUDE.md         ← copy to ~/.claude/CLAUDE.md (personal)
│
└── .claude/
    ├── settings.json        ← build hook + HIPAA guard
    └── skills/
        ├── sdd-clarify/     ← /sdd-clarify  (after spec, before plan)
        ├── sdd-analyze/     ← /sdd-analyze  (after tasks, before implement)
        ├── spec-review/     ← /spec-review  (after each generation task)
        └── hipaa-check/     ← /hipaa-check  (after phase 3, before PR)
```

---

## Where Files Live in Your Project

```
pa_app/
├── CLAUDE.md                    ← project root
├── OPEN_QUESTIONS.md                  ← project root
│
├── specs/
│   └── 001-member-eligibility/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       └── eval.md
│
└── .claude/
    ├── settings.json
    └── skills/
        ├── sdd-clarify/SKILL.md
        ├── sdd-analyze/SKILL.md
        ├── spec-review/SKILL.md
        └── hipaa-check/SKILL.md
```

---

## Phase-by-Phase Guide

### Phase 0 — CLAUDE.md (once per project)
*Governs everything that follows*

1. Read the codebase — 7 key files
2. Ask Claude to generate CLAUDE.md from reading those files
3. Review every rule — ensure it is derived, not invented
4. Commit → never change without team agreement

---

### Phase 1 — SPEC.md (once per feature)
*Define WHAT — not HOW*

1. Write a one-line feature description
2. Ask Claude to generate spec.md from the description + CLAUDE.md
3. Run `/sdd-clarify` → resolve all BLOCKING questions
4. Review section 7 (non-goals) — minimum 4 entries
5. Approve → commit

---

### Phase 2 — PLAN.md (once per feature)
*Define HOW — architecture decisions*

1. Ask Claude to generate plan.md from spec.md + CLAUDE.md
2. Review section 8 (constitution compliance check) — all boxes ticked
3. Verify section 7 non-goals are absent from the plan
4. Approve → commit

---

### Phase 3 — TASKS.md (once per feature)
*Break plan into executable steps*

1. Ask Claude to generate tasks.md from plan.md
2. Run `/sdd-analyze` → must show READY TO IMPLEMENT
3. Identify parallelisable tasks → create worktrees for them
4. Approve → commit

---

### Phase 4 — IMPLEMENT (one session per task)
*Execute tasks in order — one Claude session per task*

For each task in tasks.md:
1. Open Claude Code: `claude`
2. Prompt: "Execute Task [N.N] from specs/001/tasks.md. Read the pattern reference files listed in the task. Stop after this task only."
3. Watch build hook fire automatically
4. Run `/spec-review` after each phase
5. Mark task `[x]` when done
6. Commit

For parallelisable tasks:
- Create worktrees: `git worktree add ../pa_app-[label] feature/[branch]`
- Run Claude in each worktree simultaneously
- Review diff before merging each branch

---

### Phase 5 — EVAL.md (once per feature)
*Evidence before PR*

1. Run application: `dotnet run`
2. Test each AC in Swagger
3. Run `/hipaa-check` → must show COMPLIANT
4. Run `/spec-review` → must show zero FAIL
5. Fill eval.md — paste all outputs
6. Update CLAUDE.md with new patterns
7. Commit → raise PR

---

## The Four Skills — When to Use Each

| Skill | Run after | Before | Purpose |
|-------|-----------|--------|---------|
| `/sdd-clarify` | spec.md written | plan.md | Find spec gaps |
| `/sdd-analyze` | tasks.md written | implement | Cross-artifact check |
| `/spec-review` | each task | next task | AC coverage check |
| `/hipaa-check` | Phase 3 | PR | Compliance gate |

---

## Key Rules

**CLAUDE.md** — read the code. Every rule must come from evidence.

**SPEC.md section 7** — minimum 4 non-goals. Be aggressive.

**TASKS.md** — one task per Claude session. Never combine phases.

**EVAL.md** — written by human. Not Claude. PR blocked until complete.

**Worktrees** — only for tasks with zero shared file dependencies.
