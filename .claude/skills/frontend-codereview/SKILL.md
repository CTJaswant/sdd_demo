---
 name: frontend-codereview
 description: Review TypeScript and React code for type safety, hook correctness, component patterns, and common bugs. Use this skill whenever the user asks to review, audit, check, or improve TypeScript (.ts) or React (.tsx) code — even if they just say "look at my code", "what's wrong with this", or paste a component. Triggers on any TS/React code review, refactor advice, or lint-check request.
 tools: read, grep, glop
 model: sonnet
---

  # TypeScript & React Code Review

  ## Workflow

  ### 1. Collect files
  - If uploaded: note path under `/mnt/user-data/uploads/`
  - If pasted inline: save to `/tmp/review-target/` via `bash_tool`

  ### 2. Run the linter
  ```bash
  bash /mnt/skills/user/ts-react-review/scripts/lint.sh <target_path>
  ```
  For JSON output (easier to parse programmatically):
  ```bash
  bash /mnt/skills/user/ts-react-review/scripts/lint.sh <target_path> --json
  ```
  The script auto-installs ESLint 8 + plugins into `/tmp/ts-review-lint` on first run.

  ### 3. Manual review checklist
  After linting, scan the code for issues ESLint won't catch:

  **TypeScript**
  - [ ] `any` types hiding real type errors
  - [ ] Missing return types on exported functions
  - [ ] Non-null assertions (`!`) masking null-safety issues
  - [ ] Overly wide union types that should be narrower

  **React**
  - [ ] Hook calls inside conditionals, loops, or callbacks
  - [ ] Missing or incorrect `useEffect` dependency arrays
  - [ ] Mutating state directly instead of via setter
  - [ ] Key props on dynamic lists (missing or using array index)
  - [ ] Large components that should be split

  **Performance**
  - [ ] Expensive calculations not wrapped in `useMemo`
  - [ ] Callbacks re-created on every render (missing `useCallback`)
  - [ ] Components missing `React.memo` where prop stability is guaranteed

  ### 4. Security Review
  4. Security review
  If the request involves auth, user input, external data, or the user asks for a security audit, load and apply:
  `/mnt/skills/user/frontend-codereview/security.md`
  ### 5. Produce the review

  Structure the output as:

  ```
  ## Code Review: <filename or description>

  ### 🔴 Errors  (must fix)
  ### 🟡 Warnings  (should fix)
  ### 🔵 Suggestions  (nice to have)
  ### ✅ What's good
  ```

  - Quote the relevant code snippet for each finding
  - Provide a corrected snippet for every 🔴 error
  - Keep suggestions concise — one paragraph max per item
  - If no issues found, say so clearly

  ## Scope

  This skill covers `.ts` and `.tsx` files only. For CSS-in-JS, testing files, or build config, note the limitation and offer a best-effort review without the linter.