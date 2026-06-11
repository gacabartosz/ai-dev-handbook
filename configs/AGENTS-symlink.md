# One rules file for Claude Code and Codex (CLAUDE.md = AGENTS.md)

Codex reads `AGENTS.md`, Claude Code reads `CLAUDE.md`. An alias (symlink) makes both
tools work on exactly the same rules — zero drift between developers.

## Setup in an existing repo

```bash
cd <repo>

# Variant A: you already have CLAUDE.md and are adding Codex
git mv CLAUDE.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
git add CLAUDE.md
git commit -m "Unify agent rules: AGENTS.md canonical, CLAUDE.md symlink"

# Variant B: a new repo
cp <ai-dev-handbook>/configs/CLAUDE.template.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
git add AGENTS.md CLAUDE.md
```

`AGENTS.md` is canonical (the format read by Codex and a growing number of tools);
`CLAUDE.md` is a symlink for Claude Code. Git versions symlinks correctly.

## Notes

- **Windows on the team?** Symlinks in git require `core.symlinks=true` and the right
  privileges — if that's a problem, instead of a symlink use a one-line `CLAUDE.md`
  containing: `@AGENTS.md` (Claude Code expands `@path` imports in memory files).
- Per-module rules work the same way: `src/billing/AGENTS.md` + a symlink next to it.
- Check that both files don't exist side by side with DIFFERENT content — that's worse
  than no rules at all, because each tool then plays by different rules. Repo audit:
  ```bash
  for d in */; do
    [ -f "$d/CLAUDE.md" ] && [ -f "$d/AGENTS.md" ] && [ ! -L "$d/CLAUDE.md" ] && \
      ! diff -q "$d/CLAUDE.md" "$d/AGENTS.md" >/dev/null && echo "DRIFT: $d"
  done
  ```
