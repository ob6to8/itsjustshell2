# itsjustshell2

#agent-authored
Provenance: [exchanges/2026-08-15-bootstrap-thread.md](exchanges/2026-08-15-bootstrap-thread.md)

An exchange-ledger development system. Every operator↔agent interaction is
a one-shot call whose record — prompt, response, provenance — is filed as
an immutable, dated **exchange**. Governing decisions live in ratified
**docs**. Deterministic **tools** do everything mechanical: capture,
validation, derivation. Agents propose and author; the operator ratifies;
the commit is the ratification gate, and it is always the operator's.

The bootstrap was agent-authored in one pass, traceable end to end to
the init exchange linked above. The constitution — what everything is —
is [docs/constitution.md](docs/constitution.md).

## Layout

    docs/        the governing layer: constitution, intent, invariants,
                 roles, schema, backend contract, methods, tripwires,
                 setup (first contact, testing tiers, the inference path),
                 glossary (every bespoke term, linked to docs and code)
    exchanges/   the ledger: immutable exchange records, flat, dated
      envelopes/ per-exchange sidecars: the harness's raw JSON, kept forever
    taxonomy/    vocabulary only — the tag tree; leaf index.md files are
                 derived views, never content
    threads/     derived views over deps edges (created by the deriver)
    tools/       deterministic machinery: capture pipeline, checks,
                 derivers, hook shim, stub fixtures
    test/        acceptance: the property loop. Operator-only zone.

## Prerequisites

git · Elixir (1.14+; 1.18+ recommended) · jq (1.6+) · the `claude` CLI
(backend #1 — swappable, see [docs/backend-contract.md](docs/backend-contract.md))

## The loop

    elixir tools/ask.exs <slug> "<your question>"

One command in: the exchange file and its sidecar land in the ledger,
metadata harvested and proposed, derived views refreshed. You read the
file — the read is the audit — fix judgment fields if needed, and
commit with `git add -A`. Checks run at commit via the pre-commit hook
(`git config core.hooksPath tools/hooks`, once). Step-by-step first
contact, expected outputs, and how to test the pipeline with and
without live inference: [docs/setup.md](docs/setup.md).

Unfamiliar term anywhere in this repo? It's defined in
[docs/glossary.md](docs/glossary.md), linked to the doc that specifies
it and the code that embodies it.
