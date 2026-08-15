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
`tools/check_views.exs` (the views half — regenerate and diff, at every
commit); operator discipline + git history for committed-record
immutability (a diff-against-HEAD check is a known upgrade, see residue
in [methods.md](methods.md)).

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

**INV-5**: Every commit must be operator-made and pass `check_all`. No
agent commits, ever. Origin: the bootstrap exchange — the commit is the
ratification gate. Breaks: ratification evaporates; generated content
enters force unread. Armed by: `tools/hooks/pre-commit` (the check half);
the no-agent-commits half is contract (`CLAUDE.md`) — mechanizing it is
in the residue.
