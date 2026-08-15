# Setup — first contact and testing

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [capture](glossary.md#capture) · [checks](glossary.md#checks) · [envelope](glossary.md#envelope) · [adapter](glossary.md#adapter) · [backend](glossary.md#backend) · [sidecar](glossary.md#sidecar) · [tags](glossary.md#tags) · [deps](glossary.md#deps)

## Prerequisites

git · Elixir 1.14+ · jq 1.6+ · the `claude` CLI, logged in (inference
backend #1). Verify all four before anything else:

```
elixir --version && jq --version && claude --version
```

## What actually runs when you capture

```
elixir tools/ask.exs <slug> "<your question>"
```

makes exactly **two inference calls, both through the CLI harness in
print mode** — command-line calls to a harnessed agent, not raw HTTP API
calls; this repo contains no API client:

1. **respondent** — your question, at your CLI's default model
   (`ASK_MODEL` overrides), no tools enabled;
2. **classifier** — a second, cheap call (the adapter defaults it to the
   backend's cheap tier; `ASK_CLASSIFY_MODEL` overrides) that proposes
   `tags:` and `deps:` as JSON, which the tool validates before writing.

Everything else is deterministic Elixir + jq. The backend is a swappable
seam — see [backend-contract.md](backend-contract.md), including the
recipe for integrating a different vendor CLI.

## First contact

The full operating protocol — cycles, branches, merges, derivation — is
[workflow.md](workflow.md); this is the walk-through.

1. **Clone and verify**: `git clone <repo> && cd <repo>` — then
   `elixir tools/check_all.exs; echo $?`. Expect **no output, exit 0**
   (a few seconds; several Elixir processes run, including the view
   regeneration sandbox). Any printed path means a broken clone.
2. **Arm the hook** (once per clone): `git config core.hooksPath
   tools/hooks`. No output.
3. **Open a cycle**: `git checkout -b cycle/YYYY-MM-DD-<name>` — the
   cycle is named before its work exists, the same declaration of
   intent as naming an exchange.
4. **Capture**: run the `ask.exs` command above. Expect 10–40 seconds
   (two model calls), then: the exchange and sidecar paths, a
   `tags | deps` summary line, the answer's cost, and a review
   reminder.
5. **Audit** — open the exchange file and check, in order: envelope
   fields populated (session, UTC date, model, cost, cwd; blank only
   where the backend reported nothing); your prompt **verbatim**; the
   answer **verbatim**; Side Effects carries the harness digest, the
   classifier note, and the retriever coverage line. Tags silly? Edit
   the `tags:` line by hand — pre-commit, that is the audit working.
   Side Effects flags a **NEW** tag you accept? `mkdir -p
   taxonomy/<path>` and commit the empty leaf's index at the next
   derivation.
6. **Commit to the branch**: `git add exchanges && git commit`. The
   hook runs the record checks; silence, then the commit lands. Repeat
   4–6 per exchange for the rest of the cycle.
7. **Close the cycle**: push the branch, open a PR, let the required
   record checks pass, then **squash-merge with a hand-written message
   describing the cycle** — the merge is the ratification. The
   derivation job then regenerates the views on `main` and commits
   them itself.

## Failure behavior, so nothing surprises

- Backend errors (auth, network) → `nothing filed`, exit 1, no file.
- Classifier garbage → the file lands with `tags: UNCLASSIFIED` and a
  Side Effects instruction to set it by hand; capture never blocks on
  classification.
- Same slug, same day → `refusing to overwrite … exchanges are
  immutable`.
- Hand-edited derived view at commit → the hook prints the diff and
  refuses; run the deriver instead.

## Testing without spending inference — the stub tier

The shipped fixtures pin real backend envelope shapes, so the whole
pipeline runs with zero model calls:

```
ASK_STUB=tools/stub-fixtures/answer-1.json \
ASK_STUB_CLASSIFY=tools/stub-fixtures/classify-1.json \
elixir tools/ask.exs stub-test "any question"
```

Expect a complete exchange + sidecar, canned content, real machinery
(validation, digest, sidecar assembly). `classify-2.json` exercises
the ugly paths: a fenced reply, a NEW tag, and an invalid dep that gets
dropped with a note. **Stub runs write real files into the ledger** —
test in a scratch clone, or delete the generated exchange + sidecar
before committing anything.

## Testing the live classifier cheaply — the mixed tier

The classifier is the one judgment component; test it live without
paying for a live answer by stubbing call 1 only:

```
ASK_STUB=tools/stub-fixtures/answer-1.json \
elixir tools/ask.exs classifier-test "any question"
```

Call 2 goes live at the cheap tier (fractions of a cent). Audit what it
proposed: are the tags drawn sensibly from the taxonomy? Are the deps
real continuations, given what the shown-list says it was shown? Repeat
with different fixtures and `ASK_CLASSIFY_MODEL` values to compare
tiers. Same ledger-pollution caveat: scratch clone, or clean up.

## Knobs

`ASK_MODEL` (answer call) · `ASK_CLASSIFY_MODEL` (classifier call) ·
`ASK_K` (retriever top-k, default 4) · `ASK_STUB` /
`ASK_STUB_CLASSIFY` (fixture envelopes instead of live calls).
