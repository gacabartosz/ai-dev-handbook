#!/bin/bash
# AI Dev Handbook — one-command installer for Claude Code.
#
# Installs into ~/.claude (override with CLAUDE_DIR):
#   statusline.sh, hooks/, agents/, skills/
# and SAFELY merges statusLine + hooks into settings.json (jq deep-merge,
# never overwrites existing entries; a timestamped backup is created first).
#
# Flags (environment variables):
#   SKIP_MERGE_GUARD=1   don't wire the PreToolUse merge/push blocker
#                        (recommended for solo devs who push to main directly)
#   SKIP_NOTIFY=1        don't wire the macOS notification hook
#   SKIP_SUMMARY=1       don't wire the Stop session-summary hook
#
# Idempotent: safe to run multiple times.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq >/dev/null || { echo "ERROR: jq is required (brew install jq / apt install jq)"; exit 1; }

echo "Installing AI Dev Handbook into $CLAUDE_DIR"

# --- 1. Files ---------------------------------------------------------------
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

cp "$REPO_DIR/configs/statusline.sh" "$CLAUDE_DIR/statusline.sh"
cp "$REPO_DIR/configs/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/hooks/"*.sh
echo "  [ok] statusline.sh + hooks/"

cp "$REPO_DIR/configs/agents/"*.md "$CLAUDE_DIR/agents/"
echo "  [ok] agents/ (quick-fix-haiku, planner-opus, reviewer-codex, security-auditor)"

cp -R "$REPO_DIR/configs/skills/tdd-loop" \
      "$REPO_DIR/configs/skills/debug-protocol" \
      "$REPO_DIR/configs/skills/secure-by-default" "$CLAUDE_DIR/skills/"
echo "  [ok] skills/ (tdd-loop, debug-protocol, secure-by-default)"

# --- 2. settings.json merge -------------------------------------------------
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq . "$SETTINGS" >/dev/null || { echo "ERROR: $SETTINGS is not valid JSON — fix it first"; exit 1; }

backup="$SETTINGS.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$backup"
echo "  [ok] settings backup: $backup"

merge() { # merge JQ_PROGRAM [args...]
  local prog=$1; shift
  jq "$@" "$prog" "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
}

# statusLine — only if not already configured
merge 'if .statusLine then . else .statusLine = {type:"command", command:"~/.claude/statusline.sh"} end'
echo "  [ok] statusLine wired (kept existing one if present)"

# hooks — append an entry only if that exact command isn't wired yet
add_hook() { # event matcher command
  merge '
    .hooks //= {} | .hooks[$e] //= [] |
    if ([.hooks[$e][]?.hooks[]?.command] | index($c)) then .
    else .hooks[$e] += [{matcher:$m, hooks:[{type:"command", command:$c}]}] end
  ' --arg e "$1" --arg m "$2" --arg c "$3"
}

if [ "${SKIP_MERGE_GUARD:-0}" != "1" ]; then
  add_hook "PreToolUse" "Bash" "~/.claude/hooks/block-git-merge.sh"
  echo "  [ok] PreToolUse hook: block-git-merge (disable: remove entry or SKIP_MERGE_GUARD=1)"
else
  echo "  [--] PreToolUse merge guard skipped (SKIP_MERGE_GUARD=1)"
fi

if [ "${SKIP_SUMMARY:-0}" != "1" ]; then
  add_hook "Stop" "" "~/.claude/hooks/session-summary.sh"
  echo "  [ok] Stop hook: session-summary -> ~/.claude/session-log.md"
else
  echo "  [--] Stop session-summary skipped (SKIP_SUMMARY=1)"
fi

if [ "${SKIP_NOTIFY:-0}" != "1" ] && [ "$(uname)" = "Darwin" ]; then
  add_hook "Notification" "" "osascript -e 'display notification \"Claude is waiting for input\" with title \"Claude Code\" sound name \"Glass\"'"
  echo "  [ok] Notification hook: macOS banner"
else
  echo "  [--] Notification hook skipped (non-macOS or SKIP_NOTIFY=1)"
fi

jq . "$SETTINGS" >/dev/null && echo "  [ok] settings.json valid after merge"

echo ""
echo "Done. New sessions pick the config up automatically; in a running session"
echo "check /hooks and /statusline. Verify the install with: ./verify.sh --live"
