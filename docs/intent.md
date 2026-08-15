# Intent

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [capture](glossary.md#capture) · [checks](glossary.md#checks) · [property loop](glossary.md#property-loop) · [tags](glossary.md#tags) · [exit criterion](glossary.md#exit-criterion)

## Purpose

Kill persistence debt. Interacting with agents through ephemeral one-shot
calls, with every interaction filed as an immutable record *named before
the answer exists*, forces intent to be declared at the moment of
communication — instead of threads spinning into directions no one can
persist, and abandoning. The repo is simultaneously the record system and
the enforcement system: it polices its own files.

## Vehicle

- `tools/ask.exs` — the capture pipeline: one command in, one
  schema-complete exchange + sidecar out.
- `tools/check_authorship.exs`, `check_exchanges.exs`, `check_deps.exs`
  (record checks, run at every commit and on every PR),
  `check_views.exs` (derived views equal their regeneration — holds on
  `main`, where the derivation job refreshes them after each merge),
  `check_records.exs` / `check_all.exs` — the runners.
- `tools/derive_threads.exs`, `derive_indexes.exs` — the views.

## Scenarios

1. Healthy repo → every check exits `0`, silently.
2. An exchange's `deps:` names a missing file → the path is printed,
   exit `1`, the commit is refused.
3. A markdown file lacks its authorship marker, or an exchange is
   schema-incomplete → the path is printed, exit `1`, the commit is
   refused.
4. The operator asks a question via `ask.exs` → the exchange lands named,
   harvested, tagged (proposed), dep-linked (proposed), sidecar kept; the
   operator reads, corrects if needed, commits.

## Anti-goals

- No YAML parser dependency: frontmatter stays flat `key: value` lines,
  parseable by line discipline.
- No network beyond the inference call itself.
- No agent framework: tools are standalone; `ls tools/` is the registry.
- No summarization that replaces records: views link, never copy.
- No speculative structure: taxonomy grows by use, tools split when a
  tripwire fires, not before.

## Exit criterion for bootstrap threads

This class of long-lived agent thread retires when any change can travel
as **persisted exchanges + deterministic tool runs + operator commits**,
with the checks green at commit time. Until then, each bootstrap thread
names what still cannot travel through the loop. The standing audit may
ask of any change: did this need a thread?

## Debt counter

"Must"/"every"/"all" sentences in this docs set are promissory notes.
Current count is taken and re-checked by the weekly review (see
[methods.md](methods.md)); each is either armed by a check or listed in
the residue.
