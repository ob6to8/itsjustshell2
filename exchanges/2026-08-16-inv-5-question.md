---
session_id: be9c8aa0-adfd-4150-8599-71e69d0dd679
date: 2026-08-16T07:51:16Z
model: claude-sonnet-5
cost_usd: 0.2761164
cwd: /Users/mark/dev/repos/itsjustshell2
role: respondent
tags: methodology
deps: exchanges/2026-08-15-bootstrap-thread.md, exchanges/2026-08-16-workflow-human-authored-review.md
---

## Prompt
#human-authored

in invariants.md, there is the following: **INV-5** *(superseded 2026-08-15 → INV-5′)*: Every commit must be
operator-made and pass . No agent commits, ever. Origin: the
bootstrap exchange — the commit is the ratification gate. Breaks:
ratification evaporates; generated content enters force unread.

**INV-5′**:  has exactly two writers: the operator's merge of a
checked cycle, and the derivation job committing  paths only.
Agents never merge and never push to ; a cycle branch may carry
agent commits when the operator has delegated that cycle. The
ratification gate is the operator's hand-written squash merge. Origin:
supersedes INV-5 for the cycle workflow ([workflow.md](workflow.md)) —
the gate moved from commit to merge; a deterministic deriver is
machinery, not an agent. Breaks: ratification evaporates, or invented
views enter  unverified. Armed by: check_authorship: missing or multiple markers: docs/workflow.md
check_records: FAILED: tools/check_authorship.exs
(record checks at every commit) + the PR-required record check + the
derivation job's own path guard + the  ruleset (PR-only merges,
 required, the derivation job's deploy key the sole bypass —
[workflow.md](workflow.md)). The never-merge half stays contract,
noted in the residue. /end quote. The issue here as I see it is keeping a copy of the superceeded INV-5, and referencing the history of the supersession, is unecessary when this is already recorded in the git history. I see this as a violation of DRY, and that invariants.md should only record the active definitions with no reference to history. do you agree? do not make any changes, only levy judgment. if you agree this should be removed, would doing so break anything? if yes, how ta oddress? within your response, include recommended next steps --model claude-fable-5

## Response
#agent-authored

I disagree with the framing. Here's the judgment, and why.

**This isn't a DRY violation — it's the documented design.** `docs/invariants.md` states its own discipline right at the top: "Register discipline: append-and-supersede, dated (INV-n → INV-n′, both kept); silent edits forbidden." That's not incidental — it's confirmed as one of exactly three mutability regimes in `docs/constitution.md` §6: "Edit-in-place with dated supersession: docs. Invariants in particular... silent edits are forbidden." The glossary's `supersession` entry says the same thing a third time: "a new dated entry (INV-n → INV-n′, both kept), never a silent edit."

So removing the superseded INV-5 text wouldn't be tidying up duplication — it would be a silent edit to the one artifact the constitution explicitly protects from silent edits. Three separate governing docs converge on "both kept" as a rule, not a side effect.

**Why this doesn't collapse into "git history already has it":** the constitution draws a real distinction between what git remembers and what the document asserts. Git tells you *that* something changed and roughly when; it doesn't tell a reader auditing current INV-5′ *why* the ratification gate moved from commit-time to merge-time, or what the prior invariant actually claimed, without spelunking blame/log. The kept-superseded entry is doing the same job the exchange ledger does elsewhere in this repo: making the reasoning behind a state transition part of the artifact itself, not something you have to reconstruct from plumbing. This mirrors CLAUDE.md rule 4 ("Exchanges are immutable... corrections happen by supersession — a new record, never an edit") — the same philosophy applied one level up, to docs instead of records.

**Would removing it break anything mechanically?** No automated check enforces this — I checked `tools/*.exs` and found nothing that inspects `invariants.md` content (the checks that exist target exchanges, deps, views, authorship markers). So nothing in CI would fail. The breakage is contractual/philosophical, not mechanical: it would violate the constitution's own stated mutability regime for docs, and it would quietly discard the "why" that INV-5′'s "Origin:" line depends on for context (INV-5′ literally reads "supersedes INV-5 for the cycle workflow" — that sentence is only meaningful if INV-5's text is still there to point at).

**Recommended next steps, if you still want to act on the DRY instinct:**
1. Don't delete INV-5 — if the register entry feels too heavy, that's a formatting complaint, not a content one. Consider collapsing the superseded entry's body to a one-line pointer plus a link to the exchange/PR where it was superseded, while keeping the "both kept" invariant intact (i.e., compress, don't remove).
2. If you think the "both kept, silent edits forbidden" rule itself is wrong for this repo, that's a constitution-level change, not an invariants.md edit — it'd require going through `docs/constitution.md` §6 and `docs/glossary.md`'s `supersession` entry, and probably its own exchange, since it's a normative reversal of a rule that's stated in three places.
3. Either way, this is a "docs" mutability-regime question, which per CLAUDE.md rule 1 you'd want routed through the operator's own judgment rather than an agent edit — I haven't made any changes, per your instruction.

## Side Effects
#derived

created persistent record (this document)
harness digest: num_turns=12, tools=Bash, Bash, Read, Bash, Bash, Bash, Read, Read, Bash, Read, Bash, permission_denials=0
tags and deps machine-proposed (classifier model: claude-haiku-4-5-20251001, cost_usd: 0.0438361) — reason: Defends the supersession discipline as documented design, responding to the workflow review's question about documentation duplication while extending system design principles from the bootstrap exchange.
retriever: full text shown for 3 of 3 candidates (shown_list in sidecar)
