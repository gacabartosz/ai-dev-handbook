---
name: debug-protocol
description: Bug-debugging protocol — reproduction before hypothesis, hypothesis before change, proof after the change. Use on every bug report, regression or "works on my machine", before touching any code.
---

# Debugging protocol

The order is mandatory. A fix reported without passing steps 1 and 5 is invalid.

## Steps

1. **Reproduce.** Reproduce the bug locally — ideally directly as a failing automated
   test (it becomes the regression test in step 5). If you can't reproduce: collect the
   missing information (logs, versions, input data) and report what's missing.
   Do NOT change code "blind" without a reproduction.
2. **Narrow down.** Locate the cause: logs, a minimal case, `git bisect`, disabling
   suspects one at a time. Record what you've already ruled out — don't revisit
   eliminated paths.
3. **Hypothesis and confirmation.** Form one concrete hypothesis ("the bug originates
   in X because Y") and CONFIRM it with an observation (a log, a debugger, a unit test
   of the fragment) before fixing anything. Unconfirmed hypothesis = back to step 2.
4. **Fix the cause.** Fix the source, not the symptom. Red flags that you're treating
   a symptom: adding `if`/`try` around the blast site instead of where the bad data is
   created; adding `sleep`/retry for a race; widening a type to "make it pass".
5. **Proof and regression.** Run the reproduction from step 1 — it must pass. The
   regression test stays in the repo permanently. Run the full test suite: the fix must
   not break anything else.

## Final report (mandatory format)

- **Symptom:** what the user saw.
- **Cause:** the mechanism of the bug (confirmed, not presumed).
- **Fix:** what changed and where, and why it cures the cause.
- **Proof:** reproduction output before (red) and after (green) + full test suite.
- **Regression:** path of the new regression test.
