# Methods — the gradient, distilled into practice

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [nursery rule](glossary.md#nursery-rule) · [generator](glossary.md#generator) · [verifier](glossary.md#verifier) · [supersession](glossary.md#supersession) · [property loop](glossary.md#property-loop) · [promotion](glossary.md#promotion) · [residue](glossary.md#residue)

The spec gradient's working claim: when interiors are generated and
regenerable, the judgment layer — intent, invariants, contracts,
acceptance — is the load-bearing part, and interior code is cattle. The
methods below are that claim as daily practice.

## 1 · The inner loop: write first, diff second

For any governing artifact: write your version cold, arm what can be
armed (run it, break it once on purpose), then diff — yourself first,
then via a one-shot review exchange. Record what you missed and what the
reviewed source missed. Where you disagree with a prior spec after a
diff, supersede it, dated, with reasons.

## 2 · The nursery flow

Ask through the capture tool → the record lands in the ledger → if the
response contains something that should govern or run, the operator
promotes it (to `docs/` or `tools/`) with a provenance link back — the
promotion commit is the ratification. Nothing enters force unread.

## 3 · Generation inside the cage

Interiors are generated, not hand-polished: a `generator` exchange gets
the contract and the acceptance test, returns one fenced block; a tool
installs it; the property loop and checks judge it. If the itch is to
hand-edit a generated interior — stop: the missing decision belongs in
the contract or the register; write it there and regenerate. Two
independently generated interiors passing the same acceptance unchanged
is the proof the contract carries the weight.

## 4 · The review protocol

Reviews are one-shot exchanges, persisted, `deps:` pointing at what they
reviewed. Shape every prompt for refutation, never affirmation:

- **Restate** — "restate what this is for; name ambiguities; do not improve."
- **Counterexample** — "construct a state satisfying every rule as
  written that is still obviously wrong; name the unstated assumption."
- **Gap** — "using only this document, do the task; write GUESS: wherever
  you are forced to guess; list every guess."
- **Entitlement** — "for each side effect in this record: within
  entitlement, exceeded, or unclear — and why."

Never ask "is this good?" — a plausibility engine answers yes. Reviews
return findings; they never edit. The reviewing exchange's own record is
the review trail.

## 5 · The change ceremony

A change that contradicts a register entry runs, in order: supersede the
invariant (INV-n → INV-n′, both kept, dated) → ripple the contracts →
ripple the acceptance (operator does this; `test/` is operator-only) →
regenerate the affected interior. History constrains specs: records that
legally predate a rule get a dated scope clause in the register, never a
special case in a script.

## 6 · Triage

When something breaks: five lines in a dated doc — what failed · which
layer (acceptance thin / contract uncovered / invariant wrong / intent
wrong / residue) · at which layer the fix entered.

## 7 · Standing cadence

Weekly, one review exchange over the week's ledger: entitlement audit of
side effects, register↔checks sync, marker integrity, and the intent
doc's debt counter re-taken. Plus `check_all` on a fresh clone.

## 8 · Residue

What no layer can hold — scope selection, taste, the judgment of what to
ask — has a named owner: the operator, knowingly. Current known residue:
INV-2's committed-immutability check and INV-4's provenance-link check
are unarmed halves; the no-agent-commits rule is contract, not mechanism.
Each is either armed eventually or stays here, owned.
