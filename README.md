# AI Dev Handbook

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-d97757)](https://code.claude.com)
[![Works with Codex](https://img.shields.io/badge/Works%20with-Codex-10a37f)](#)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#)

Battle-tested guidelines for team workflows with AI coding agents (Claude Code, Codex) —
plus a **one-command install** of working configs: hooks, statusline, subagents, skills
and rule templates. Every component ships with a self-test (`verify.sh`), so you know it
works before and after installing.

**Main document: [GUIDELINES.md](GUIDELINES.md)** — 20 sections + a 15-item TL;DR
checklist to roll out tomorrow. Part I: organizing the work of teams and agents
(rule standardization, hooks, context management, model selection, parallel work,
coordination, observability). Part II — Dev Skills Pack: engineering disciplines
(TDD, security, debugging, permissions, CI) translated into tool mechanisms.

## Install (one command)

```bash
git clone https://github.com/gacabartosz/ai-dev-handbook
cd ai-dev-handbook
./install.sh      # solo dev pushing straight to main? → SKIP_MERGE_GUARD=1 ./install.sh
./verify.sh --live
```

The installer is **idempotent and non-destructive**: it backs up `settings.json` with a
timestamp, deep-merges new entries via `jq`, and never overwrites anything you already
configured. Flags: `SKIP_MERGE_GUARD=1` (skip the merge/push blocker),
`SKIP_SUMMARY=1` (skip session summaries), `SKIP_NOTIFY=1` (skip macOS notifications).

## Key theses

- **Prompts are interpreted; hooks are executed.** Hard bans (merge, push to main) must
  live in hooks and branch protection, not in CLAUDE.md — a model that "finds no clear
  statement that it is forbidden" will conclude it's allowed.
- **No ban = permission.** Write rules as a contract: verb + object + condition + what
  instead. After every model upgrade — smoke-test your rules.
- **One rules file for all tools:** `AGENTS.md` canonical, `CLAUDE.md` a symlink.
- **Model per task:** Haiku — 1 SP, Sonnet — 3–8 SP, Opus — planning and debugging.
- **Specs are reviewed by a different vendor than the author** — a model doesn't see the
  flaws in its own artifact.
- **A test failing before implementation is the only instruction a model can't talk its
  way around.**

## What's inside

| File | What it does | Section |
|---|---|---|
| `install.sh` | one-command, idempotent install into `~/.claude` (with settings backup) | — |
| `verify.sh` | self-test: syntax, formats, functional hook/statusline tests, `--live` skill discovery | — |
| `configs/settings.example.json` | reference settings.json: statusline, hooks, deny rules | 4, 7, 19 |
| `configs/statusline.sh` | context-window usage bar (50/70% thresholds) | 7 |
| `configs/hooks/block-git-merge.sh` | PreToolUse: hard block on merge / push to main | 4 |
| `configs/hooks/session-summary.sh` | Stop: Haiku summarizes the session to `~/.claude/session-log.md` | 14 |
| `configs/CLAUDE.template.md` | project rules template with a "WHAT NOT TO DO" section | 5, 6 |
| `configs/AGENTS-symlink.md` | one rules file for Claude and Codex (symlink) | 2 |
| `configs/agents/quick-fix-haiku.md` | Haiku subagent for 1-SP tasks | 8 |
| `configs/agents/planner-opus.md` | Opus planning subagent (no write access) | 8 |
| `configs/agents/reviewer-codex.md` | cross-vendor spec review via the Codex CLI | 9 |
| `configs/agents/security-auditor.md` | PR-diff security audit (Opus, no write access) | 17 |
| `configs/skills/tdd-loop/` | TDD loop with hard bans (don't delete tests…) | 16 |
| `configs/skills/debug-protocol/` | reproduce → hypothesize → fix → proof + regression | 18 |
| `configs/skills/secure-by-default/` | non-negotiable security checklist | 17 |

## Manual install

Prefer doing it by hand? Each step from `install.sh`, spelled out:

```bash
# 1. statusline
cp configs/statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh

# 2. hooks
mkdir -p ~/.claude/hooks
cp configs/hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh

# 3. settings — do NOT overwrite your live file; merge the statusLine/hooks/permissions
#    sections from configs/settings.example.json into ~/.claude/settings.json

# 4. subagents and skills (globally — or per repo in <repo>/.claude/)
mkdir -p ~/.claude/agents ~/.claude/skills
cp configs/agents/*.md ~/.claude/agents/
cp -R configs/skills/* ~/.claude/skills/

# 5. in every active repo: one rules file — see configs/AGENTS-symlink.md
```

## License

MIT — see [LICENSE](LICENSE).
