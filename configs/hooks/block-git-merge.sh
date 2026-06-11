#!/bin/bash
# PreToolUse hook: hard block on merge / push to main — regardless of how the model
# "interprets" CLAUDE.md (section 4 of GUIDELINES.md).
#
# Installation: see settings.example.json (hooks.PreToolUse, matcher "Bash").
# Mechanics: the hook receives JSON on stdin with tool_input.command.
#   exit 0  -> the command passes
#   exit 2  -> the command is BLOCKED; stderr is fed back to the model as the explanation

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[[ -z "$command" ]] && exit 0

block() {
  echo "BLOCKED by hook: $1" >&2
  echo "Team rule: merging and pushing to main is done exclusively by a human." >&2
  echo "Finish your work, print the PR link and stop." >&2
  exit 2
}

# git merge (in any form, including chains like `cd x && git merge`)
if echo "$command" | grep -qE '(^|[;&|]\s*)git\s+merge\b'; then
  block "git merge"
fi

# gh pr merge
if echo "$command" | grep -qE '(^|[;&|]\s*)gh\s+pr\s+merge\b'; then
  block "gh pr merge"
fi

# git push to main/master (explicit or forced)
if echo "$command" | grep -qE '(^|[;&|]\s*)git\s+push\b.*\b(main|master)\b'; then
  block "git push to main/master"
fi
if echo "$command" | grep -qE '(^|[;&|]\s*)git\s+push\b.*(--force|-f)\b'; then
  block "git push --force"
fi

exit 0
