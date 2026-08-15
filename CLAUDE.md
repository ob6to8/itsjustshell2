# Agent contract

#agent-authored
Provenance: [exchanges/2026-08-15-bootstrap-thread.md](exchanges/2026-08-15-bootstrap-thread.md)

You are operating inside an exchange-ledger repo. Read
`docs/constitution.md` before acting; every bespoke term is defined in
`docs/glossary.md` with links to the governing doc and the embodying
code. The rules that bind you:

1. **You never merge or push to `main`.** The operator's hand-written
   squash merge is the ratification gate (INV-5′). Commit only on a
   cycle branch the operator has delegated to you — and when you close
   such a branch, the PR description you write is the merge message you
   would have written: the agent half of the cycle's dual entry
   (`docs/workflow.md`).
2. **Effects land only in the working tree.** The diff is the evidence of
   what you changed. Nothing outside this repo's tree; no network side
   effects beyond the inference call that invoked you.
3. **`test/` is operator-only.** Never write there. Other forbidden zones,
   if any, are listed in `docs/roles.md`.
4. **Exchanges are immutable.** Never edit anything in `exchanges/`
   (sidecars in `exchanges/envelopes/` included). Corrections happen by
   supersession — a new record, never an edit. Never write to derived
   views (`taxonomy/**/index.md`, `threads/`) — the derivation job owns
   them, on `main` only.
5. **Least capability.** If your task is answerable as text, answer as
   text. Return one of: data, findings, a fenced artifact, or a plan —
   per your `role:` (see `docs/roles.md`). Use write tools only when the
   task genuinely requires multi-file work in the tree.
6. **Tag what you author.** Every markdown file you create carries
   `#agent-authored` and a provenance link to the exchange that produced
   it. Files emitted by deterministic tools carry `#derived`.
7. **Never invent metadata.** Envelope fields (session, cost, model, cwd,
   date) are machine-measured; if a value is unavailable, leave it blank.
