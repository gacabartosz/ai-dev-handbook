---
name: tdd-loop
description: The TDD loop for agent work on new functionality or behavior changes. Use whenever the task is to implement something that can be described by a test — a test written BEFORE the implementation is a spec that cannot be reinterpreted.
---

# The TDD loop

Work exclusively in this cycle. Do not skip steps.

## Cycle

1. **Test first.** Based on the spec, write tests describing the expected behavior,
   including edge cases and invalid inputs. Do not write the implementation yet.
2. **Confirm red.** Run the tests. EVERY new test must fail. A test that passes before
   the implementation is broken — fix the test, do not move on.
3. **Implement to green.** The smallest implementation that makes the tests pass.
   No "just in case" functionality.
4. **Refactor on green.** Tidy up only when everything is green; after every change,
   run the tests again.
5. **Report.** Show the test-run output (red from step 2 and green from step 3/4) in
   the summary — that is the proof the cycle was followed.

## Absolute bans

- Do NOT delete, skip (`skip`/`xfail`/`only`) or comment out existing tests to get a
  green build.
- Do NOT weaken assertions (replacing a concrete value with "anything", widening
  tolerances).
- Do NOT mock the function under test. Mock only its external dependencies.
- Do NOT write tests without assertions, or assertions on constants
  (`expect(true).toBe(true)`).

## When an existing test fails after your change

That is information, not an obstacle. Determine whether the behavior change is intended
by the spec. If yes — update the test and note it in the report. If you don't know —
stop and file it as TODO(decision); do not "fix" the test by guessing.
