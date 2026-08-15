# Glossary

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)

Every bespoke term in this repo, defined once, with links to where the
concept is specified (docs) and where it is embodied (code). Alphabetical.
Anchor convention: each term is a heading, so
`glossary.md#<term-with-dashes>` links resolve; the other docs carry a
"terms used here" line pointing back into this file.

## adapter

The one code seam allowed to know a vendor's name. Takes `(prompt, opts)`,
invokes its inference backend with no tools enabled, saves the raw
[envelope](#envelope) verbatim, and returns the normalized fields (text,
session id, model, cost, cwd — blank when unreported, never invented).
Where: [backend-contract.md](backend-contract.md) · code:
[../tools/ask.exs](../tools/ask.exs), module `IJS.Backend` (`claude_p/2`
is adapter #1, `stub/1` is the fixture adapter).

## audit

The operator reading a record before committing it — the human half of
verification. Distinct from [checks](#checks) (mechanical) and from the
[verifier](#verifier) role (a later review exchange). Anomalies are
surfaced *into the file being audited* (Side Effects notes) so the read
catches them.
Where: [roles.md](roles.md) · [exchange-schema.md](exchange-schema.md).

## authorship markers

Every markdown file (outside `exchanges/`) carries exactly one of
`#human-authored` (operator wrote it), `#agent-authored` (a model wrote
it; a provenance link to its birth exchange is required), `#derived` (a
deterministic tool emitted it; regenerate, never edit). Exchange files
are composite: their sections carry the markers.
Where: [constitution.md](constitution.md) §5 · enforced by
[../tools/check_authorship.exs](../tools/check_authorship.exs) and
[../tools/check_exchanges.exs](../tools/check_exchanges.exs).

## backend

The inference service behind an [adapter](#adapter) — `claude -p` today,
anything tomorrow. Doctrine and tools never name one outside adapters, so
swapping vendors is one new adapter, not a rewrite. The stub backend
(canned envelopes from `ASK_STUB` / `ASK_STUB_CLASSIFY`) is a first-class
citizen: it is how the pipeline is tested without inference.
Where: [backend-contract.md](backend-contract.md) · code:
[../tools/ask.exs](../tools/ask.exs) module `IJS.Backend` · fixtures:
[../tools/stub-fixtures/](../tools/stub-fixtures/).

## bootstrap exception

The one record not born through the one-shot loop:
[../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
(`role: bootstrap`), the multi-turn thread that created this repo,
transcribed verbatim. Its role-keyed schema deviations (Prompt marker,
navigation apparatus) are declared in
[exchange-schema.md](exchange-schema.md) and never repeated.

## capability dial

The rule that an agent gets the minimum capability its task needs, low to
high: pure function (no tools) → [fenced return](#fenced-return) →
workspace [executor](#executor) (write tools in the tree). Audit cost
scales with the dial; verification (checks + operator commit) is
identical at every setting. Binding invariants: no agent ever commits;
effects land only in a git working tree; forbidden zones enforced at
commit; every run persists its [sidecar](#sidecar).
Where: [roles.md](roles.md) · agent-facing contract:
[../CLAUDE.md](../CLAUDE.md).

## capture

The whole path from one operator command to one committed-ready record:
ask → envelope harvest → [retriever](#retriever) → [classifier](#classifier)
proposal → validation → exchange + sidecar written → operator audit →
commit on the open [cycle](#cycle) branch.
Where: [intent.md](intent.md) · code: [../tools/ask.exs](../tools/ask.exs)
(entry: `IJS.Ask.main/1`).

## checks

The armed invariants — deterministic scripts that exit `0` silently on a
healthy repo and print the offending path with exit `1` otherwise. The
pre-commit hook and the PR-required CI run the record checks
(`check_records`: authorship, exchanges, deps); `check_views` guards
`main` after derivation; `check_all` runs everything.
Where: [invariants.md](invariants.md) (which invariant each check arms) ·
code: [../tools/check_authorship.exs](../tools/check_authorship.exs),
[../tools/check_exchanges.exs](../tools/check_exchanges.exs),
[../tools/check_deps.exs](../tools/check_deps.exs),
[../tools/check_views.exs](../tools/check_views.exs),
[../tools/check_all.exs](../tools/check_all.exs) · hook doorway:
[../tools/hooks/pre-commit](../tools/hooks/pre-commit).

## classifier

The role (and the capture pipeline's second model call) that proposes
metadata for a new record — [tags](#tags), [deps](#deps), a one-sentence
reason — as one JSON object. Proposal, not authority: the tool
shape-checks tags, stat-checks deps, and writes the survivors; failures
degrade to [UNCLASSIFIED](#unclassified), never block capture.
Where: [roles.md](roles.md) · code: [../tools/ask.exs](../tools/ask.exs)
module `IJS.Classifier`.

## conversational layer

The messages the operator and agent actually displayed to each other —
what a transcript can capture verbatim. Contrast [work layer](#work-layer).
Where: declared in the bootstrap record's preamble,
[../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md).

## cycle

The unit of work between exchanges and history: a branch
(`cycle/YYYY-MM-DD-<name>`, named at open — intent declared before the
work exists) carrying one or more record commits, closed by a PR whose
required checks pass and whose squash merge carries the operator's
hand-written message describing the cycle. Cycles may run in parallel;
each must be self-contained modulo `main` ([deps](#deps) target `main`
∪ the cycle's own branch).
Where: [workflow.md](workflow.md).

## deps

Frontmatter field: comma-separated repo-relative paths of prior
exchanges the new one directly continues. Deps point at **exchanges**,
never at threads (threads are derived *from* deps). Every path must
exist on disk — enforced at write time and at commit. Blank = a root.
Where: [exchange-schema.md](exchange-schema.md) ·
[invariants.md](invariants.md) INV-3 · code:
[../tools/check_deps.exs](../tools/check_deps.exs), and the dep-walk in
[../tools/derive_threads.exs](../tools/derive_threads.exs).

## derivation job

The deterministic CI job that runs on every push to `main`: regenerates
all derived views, verifies the full check suite, and — only when views
changed — commits the regeneration itself, touching `#derived` paths
only. One of exactly two writers of `main` (the other is the operator's
merge); it is machinery, not an agent, per the trust gradient.
Where: [workflow.md](workflow.md) · [invariants.md](invariants.md)
INV-5′ · code: `.github/workflows/derive.yml`.

## derived view

A file computed wholesale from the ledger by a deterministic tool —
[threads](#thread) (lineage) and taxonomy leaf indexes (aboutness).
Marked `#derived`; regenerated, never hand-edited; links only, never
copies. The third mutability regime. Views live on `main` only —
[cycle](#cycle) branches carry records, never view changes; after each
merge the [derivation job](#derivation-job) regenerates the views, and
`check_views` verifies that `main`'s views equal their regeneration
(falsifiable by regeneration).
Where: [constitution.md](constitution.md) §3, §6 · code:
[../tools/derive_threads.exs](../tools/derive_threads.exs),
[../tools/derive_indexes.exs](../tools/derive_indexes.exs),
[../tools/check_views.exs](../tools/check_views.exs).

## digest

The machine-written Side Effects content of an exchange: a deterministic
projection of the [sidecar](#sidecar) — `num_turns`, tools invoked,
permission denials, classifier note and cost, NEW-tag flags, dropped-dep
notes, [retriever](#retriever) coverage. Recomputable from the sidecar
by anyone; that is what makes it evidence rather than a model claim.
Where: [exchange-schema.md](exchange-schema.md) · code: the
`side_effects` assembly in [../tools/ask.exs](../tools/ask.exs)
(`IJS.Ask.main/1`) and harvest in `IJS.Envelope`.

## docs

One of the three content classes: the governing layer — doctrine,
policy, purpose, intent, invariants, contracts, methods, tripwires.
Defined by **ratification, not species of author**: operator-authored or
agent-originated-then-promoted, authorship carried by markers,
agent-originated docs dep-linked to their birth exchange. "Doctrine" is
the informal collective name for the normative content of `docs/`.
Where: [constitution.md](constitution.md) §2.

## envelope

The JSON the harness emits *around* a model call — init event, message
stream, result object — carrying machine-measured fields the model never
writes: `session_id`, `model`, `cost_usd`, `cwd`, `num_turns`, tool-use
records. Not a canonical industry term (the official docs say "messages"
and "result object"); it is this repo's name for that wrapper. Shape
warning: `claude -p --output-format json` emits one
object; adding `--verbose` emits an array whose init message is the only
carrier of `model` and `cwd` — the harvest handles both.
Where: [backend-contract.md](backend-contract.md) ·
[exchange-schema.md](exchange-schema.md) (field provenance) · code:
[../tools/ask.exs](../tools/ask.exs) module `IJS.Envelope` · pinned
shapes: [../tools/stub-fixtures/](../tools/stub-fixtures/).

## evidence

Anything a verdict can be re-audited against: [sidecars](#sidecar), the
git history, the ledger itself. Rule: verdicts never destroy their
evidence — a verdict without evidence is unfalsifiable. Evidence is
kept, never deleted; any future retention policy is operator-ratified
and executed by a deterministic script.
Where: [constitution.md](constitution.md) §7.

## exchange

The atomic record class: one operator↔agent interaction — prompt
verbatim, response verbatim, derived Side Effects — filed flat, dated,
immutable in `exchanges/`, named before the answer exists. The only
place agent content is born ([nursery rule](#nursery-rule)).
Where: [constitution.md](constitution.md) §2 ·
[exchange-schema.md](exchange-schema.md) · enforced by
[../tools/check_exchanges.exs](../tools/check_exchanges.exs).

## executor

The highest [capability-dial](#capability-dial) role: write tools inside
the git working tree, for multi-file work. Audited by diff + sidecar +
checks; cannot commit. Escalation beyond the tree (network, system
state) requires an explicit per-task operator grant (tripwire T2).
Where: [roles.md](roles.md) · [tripwires.md](tripwires.md).

## exit criterion

The done-condition for bootstrap threads: the class retires when any
change can travel as persisted exchanges + deterministic tool runs +
operator commits, checks green at commit. The standing audit may ask of
any change: did this need a thread?
Where: [intent.md](intent.md).

## fenced return

The middle dial setting: the [generator](#generator) returns exactly one
artifact as a fenced code block — data, not a filesystem action — and a
deterministic tool installs it.
Where: [roles.md](roles.md) · [methods.md](methods.md) §3.

## fenced-JSON stripping

The guard against models wrapping JSON replies in markdown code fences
despite instructions: fence-only lines are deleted before parsing; if
the remainder still isn't a JSON object, capture proceeds with
[UNCLASSIFIED](#unclassified). The raw fenced reply is preserved in the
sidecar as evidence either way.
Where: code: `IJS.Classifier.parse/1` in
[../tools/ask.exs](../tools/ask.exs) · exercised by
[../tools/stub-fixtures/classify-2.json](../tools/stub-fixtures/classify-2.json).

## frontmatter

The nine `key: value` lines between `---` fences at byte zero of every
exchange. Flat by design — no YAML parser dependency, parseable by line
discipline (an anti-goal in [intent.md](intent.md)).
Where: [exchange-schema.md](exchange-schema.md) · enforced by
[../tools/check_exchanges.exs](../tools/check_exchanges.exs).

## generator

The role that authors content — code or prose — as a return value
against a contract and acceptance test. Input: the contract + the test.
Output: one fenced block, nothing else. Installation is mechanical and
not the generator's.
Where: [roles.md](roles.md) · [methods.md](methods.md) §3.

## harness

The vendor machinery around a model: system prompt scaffolding, tool
orchestration, permission layer, session management. `claude -p` *is*
the Claude Code harness in headless mode — there is no harness-free
`claude -p`. This system rents the harness's [inner loop](#inner-loop)
and owns the [outer loop](#outer-loop).
Where: [backend-contract.md](backend-contract.md) · divorce triggers:
[tripwires.md](tripwires.md) T1.

## inner loop

What is rented, never rebuilt: tool-call orchestration, retries,
streaming, auth, model routing — commodity, expensive to own, and
largely unused by the no-tools roles anyway.
Where: [backend-contract.md](backend-contract.md).

## ledger

The `exchanges/` directory as a concept: records filed by provenance,
immutable, dated — what happened, in the form it happened. Aboutness is
computed as [derived views](#derived-view), never by re-shelving.
Where: [constitution.md](constitution.md) §1.

## no silent caps

Standing rule: whenever machinery bounds coverage — top-k, truncation,
sampling — the bound is recorded where the result lands, because "found
nothing" is meaningless unless what was searched is on record.
Where: [constitution.md](constitution.md) §9 ·
[tripwires.md](tripwires.md) T3 · code: the [shown-list](#shown-list)
written by [../tools/ask.exs](../tools/ask.exs) into every sidecar.

## nursery rule

All agent content is born in the [ledger](#ledger), as an exchange.
Promotion out of the ledger is the operator's ratifying act, with
exactly two targets: docs (it governs) and tools (it runs). Everything
else stays in the ledger and is referenced by path.
Where: [constitution.md](constitution.md) §4 · flow:
[methods.md](methods.md) §2.

## operator

The human; the system's declared trust root. Names every exchange,
audits every record, makes every commit. The verification regress
terminates here and in deterministic code — nowhere else.
Where: [roles.md](roles.md) · [invariants.md](invariants.md) INV-5.

## outer loop

What this system owns: capture, provenance, context assembly, role
routing, audit — the half of a harness no vendor provides.
Where: [backend-contract.md](backend-contract.md) · embodied across
[../tools/](../tools/).

## planner

Pure-function role that returns a plan artifact. A plan with open
questions is not executable — the gate is mechanical (exit-code check),
not social.
Where: [roles.md](roles.md).

## promotion

The operator's ratifying act of moving agent-born content out of the
ledger into force — into docs or tools — with a provenance link back to
the birth exchange. The commit is the ratification event. See
[nursery rule](#nursery-rule).
Where: [constitution.md](constitution.md) §4, §8 ·
[methods.md](methods.md) §2.

## property loop

The acceptance test that fights back: assemble a random *valid* exchange
→ every check must pass; apply one random mutation → the check that owns
the violated invariant must fail. Catches wrong verdicts examples can't.
Where: [methods.md](methods.md) · code:
[../test/prop_checks.exs](../test/prop_checks.exs) (operator-only zone).

## register

The invariant list — the system's smallest load-bearing artifact.
Append-and-supersede, dated, capped at five live entries; each names its
origin, what breaks if violated, and what arms it.
Where: [invariants.md](invariants.md).

## residue

What no layer can hold — scope selection, taste, the judgment of what to
ask — with a named owner: the operator, knowingly. Unarmed halves of
invariants live here until armed.
Where: [methods.md](methods.md) §8.

## respondent

The default role: plain Q&A, call 1 of every capture. Pure function.
Where: [roles.md](roles.md) · written into every captured record's
`role:` field by [../tools/ask.exs](../tools/ask.exs).

## retriever

The deterministic pre-sort before classification — not an agent, a
ranking function: tokenize the new prompt+response, drop stopwords,
score every prior exchange by shared-token count, take the top-k for
full-text inclusion. Same inputs, same shortlist, every run; the
semantics stay with the model, which reads only the shortlist in full.
Where: [roles.md](roles.md) context · code:
[../tools/ask.exs](../tools/ask.exs) module `IJS.Retriever`.

## role

Frontmatter field naming which contract the exchange's agent ran under:
`respondent` · `planner` · `generator` · `classifier` · `verifier` ·
`executor` · `bootstrap` (once, never again).
Where: [roles.md](roles.md) · [exchange-schema.md](exchange-schema.md) ·
role-aware checking in
[../tools/check_exchanges.exs](../tools/check_exchanges.exs).

## schema

The exchange file's required shape: eight frontmatter keys in order,
fence at byte zero, three sections each under its marker. Extra keys
fail — that arms tripwire T5 (schema drift).
Where: [exchange-schema.md](exchange-schema.md) · enforced by
[../tools/check_exchanges.exs](../tools/check_exchanges.exs) · fought by
[../test/prop_checks.exs](../test/prop_checks.exs).

## shown-list

The exact evidence the [classifier](#classifier) was given — which
candidates at full text (with scores), which as one-line stubs —
recorded in the sidecar so a missed dep is diagnosable as "never shown
in full" versus "shown and rejected". The mechanism that satisfies
[no silent caps](#no-silent-caps).
Where: code: the `shown_lines` block in
[../tools/ask.exs](../tools/ask.exs); stored under `shown_list` in every
sidecar.

## sidecar

The per-exchange evidence file
`exchanges/envelopes/<same-basename>.json`: the raw answer
[envelope](#envelope) verbatim, the raw classifier envelope (fenced
warts and all), and the [shown-list](#shown-list). Kept forever;
verdicts never destroy their evidence.
Where: [constitution.md](constitution.md) §7 ·
[exchange-schema.md](exchange-schema.md) · code:
`IJS.JQ.build_sidecar/4` in [../tools/ask.exs](../tools/ask.exs).

## supersession

The only way committed records and register entries change: a new dated
entry (INV-n → INV-n′, both kept), never a silent edit. Docs are
edit-in-place *with* dated supersession for normative reversals;
exchanges are immutable outright.
Where: [constitution.md](constitution.md) §6 ·
[invariants.md](invariants.md) discipline note ·
[methods.md](methods.md) §5.

## tags

Frontmatter field: 1–3 comma-separated [taxonomy](#taxonomy) paths,
cross-cutting facets of what the record is about (OKF-style: path says
what a thing *is*, tags say what it's *about*). Proposed by the
classifier, validated against the vocabulary, NEW coinages flagged for
audit, ratified by the operator's commit.
Where: [exchange-schema.md](exchange-schema.md) · vocabulary assembly:
`IJS.Classifier.vocab/0` in [../tools/ask.exs](../tools/ask.exs) ·
consumed by [../tools/derive_indexes.exs](../tools/derive_indexes.exs).

## taxonomy

The tag vocabulary as a directory tree (`taxonomy/`) — vocabulary only,
never content. Each leaf holds a `#derived` `index.md` (links only),
which is also what lets git track the tree. Grows by classifier proposal
+ operator commit.
Where: [constitution.md](constitution.md) §3 · code:
[../tools/derive_indexes.exs](../tools/derive_indexes.exs).

## thread

A [derived view](#derived-view) materializing lineage: the chain found
by following each record's first dep up to a root. Threads are computed
from [deps](#deps), never pointed at by them.
Where: [constitution.md](constitution.md) §3 · code:
[../tools/derive_threads.exs](../tools/derive_threads.exs).

## tools

One of the three content classes: deterministic executable machinery in
`tools/`. The directory marks role (plumbing); authorship markers and
provenance still apply to each tool.
Where: [constitution.md](constitution.md) §2 · the inventory:
[../tools/](../tools/).

## tripwire

A pre-committed trigger for a deferred decision: the decision, the
condition that un-defers it, and the response — checked by the weekly
review. Firing one is the plan working, not failing.
Where: [tripwires.md](tripwires.md).

## trust gradient

The ordering this system builds down: natural language → structured,
validated data → deterministic shell/code semantics. Verification
terminates only when the verifier sits lower on the gradient than the
thing verified; agent-verifying-agent reduces variance but never
terminates.
Where: applied throughout [roles.md](roles.md) (capability dial) and
[exchange-schema.md](exchange-schema.md) (field provenance classes).

## UNCLASSIFIED

The sentinel written into `tags:` when the classifier's reply is
unusable after [fenced-JSON stripping](#fenced-json-stripping). Capture
never blocks on classification; the Side Effects digest tells the
operator to set the field by hand before committing.
Where: code: `IJS.Classifier.run/3` in
[../tools/ask.exs](../tools/ask.exs).

## verifier

Pure-function (plus read-only) role that returns findings about an
existing record — claims checked against evidence (e.g. Side Effects
digest vs. the sidecar's tool log). Reviews are shaped for refutation,
never affirmation, and never edit.
Where: [roles.md](roles.md) · protocol: [methods.md](methods.md) §4.

## work layer

What happened *between* the displayed messages — tool calls, tests,
file writes. Not capturable by a transcript; its evidence is the
[sidecar](#sidecar) for normal captures and the git history for the
bootstrap. Contrast [conversational layer](#conversational-layer).
Where: [exchange-schema.md](exchange-schema.md) (digest) · the bootstrap
record's Side Effects.
