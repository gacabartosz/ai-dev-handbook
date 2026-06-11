#!/bin/bash
# Status line for Claude Code: model | directory | context-window usage %
# (section 7 of GUIDELINES.md)
#
# Installation:
#   1. cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#   2. in ~/.claude/settings.json:
#      "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#   (or just run the /statusline command — Claude Code will configure it for you)
#
# Claude Code provides session JSON on stdin, including model.display_name,
# workspace.current_dir, context_window.used_percentage, transcript_path.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"' | sed "s|^$HOME|~|")

# Context usage: the context_window.used_percentage field (provided by Claude Code).
# Fallback for older versions: compute from the last usage entry in the session
# transcript (JSONL).
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)

if [[ -z "$pct" ]]; then
  transcript=$(echo "$input" | jq -r '.transcript_path // empty')
  window=${CLAUDE_CONTEXT_WINDOW:-200000}
  if [[ -n "$transcript" && -f "$transcript" ]]; then
    used=$(tail -n 200 "$transcript" | jq -rs '
      [ .[] | select(.message.usage != null) | .message.usage ] | last //
        {input_tokens:0, cache_read_input_tokens:0, cache_creation_input_tokens:0} |
      (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
    ' 2>/dev/null)
    [[ "$used" =~ ^[0-9]+$ && "$used" -gt 0 ]] && pct=$(( used * 100 / window ))
  fi
fi

ctx="ctx ?"
if [[ "$pct" =~ ^[0-9]+$ ]]; then
  # thresholds: green <50%, yellow 50-70%, red >70% (time for /compact or /clear)
  if   (( pct < 50 )); then color="\033[32m"
  elif (( pct < 70 )); then color="\033[33m"
  else                      color="\033[31m"; fi
  ctx=$(printf "${color}ctx %d%%\033[0m" "$pct")
fi

printf "%s | %s | %b" "$model" "$cwd" "$ctx"
