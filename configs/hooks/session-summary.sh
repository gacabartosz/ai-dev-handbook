#!/bin/bash
# Stop hook: when a turn ends, Haiku summarizes the session into ~/.claude/session-log.md
# (section 14 of GUIDELINES.md). A minimal local equivalent of a Langfuse integration.
#
# Installation: see settings.example.json (hooks.Stop).

# Guard: don't run recursively — the `claude -p` called below has hooks too,
# so without this environment variable the hook would invoke itself in a loop.
[[ -n "$CC_SESSION_SUMMARY_RUNNING" ]] && exit 0

input=$(cat)

transcript=$(echo "$input" | jq -r '.transcript_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
[[ -z "$transcript" || ! -f "$transcript" ]] && exit 0

logfile="$HOME/.claude/session-log.md"

# Latest transcript entries (JSONL) -> text content only, truncated
excerpt=$(tail -n 60 "$transcript" | jq -r '
  select(.message.content != null) |
  .message.content |
  if type == "array" then [ .[] | select(.type == "text") | .text ] | join("\n") else . end
' 2>/dev/null | tail -c 8000)

[[ -z "$excerpt" ]] && exit 0

summary=$(CC_SESSION_SUMMARY_RUNNING=1 claude -p \
  --model haiku \
  "Summarize in at most 3 bullet points what was done in this coding session and whether anything was left unfinished. Bullets only, no preamble:

$excerpt" 2>/dev/null)

[[ -z "$summary" ]] && exit 0

{
  echo ""
  echo "## $(date '+%Y-%m-%d %H:%M') — session \`$session_id\`"
  echo "$summary"
} >> "$logfile"

exit 0
