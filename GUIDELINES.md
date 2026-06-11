# AI Dev Handbook — team workflows for Claude Code and Codex

> A handbook for teams that work with AI agents every day: from a single developer
> running a few parallel sessions to organizations with hundreds of licenses.
> Every section has two parts: **⚠ Problem** (what actually breaks in teams) and
> **🛠 Rule** (how to fix it with tool mechanisms — hooks, settings, subagents, skills).
>
> The document has two parts: **Part I** (sections 1–15) — organizing the work of teams
> and agents, **Part II — Dev Skills Pack** (sections 16–20) — engineering disciplines:
> TDD, security, debugging, permissions, CI.
>
> Ready-to-copy config files: see [`configs/`](configs/).

---

# Part I — Organizing the work of teams and agents

## 1. Standardizing tools and licenses across the team

**⚠ Problem**
In larger organizations a tool zoo grows naturally: two dominant tools (typically Claude
Code + Cursor, ~90% of usage combined) and a long tail of "5–10 license" things someone
wanted to try — and two months later nobody uses them, and nobody reports that either.

**🛠 Rule**
- Freedom to **experiment**, standardization of **process**: let everyone test whatever
  they want, but keep rules, hooks and skills in a tool-agnostic format (sections 2 and 3).
- Audit licenses with data, not memory: admin panels (console.anthropic.com /
  Team-Enterprise plan, Cursor's panel) show last activity per seat. Make "90 days without
  activity = seat returns to the pool" a policy, not a judgment call.
- Two tools in a team is not pathology, it's **redundancy**: cross-vendor review
  (section 9) requires access to at least two model families.

---

## 2. One source of rules: CLAUDE.md = AGENTS.md

**⚠ Problem**
Codex reads `AGENTS.md`, Claude Code reads `CLAUDE.md`. When rules live in only one of
them, half the team works without them — and the same code gets written under different
rules depending on who uses which tool.

**🛠 Rule**
- Keep **one** rules file in the repo plus a symlink:
  ```bash
  # AGENTS.md as canonical (read by Codex and a growing number of tools),
  # CLAUDE.md as a symlink for Claude Code:
  ln -s AGENTS.md CLAUDE.md
  git add AGENTS.md CLAUDE.md   # git versions symlinks correctly
  ```
  Step-by-step instructions: [`configs/AGENTS-symlink.md`](configs/AGENTS-symlink.md).
- The whole flow must behave the same on the same rules — you only swap the engine
  underneath (Sonnet, Opus, Codex, whatever).
- Claude Code memory file hierarchy: `~/.claude/CLAUDE.md` (global, private to the
  developer) → `<repo>/CLAUDE.md` (team-wide, in git) → `<repo>/subdir/CLAUDE.md`
  (per module). Team rules **must** live in the repo, not in developers' home files.
- A template for a good rules file (with a "WHAT NOT TO DO" section — see section 6):
  [`configs/CLAUDE.template.md`](configs/CLAUDE.template.md).

---

## 3. A central "marketplace" of rules, skills and hooks

**⚠ Problem**
Rules added "YOLO, everyone appends something" drift apart between people and projects.
Rules consumed by AI affect the whole team's work — they must be agreed upon, deliberate,
and distributed from one place.

**🛠 Rule**
- Claude Code has this built in: the **plugin marketplace**. One git repo in the org with
  a `.claude-plugin/marketplace.json` file, containing plugins that package skills, agents,
  hooks and commands. A developer connects once: `/plugin marketplace add <org>/<repo>`,
  then `/plugin install <name>` — the whole team pulls the same versions from git.
- Minimal variant without plugins: a `.claude/` directory (skills/, agents/, settings.json
  with hooks) **committed in the project repo**. Everything team-wide goes to git;
  `settings.local.json` stays for personal deviations.
- Appoint an owner for these files. Rule changes go through PR like code — because they
  **are** code, just executed by a model.

---

## 4. Hard bans = hooks, not prompts

**⚠ Problem**
A classic post-model-upgrade scenario: an agent that always stopped before merging
("PR ready for human approval") suddenly starts **merging on its own**. Asked why, it
answers: "I analyzed AGENTS.md and CLAUDE.md and found no clear statement that it is
forbidden." On top of that, instructions from the start of a long session simply fall out
of the model's attention — you cannot rely on something "being written down".

**🛠 Rule** — three layers of defense, hardest first:
1. **Platform** (always works): GitHub branch protection — required reviews, force-push
   blocked, merge only via PR. Catches humans too, not just agents.
2. **PreToolUse hook** (runs deterministically, before the tool executes): the script
   receives JSON on stdin with `tool_input.command`, detects `git merge` / `git push` to
   main / `gh pr merge`, and exits with **exit code 2** — the call is blocked and the
   stderr text is fed back to the model as the explanation. Ready-made script:
   [`configs/hooks/block-git-merge.sh`](configs/hooks/block-git-merge.sh), wiring in
   [`configs/settings.example.json`](configs/settings.example.json).
3. **Prompt/CLAUDE.md** (softest layer): still write the ban into the rules — the model
   then doesn't try and doesn't waste a turn — but treat it as UX, not as a safeguard.

Rule of thumb: **if breaking a rule has a cost, the rule must not exist only in natural
language.** Prompts are interpreted; hooks are executed.

---

## 5. Instruction precision: no ban = permission

**⚠ Problem**
Different models — within one vendor and across vendors — interpret the same imprecise
instructions differently. You see it with every new release: a model suddenly stops
following rules that "used to work". Opinions like "this model is better/worse" often
come down to imprecise instructions — just like with people.

**🛠 Rule**
- Write rules as a **contract, not a wish**: verb + object + condition + what instead.
  Bad: "be careful with merging". Good: "NEVER run `git merge` or `gh pr merge`. When
  done, print the PR link and STOP — a human performs the merge."
- Treat every model upgrade as an **environment change**: run your rule set through it
  (a smoke test on 2–3 typical tasks) before the team switches to the new model.
- Don't count on the model's memory in a long session — keep critical instructions in
  CLAUDE.md (loaded into every session), not in the first prompt of a conversation.

---

## 6. Specs with a "what NOT to do" section

**⚠ Problem**
A spec that only describes what should be built leaves the model the entire remaining
decision space — and that's exactly where "magic", hallucinations and unrequested
changes are born.

**🛠 Rule**
- For larger tasks/epics, the pre-implementation analysis describes scope, execution
  structure, expected outcome **and an explicit list of what the model must NOT do**.
  The negative list works because it closes the interpretation space (section 5).
- Standard entries: "don't change files outside directory X", "don't add dependencies",
  "don't refactor code unrelated to the task", "don't catch broad exceptions — name the
  concrete type", "don't write sham tests that verify nothing".
- Constraints **repeated across the repo** → CLAUDE.md/AGENTS.md. Constraints
  **per task** → the task description/spec. Constraints **portable between projects** →
  a skill (`SKILL.md` with `name` + `description` frontmatter — Claude loads it on its
  own when it matches). That's how a portable mini-base of good practices grows.
- Spec template with the negative section: [`configs/CLAUDE.template.md`](configs/CLAUDE.template.md).

---

## 7. Context management: statusline, thresholds, /compact, subagents

**⚠ Problem**
The longer the session, the more expensive and worse it gets: every turn sends the entire
context so far, tokens "accelerate", session limits drain faster, and the model holds
instructions more and more loosely. Teams that don't measure this ride up to 60–70% of
the window and wonder about the quality drop; teams that measure stay around 15–50%.

**🛠 Rule**
- **A statusline with context % is the first thing to deploy** — ready-made script:
  [`configs/statusline.sh`](configs/statusline.sh) (reads session JSON from stdin;
  Claude Code provides a ready `context_window.used_percentage` field there). Wire it up
  via the `statusLine` key in settings.json or the `/statusline` command.
- Check `/context` — it shows the window breakdown (system prompt, MCP tools, files,
  history). Often the "eaten context" isn't the conversation but an excess of connected
  MCP servers.
- Practical thresholds: work normally up to ~50%; schedule `/compact` at **task
  boundaries** (after closing a task, not mid-work — compacting halfway loses details).
  New task = ideally a new session (`/clear`) — cheaper and cleaner than dragging out
  the old one.
- Cut tasks so a single agent run takes ~20 minutes — longer runs signal the task was
  too big or under-specified.
- Subagents (Task tool / `.claude/agents/`) have **their own context windows** — delegate
  research, log review and wide greps downward; only the conclusion returns to the main
  window.

---

## 8. Matching the model to task complexity

**⚠ Problem**
A 1-story-point task can be done with the most expensive model — the question is why.
The other direction hurts more: planning architecture with a cheap model produces plans
you later have to unwind at the code level.

**🛠 Rule**
- Starting mapping (calibrate with your own data):
  | Task | Model |
  |---|---|
  | 1 SP: typos, small fixes, formatting, summaries | Haiku |
  | 3–8 SP: implementation within an existing pattern, tests, module refactor | Sonnet |
  | Planning, architecture, "no idea why it doesn't work" debugging | Opus |
  | Security audit, whole-application review | strongest available |
- A subagent in `.claude/agents/<name>.md` has a `model:` field in its frontmatter
  (`haiku` / `sonnet` / `opus` / `inherit`) — the orchestrator picks a "junior/mid/senior"
  for the estimated task. Ready-made examples:
  [`configs/agents/quick-fix-haiku.md`](configs/agents/quick-fix-haiku.md),
  [`configs/agents/planner-opus.md`](configs/agents/planner-opus.md),
  [`configs/agents/reviewer-codex.md`](configs/agents/reviewer-codex.md).
- Separate agent instructions per process function (spec, implementation, code review,
  spec review) — each with its assigned model.
- A profitable pattern: **the expensive model plans, the cheap one executes.** Plan with
  Opus (plan mode), execute with Sonnet following the plan, verify with the expensive
  one again.

---

## 9. Multi-model spec review (cross-vendor)

**⚠ Problem**
If the same model wrote the spec and the same model reviews it, it will most likely see
nothing wrong — it shares "taste" and blind spots with its own artifact. Meanwhile spec
bugs (contradictions, ambiguities, missing edge cases) are the most expensive ones:
after implementation it sometimes turns out everything must be thrown away because it
went down a dead end.

**🛠 Rule**
- A spec is reviewed by **a model from a different family than the author**. A reviewer
  from another family has different priors and sees different holes — in practice, with
  2–3 reviewers from different families, one of them almost always finds something real
  and substantial.
- Cheapest implementation: a subagent with Bash access that calls the other vendor's CLI
  (`codex exec ...`) and organizes the findings —
  [`configs/agents/reviewer-codex.md`](configs/agents/reviewer-codex.md).
- Profitability threshold: epic spec / architectural decision — always multi-model.
  A single bugfix — one reviewer is enough, but **different from the author** (written by
  Sonnet → reviewed by Opus).
- Spec review is a different activity than code review: the reviewer hunts for
  contradictions, missing edge cases and places two models would interpret differently
  (section 5) — not style.

---

## 10. Repo strategy and PR hygiene at agent velocity

**⚠ Problem**
With agents, the amount of code produced in small and mid-size projects grows several
times over. The classic ticket-based division of work stops working — "someone has
already almost crossed into the other person's area". And a hard observation: **a PR
that hangs for a week is a write-off** — after a few days other agents change so much
that the conflict can't be untangled.

**🛠 Rule**
- "PR freshness" is measured in hours: PRs small (one module, one function), review in
  ≤24h (an agent can do the first pass right after opening), rebase daily or close it.
- Split work per **module/directory**, not per ticket — and write the boundaries into
  the module's CLAUDE.md (`src/billing/CLAUDE.md`: "this directory is the billing
  module; do not modify anything outside it").
- A monorepo is simply more convenient for agents (one context, one checkout);
  multi-repo works, but worse. If you have multi-repo — keep all repos cloned next to
  each other and open the session from the parent directory (`claude --add-dir` attaches
  extra directories to a session).
- In very large legacy codebases (tens of millions of lines) agent coordination is less
  of a problem — because the flood of agent-generated code is smaller too. Prioritize
  these rules where velocity is genuinely high.

---

## 11. Parallel work: worktrees and managing multiple sessions

**⚠ Problem**
Working with 5–10 parallel agents is realistic, but two things kill it: instances
stepping on each other (same ports, same directory) and lost attention — the agent
finished 50 minutes ago and you forgot about it.

**🛠 Rule**
- Isolation via **git worktrees**: `git worktree add ../proj-feature-x -b feature-x`
  and a separate session in each. Each worktree = separate directory = zero file
  conflicts. Session-manager tools (with built-in worktree creation, tracker integration
  and per-session statuses) tidy this up further — but the principle works without them.
- Worktree startup script: rebuild dependencies + **deterministic port remapping**
  (e.g. port derived from a hash of the branch name, written to `.env.local`) so two
  running instances of the app and database don't clash.
- Notifications without extra tooling: a **Notification** / **Stop** hook in
  settings.json calls `osascript -e 'display notification ...'` (macOS) — you know the
  agent finished or is waiting for input before you forget about it.
- Post the task plan **as the first comment on the GitHub issue** (`gh issue comment`):
  every subsequent agent and reviewer has that context, and the agent uses it itself via
  the `gh` CLI — even after clearing the session.
- Don't take two tasks "next to each other" in the code — take distant ones; adjacent
  tasks = guaranteed merge conflicts.
- The parallelism limit is set not by the tool but by **your review capacity** — above
  ~5–8 sessions the queue of unverified work grows, not throughput.

---

## 12. An epic coordinator agent

**⚠ Problem**
With many agents and many machines working on one epic, nobody knows what's actually in
progress: two agents grab the same task, and dependent tasks start before their
dependencies.

**🛠 Rule**
- Carve out a **coordinator** role: an agent that **implements nothing itself** — it
  reads the epic and its subtasks in the tracker (JIRA/Linear/ClickUp via MCP), reports
  progress, decides which tasks can run in parallel and which must wait, and generates
  ready-made "session prompts" for the executor agents.
- Technically: a subagent with access **only** to read tools + the tracker MCP, no
  Edit/Write — so it physically cannot "help" with implementation. Separating planning
  from execution is the same principle as plan mode for a single session.
- **The tracker as the only semaphore**: "in progress" status + assigned executor
  (session ID) in the tracker is a mutex on the task — it works across machines and
  across people, with no extra infrastructure. The coordinator also checks PRs (what's
  actually merged) and releases subsequent tasks based on that.
- Session prompts = a formalized handoff. Fixed format: goal, files/module, what NOT to
  do (section 6), definition of done, how to report the result.

---

## 13. Autonomy with placeholders, human-in-the-loop at the end of an area

**⚠ Problem**
A pipeline that stops at every doubt and waits for a human loses the entire advantage of
autonomy. A pipeline that quietly resolves doubts by itself — produces surprises.

**🛠 Rule**
- A non-blocking doubt **does not stop the work**: a placeholder lands in the code, the
  description goes to a comment on the task (tracker as the single source of truth), the
  responsible developer gets a ping — and decisions are made later, in batches.
  Human-in-the-loop at the **end of an area**, not per task and not per doubt.
- The placeholder must be **greppable and tagged**: one agreed marker
  (e.g. `// TODO(decision): <question> — @owner, ticket ABC-123`), plus a simple CI check
  that won't ship a release with open `decision` markers. Autonomy without this turns
  into silent debt.
- The autonomy boundary written explicitly into the agent's rules: what it may do without
  asking (implementation per spec, tests, placeholders) and what never (public API
  changes, data migrations, merge — section 4).
- Do part of the verification deterministically (scripts, regexes), part via
  `claude -p "<prompt>"` (headless mode) with `--output-format json` and `--allowedTools`
  narrowed to read-only — the right tool for repeatable verifications in scripts.
- Discoveries outside the task's scope → a **follow-up ticket**, not scope creep. Give
  the agent this rule in its instructions: "if you discover a problem outside the task's
  scope, do NOT fix it; describe it and file a follow-up".

---

## 14. Observability: session logs, summaries, session IDs on tasks

**⚠ Problem**
Agent sessions scattered across developers' machines are unauditable: nobody knows which
session did which task, where "things went sideways", or what the team could learn from
those sessions.

**🛠 Rule**
- The mechanics that enable this: every hook receives JSON on stdin with `session_id`
  and `transcript_path` (the full session record in JSONL). The **Stop** hook fires when
  a turn ends — the perfect place to export to an observability tool (e.g. self-hosted
  Langfuse; the integration boils down to simple scripts in hooks) or a local summary.
- Ready-made minimal variant:
  [`configs/hooks/session-summary.sh`](configs/hooks/session-summary.sh) — a Stop hook in
  which Haiku (`claude -p --model haiku`) summarizes the tail of the transcript into
  `~/.claude/session-log.md`. Watch out for the loop: the `claude -p` called from the
  hook has hooks itself, so the script has a guard (an environment variable) against
  recursion.
- **Session ID as a custom field on the task** (automated — the same Stop hook can add a
  `session: <id>` comment to the issue via `gh`/MCP): you can always return to the
  session that did the task and find where it went off the rails.
- Review collected logs with models (what works, what doesn't; scoring of tools and
  skills) — especially at model upgrades: running old sessions through the new model
  shows whether it draws different conclusions from the same context.
- Claude Code also supports OpenTelemetry (metrics/events to your own backend) — an
  option for teams that want a dashboard instead of files.

---

## 15. Target direction: zero prompts

**⚠ Problem**
Daily work with agents is repetitive — and yet developers keep writing the same prompts
over and over, each time slightly different, with slightly different results.

**🛠 Rule**
- Goal: **don't write prompts.** If the spec, rules, agents and skills are well crafted,
  an ad-hoc prompt becomes the exception, not the norm. Catch recurring user prompts
  (e.g. from session logs, section 14) and turn them into artifacts.
- Practical conversion rule: **you wrote a similar prompt for the third time → it's a
  skill** (`.claude/skills/<name>/SKILL.md`; the `description` frontmatter decides when
  the model loads it on its own). A prompt with parameters → a command `/name`
  (`.claude/commands/name.md` with `$ARGUMENTS`). A prompt + separate context + specific
  model → a subagent.
- Eventually the model becomes a "programming language": sets of commands, loops,
  conditionals — except underneath, instead of classes and methods, an agent works with
  the rule set you prepared.
- Team maturity ladder: ad-hoc prompts → CLAUDE.md → commands/skills → subagents →
  hooks/CI. Each rung converts another piece of "oral tradition" into a versioned,
  shared artifact — and that is the right answer to every problem in this document.

---

# Part II — Dev Skills Pack

> A set of engineering disciplines ("dev skills") translated into Claude Code mechanisms:
> skills, subagents, hooks. Ready-made files: [`configs/skills/`](configs/skills/)
> and [`configs/agents/`](configs/agents/). The overarching rule: **a discipline you want
> to keep must exist as an artifact in the repo — not as an intention in a developer's
> head or in a prompt.**

## 16. The TDD loop: a test is a spec the model cannot reinterpret

The most effective answer to "no ban = permission" (section 5) is converting expectations
into tests. A test failing before implementation is the only instruction no model can
talk its way around — it either passes or it doesn't.

- Agent workflow: **(1)** write tests from the spec → **(2)** run them, confirm they fail
  (a test passing before implementation = a broken test) → **(3)** implement to green →
  **(4)** refactor on green. Skill: [`configs/skills/tdd-loop/SKILL.md`](configs/skills/tdd-loop/SKILL.md).
- Two hard bans for CLAUDE.md **and** for a hook/CI: don't delete or skip tests to "make
  it pass"; don't weaken assertions. An agent under green-build pressure will do this
  more eagerly than a human — because it feels no shame.
- Anti-patterns to ban explicitly: sham tests written after the implementation,
  assertions on constants, mocking the function under test. Have tests reviewed by a
  different model than the author (section 9 — the same self-review bias applies to
  tests).

## 17. Security review as a gate, not a quarterly audit

Agent velocity (section 10) means a vulnerability reaches main in hours, not weeks.
Security review must therefore run at the same rhythm as the code.

- An auditor subagent with a strong model and no write access:
  [`configs/agents/security-auditor.md`](configs/agents/security-auditor.md). Run on the
  PR diff, not the whole repo — short, cheap, on every change touching user input, auth,
  cryptography or database queries.
- A "minimum we don't negotiate" checklist:
  [`configs/skills/secure-by-default/SKILL.md`](configs/skills/secure-by-default/SKILL.md)
  (parameterized queries, validation at the system boundary, secrets only from env,
  dependencies from the lockfile, no `eval` on external data).
- A special rule for teams building ON models: **never feed user-generated content (UGC)
  to an agent with shell access without a sandbox and a tool allowlist** — prompt
  injection in UGC is a code-execution vector, not a theoretical risk.

## 18. Debugging protocol: reproduce first, hypothesize next, fix last

Models have a strong "fix it immediately" reflex — and they can fix the symptom in the
wrong place, adding code that cures nothing. Debugging discipline must be written down
as a procedure the agent follows step by step.

- Protocol: **(1)** reproduce the bug (ideally as a failing test — that's your regression
  test for free) → **(2)** narrow down the cause (logs, bisect, minimal case) →
  **(3)** form a hypothesis and CONFIRM it before changing anything → **(4)** fix the
  cause, not the symptom → **(5)** the regression test stays in the repo. Skill:
  [`configs/skills/debug-protocol/SKILL.md`](configs/skills/debug-protocol/SKILL.md).
- A hard ban for the rules: "You must NOT report a fix without reproducing the bug before
  the change and without proof that the reproduction passes after it." This eliminates
  the "fixed it, should work now" class — the most expensive words in agent work.
- Debugging is a job for the strongest model (section 8) — it's exactly the kind of work
  where a cheap model generates a loop of consecutive missed attempts that costs more
  than one accurate diagnosis from the expensive one.

## 19. Permissions and sandbox: narrow by default, widen deliberately

The symmetric complement of section 4: hooks block known bad actions, permissions shrink
the action space altogether.

- Three levels in settings.json: `permissions.allow` (commands without prompting — build
  the allowlist from real denials, not from imagination), `permissions.ask` (prompt),
  `permissions.deny` (hard no — duplicate the hook bans here, defense in depth).
- `--dangerously-skip-permissions` only in an isolated environment (container/VM with no
  access to secrets or production). Never on a machine with keys; never when untrusted
  input can reach the session.
- Team file split: `settings.json` in the repo = team policy (goes through PR),
  `settings.local.json` = a developer's personal deviations (gitignored). The exact same
  logic as the rules in section 3.

## 20. Headless in CI: the agent as a pipeline step

`claude -p` (non-interactive mode) closes the loop: the same skills and rules that work
in a developer's session work as automation in CI.

- Patterns: a first review pass on a fresh PR (before a human sits down), spec
  verification before implementation, checking for open `TODO(decision)` markers before
  a release (section 13).
- Safe-use rules in CI: `--allowedTools` narrowed to read-only (e.g. `"Read,Grep,Glob"`),
  `--output-format json` so a script can parse the result, a timeout on the step, and the
  agent's output as a **comment, not a blocking gate** — until you've measured the
  false-positive rate on your own PRs.
- Control cost with the model per use case, as in section 8: summaries and labels —
  Haiku; diff review — Sonnet; security audit of a change — strongest available.

---

## TL;DR — checklist to roll out tomorrow

1. ☐ Symlink `CLAUDE.md → AGENTS.md` in every active repo (section 2).
2. ☐ Statusline with context %: `configs/statusline.sh` + the `statusLine` entry in
   settings (section 7).
3. ☐ PreToolUse hook blocking merge/push to main: `configs/hooks/block-git-merge.sh`
   + GitHub branch protection (section 4).
4. ☐ A "WHAT NOT TO DO" section in CLAUDE.md — a contract, not wishes (sections 5–6).
5. ☐ Subagents with a `model:` field — Haiku for trivia, Opus for plans (section 8):
   `configs/agents/`.
6. ☐ Epic specs always reviewed by a different vendor's model than the author (section 9).
7. ☐ Work split per module + a PR lives a few days max (section 10).
8. ☐ Parallelism via git worktrees + notifications via the Notification/Stop hook
   (section 11).
9. ☐ The tracker (JIRA/ClickUp) as a semaphore: status + executor + session ID on the
   task (sections 12, 14).
10. ☐ A Stop hook logging/summarizing sessions: `configs/hooks/session-summary.sh`
    (section 14).
11. ☐ Every prompt written 3× → a skill or a command (section 15).
12. ☐ After every model upgrade — a smoke test of the rule set (section 5).
13. ☐ TDD as the agent's default mode: test fails → implementation → green; a ban on
    deleting/weakening tests in CLAUDE.md and in CI (section 16): `configs/skills/tdd-loop/`.
14. ☐ The security auditor on the diff of every sensitive PR + the secure-by-default
    checklist (section 17): `configs/agents/security-auditor.md`.
15. ☐ Bugfix only with a reproduction before and proof after — the debugging protocol
    (section 18): `configs/skills/debug-protocol/`.
