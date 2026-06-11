---
name: secure-by-default
description: A minimal security checklist applied when writing and reviewing code that touches user input, authorization, secrets, cryptography or database queries. Use automatically on every such change — this is the minimum that is not negotiable.
---

# Secure by default — checklist

Apply when writing code and during review. Every deviation requires an explicit human
decision (TODO(decision) + ticket), not your own judgment that "it doesn't hurt here".

## Input and queries

- Every database query: parameterized / via a query builder. NEVER string concatenation
  with input data (SQL injection).
- Validate input at the system boundary (handler/endpoint), not deep inside. A schema
  (type, range, format) instead of hand-written ifs.
- Output to HTML/shell/file paths always via escaping or an API that escapes
  (XSS, command injection, path traversal). NEVER `eval` / dynamic execution on
  external data.

## Secrets and configuration

- Secrets exclusively from environment variables / a secret manager. NEVER in code,
  tests, fixtures, logs or error messages.
- Before committing, check the diff for keys/tokens/passwords — including sample ones
  that "look real".

## Auth and data

- Check authorization on the server for EVERY operation, not only on entering a view.
  A resource ID from the request ≠ a right to the resource (IDOR).
- Error messages for users stay generic; details (stack traces, queries) go to logs only.
- Cryptography: standard libraries and current algorithms only. Passwords via
  bcrypt/argon2, no home-grown hashing.

## Dependencies and agents

- New dependencies: only from the lockfile; check the package is maintained and the name
  isn't typosquatting.
- Code running an AI agent on user-generated content (UGC): sandbox + tool allowlist +
  input filtering. Treat prompt injection in UGC like remote code execution.

## Escalation

A suspected vulnerability found in existing code outside the task's scope:
do NOT fix it quietly — file a separate ticket with the attack vector and a priority.
