# Tripwires — pre-committed triggers for deferred decisions

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [tripwire](glossary.md#tripwire) · [adapter](glossary.md#adapter) · [executor](glossary.md#executor) · [no silent caps](glossary.md#no-silent-caps) · [schema](glossary.md#schema)

Each entry: the decision deferred, the trigger that un-defers it, and the
response. The weekly review checks whether any tripwire has fired.
Firing a tripwire is not failure — it is the plan working.

**T1 — Harness divorce (backend #1).**
Deferred: replacing `claude -p` with a raw-API adapter.
Trigger, any of: (a) measured contamination — the same prompts through
`-p` and a raw call diverge in ways that matter (this is an eval: run it
before believing it); (b) CLI shape-drift breaks the harvest;
(c) replay/eval work needs a deterministic system prompt.
Response: write one new adapter honoring
[backend-contract.md](backend-contract.md) — in its own
`tools/backend-*` file — and at that moment arm the vendor-isolation
rule: a check that vendor names appear nowhere outside `tools/backend-*`
and the prerequisites list. Never a rewrite of tools or doctrine.

**T2 — Capability escalation.**
Deferred: any agent capability beyond read/write in this repo's working
tree.
Trigger: a task that genuinely needs network, system state, or writes
outside the tree.
Response: explicit per-task operator grant, recorded in the invoking
exchange; the sidecar carries the full tool log; the entitlement review
(methods §4) covers it.

**T3 — Silent caps.**
Deferred: nothing — this one is standing.
Trigger: any tool bounding coverage (top-k, truncation, sampling, stub
tiers at scale) without recording the bound where the result lands.
Response: fix the tool before trusting its output again.

**T4 — Language and dependency floor.**
Deferred: nothing — Elixir is the single tool language.
Trigger: an environment where commits happen but the BEAM is absent.
Response: provision the environment (setup script / CI step). Never an
ad-hoc shell rewrite of a tool; the `sh` shim in `tools/hooks/` is a
doorway, not an implementation.

**T5 — Schema drift.**
Trigger: a frontmatter key appearing in ledger files that
[exchange-schema.md](exchange-schema.md) does not define — assume the
schema will be drifted from, and treat any undeclared key as this
tripwire firing.
Response: ratify the key into the schema or strip it — by supersession,
in the same week it is noticed.

**T6 — Tool fission.**
Trigger: a tool that no longer fits on one screen (~100 lines) or does
more than one job.
Response: split it, or write one sentence in the tool's header justifying
why not. (`tools/ask.exs` ships over this line at birth, justified in its
header: capture is one job with one seam — backend — and splitting the
pipeline would put the schema's single writer in two places.)

**T7 — Executor escalation.**
Trigger: a recurring task class where the fenced-return mode forces
contortions (multi-file changes, refactors).
Response: invoke the `executor` role (already seated, see
[roles.md](roles.md)) — do not widen the generator.
