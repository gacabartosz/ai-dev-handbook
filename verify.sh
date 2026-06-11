#!/bin/bash
# AI Dev Handbook — self-test. Verifies that every component of this repo
# actually works: static checks + functional tests on sample inputs.
#
#   ./verify.sh          static + functional checks (no API calls, <1s)
#   ./verify.sh --live   additionally verifies in a real headless Claude Code
#                        session that the skills are discoverable (costs ~1 cent)

set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  [pass] $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }
check(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== Static checks =="
check "bash syntax: statusline.sh"            "bash -n configs/statusline.sh"
check "bash syntax: block-git-merge.sh"       "bash -n configs/hooks/block-git-merge.sh"
check "bash syntax: session-summary.sh"       "bash -n configs/hooks/session-summary.sh"
check "bash syntax: install.sh"               "bash -n install.sh"
check "valid JSON: settings.example.json"     "jq . configs/settings.example.json"
check "jq available"                          "command -v jq"

echo "== Skills format =="
for d in configs/skills/*/; do
  s=$(basename "$d")
  name=$(awk -F': ' '/^name:/{print $2; exit}' "$d/SKILL.md")
  [ "$name" = "$s" ] && ok "skill $s: frontmatter name matches directory" \
                     || bad "skill $s: name '$name' != directory"
  grep -q '^description:' "$d/SKILL.md" && ok "skill $s: has description" \
                                        || bad "skill $s: missing description"
done

echo "== Agents format =="
for f in configs/agents/*.md; do
  a=$(basename "$f" .md)
  grep -q '^name:' "$f" && grep -q '^description:' "$f" && grep -q '^model:' "$f" \
    && ok "agent $a: frontmatter complete (name/description/model)" \
    || bad "agent $a: incomplete frontmatter"
done

echo "== Functional: block-git-merge hook =="
run_hook(){ echo "{\"tool_input\":{\"command\":\"$1\"}}" | bash configs/hooks/block-git-merge.sh >/dev/null 2>&1; echo $?; }
[ "$(run_hook 'git merge feature-x')" = "2" ]              && ok "blocks: git merge"            || bad "should block: git merge"
[ "$(run_hook 'gh pr merge 42 --squash')" = "2" ]          && ok "blocks: gh pr merge"          || bad "should block: gh pr merge"
[ "$(run_hook 'cd x && git push origin main')" = "2" ]     && ok "blocks: git push to main"     || bad "should block: push to main"
[ "$(run_hook 'git push --force origin feat')" = "2" ]     && ok "blocks: git push --force"     || bad "should block: push --force"
[ "$(run_hook 'git commit -m test')" = "0" ]               && ok "passes: git commit"           || bad "should pass: git commit"
[ "$(run_hook 'git push origin feature-branch')" = "0" ]   && ok "passes: push to feature"      || bad "should pass: push to feature"

echo "== Functional: statusline =="
out=$(echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":42}}' | bash configs/statusline.sh)
echo "$out" | grep -q "ctx 42%" && ok "reads context_window.used_percentage" || bad "context % from stdin field"
t=$(mktemp); echo '{"message":{"usage":{"input_tokens":5000,"cache_read_input_tokens":95000}}}' > "$t"
out=$(echo "{\"model\":{\"display_name\":\"O\"},\"workspace\":{\"current_dir\":\"/tmp\"},\"transcript_path\":\"$t\"}" | bash configs/statusline.sh); rm -f "$t"
echo "$out" | grep -q "ctx 50%" && ok "transcript fallback (100k/200k = 50%)" || bad "transcript fallback"

echo "== Docs links =="
missing=$(grep -oh 'configs/[a-zA-Z0-9_/.-]*' GUIDELINES.md README.md | sed 's/[).,]*$//' | sort -u | while read -r f; do [ -e "$f" ] || echo "$f"; done)
[ -z "$missing" ] && ok "all configs/ links in docs resolve" || bad "missing link targets: $missing"

if [ "${1:-}" = "--live" ]; then
  echo "== Live: skill discovery in a fresh Claude Code session =="
  if command -v claude >/dev/null; then
    answer=$(cd /tmp && claude -p --model haiku "Check your available skills list. For each of these three names answer exactly 'NAME: AVAILABLE' or 'NAME: NOT AVAILABLE' (one per line, nothing else): tdd-loop, debug-protocol, secure-by-default. Do not invoke any skill or tool." 2>/dev/null)
    for s in tdd-loop debug-protocol secure-by-default; do
      echo "$answer" | grep -q "$s: AVAILABLE" && ok "live: skill $s discovered" || bad "live: skill $s NOT discovered (run ./install.sh first)"
    done
  else
    bad "claude CLI not found — cannot run live check"
  fi
fi

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ]
