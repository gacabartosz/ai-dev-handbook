# CLAUDE.md — project rules template

> Template aligned with sections 2, 5 and 6 of GUIDELINES.md. Copy into the repo as
> `AGENTS.md`, add a symlink `CLAUDE.md → AGENTS.md` (see AGENTS-symlink.md) and fill in.
> Write contracts, not wishes: verb + object + condition + what instead.

## Project

- What the project is (1–2 sentences).
- Stack: <language, framework, database, infra>.
- Commands: build `<...>`, test `<...>`, lint `<...>`, dev server `<...>`.

## Structure and module boundaries

- `src/<module-a>/` — <description>. When working on a task from this module, do not
  modify files outside it.
- `src/<module-b>/` — <description>.
- Shared: `src/shared/` — changes here require a separate task and review.

## Workflow

- Start every task with a plan; post the plan as the first comment on the issue
  (`gh issue comment`).
- After implementing, run tests and lint. If red — fix before opening a PR.
- After opening a PR, print the link and STOP. Wait for human review.
- A problem outside the task's scope: do NOT fix it. Describe it and file a follow-up
  (`gh issue create`), then return to the task.
- A doubt that doesn't block the whole task: insert a placeholder
  `// TODO(decision): <question> — ticket <ID>`, describe it in a task comment and keep
  going.

## WHAT NOT TO DO (negative list — a contract)

- NEVER run `git merge` or `gh pr merge`. Merging is done exclusively by a human.
  (This is also blocked by a hook — if you get BLOCKED, do not look for a workaround.)
- NEVER push to `main`/`master`. Work exclusively on feature branches.
- Do NOT add new dependencies without an explicit instruction in the task.
- Do NOT refactor code the task doesn't touch — even if it's "begging for it".
- Do NOT catch broad exceptions (`catch (Exception)` / bare `except:`). Catch the
  concrete type and handle it, or let the error propagate.
- Do NOT write sham tests (a test without assertions, or asserting on a constant,
  is not a test).
- Do NOT change the public API (signatures of exported functions, HTTP contracts,
  database schema) without a separate decision in the task.
- Do NOT commit secrets, keys, tokens or customer data. Including in tests and fixtures.
- Do NOT delete or disable existing tests to "make it pass".

## Definition of done

- [ ] Tests pass locally (`<command>`).
- [ ] Lint clean (`<command>`).
- [ ] No open `TODO(decision)` within the task's scope, or each one has a ticket.
- [ ] PR open, plan + result described in the issue, session stopped before merge.
