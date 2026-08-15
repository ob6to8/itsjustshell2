# Invariants — the register

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [register](glossary.md#register) · [schema](glossary.md#schema) · [deps](glossary.md#deps) · [authorship markers](glossary.md#authorship-markers) · [supersession](glossary.md#supersession) · [operator](glossary.md#operator)

Entry shape: `INV-n: Every ___ must ___. Origin: ___. Breaks if violated:
___. Armed by: ___.` Register discipline: append-and-supersede, dated
(INV-n → INV-n′, both kept); silent edits forbidden. Hard cap: five live
entries — selection under the cap is the exercise.

---

**INV-1**: Every exchange file must be schema-complete: frontmatter fence
at byte zero, all nine keys present, the three sections in order, each
under its marker. Origin: the bootstrap exchange — records must work as
evidence. Breaks: the ledger degrades into notes; audits have nothing
stable to hold. Armed by: `tools/check_exchanges.exs`.

**INV-2**: Every record under `exchanges/` must be immutable once
committed, and every `#derived` view must equal its regeneration from
the ledger. Origin: the bootstrap exchange — what-is-known derives from
what happened, never the reverse. Breaks: the ledger loses time-truth;
views become invented history. Armed by:
`tools/check_views.exs` (the views half — regenerate and diff; cycle
branches deliberately carry stale views, and the derivation job
refreshes `main` after every merge, where this check holds); operator
discipline + git history for committed-record immutability (a
diff-against-HEAD check is a known upgrade, see residue in
[methods.md](methods.md)).

**INV-3**: Every path in an exchange's `deps:` must resolve to an
existing file under `exchanges/`. Origin: capture design — models
hallucinate plausible paths; existence is machine-checkable. Breaks:
threads derive garbage; lineage becomes fiction. Armed by:
`tools/check_deps.exs` (and at write time by `tools/ask.exs`).

**INV-4**: Every markdown file outside `exchanges/` must carry exactly
one authorship marker (`#human-authored` | `#agent-authored` |
`#derived`), and every `#agent-authored` file must carry a provenance
link. Origin: the bootstrap exchange — provenance must stay
distinguishable from assertion. Breaks:
provenance becomes indistinguishable from assertion. Armed by:
`tools/check_authorship.exs` (marker presence; the provenance-link half
is a recorded gap until the check grows it).

**INV-5** *(superseded 2026-08-15 → INV-5′)*: Every commit must be
operator-made and pass `check_all`. No agent commits, ever. Origin: the
bootstrap exchange — the commit is the ratification gate. Breaks:
ratification evaporates; generated content enters force unread.

**INV-5′**: `main` has exactly two writers: the operator's merge of a
checked cycle, and the derivation job committing `#derived` paths only.
Agents never merge and never push to `main`; a cycle branch may carry
agent commits when the operator has delegated that cycle. The
ratification gate is the operator's hand-written squash merge. Origin:
supersedes INV-5 for the cycle workflow ([workflow.md](workflow.md)) —
the gate moved from commit to merge; a deterministic deriver is
machinery, not an agent. Breaks: ratification evaporates, or invented
views enter `main` unverified. Armed by: `tools/hooks/pre-commit`
(record checks at every commit) + the PR-required record check + the
derivation job's own path guard; the branch-protection half lives in
repository settings (operator console) — until enabled it is contract,
noted in the residue.
