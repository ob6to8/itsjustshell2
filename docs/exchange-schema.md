# Exchange schema

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [frontmatter](glossary.md#frontmatter) · [envelope](glossary.md#envelope) · [tags](glossary.md#tags) · [deps](glossary.md#deps) · [role](glossary.md#role) · [sidecar](glossary.md#sidecar) · [digest](glossary.md#digest) · [UNCLASSIFIED](glossary.md#unclassified) · [bootstrap exception](glossary.md#bootstrap-exception)

Filename: `exchanges/YYYY-MM-DD-<slug>.md` — the operator names the
exchange at ask time; naming before the answer exists is the point.
Sidecar: `exchanges/envelopes/YYYY-MM-DD-<slug>.json`.

## Frontmatter — nine keys, this order, fence at byte zero

Field provenance classes (who writes the value):
**envelope** = machine-measured, copied from the harness JSON by the
capture tool — never model-written, never operator-typed;
**operator** = declared by the operator at invocation;
**proposed** = model-suggested, tool-validated, ratified by the
operator's commit (hand-correcting pre-commit is the audit working).
Blank is always legal — a field with no true value stays empty; values
are never invented.

| key | provenance | notes |
|---|---|---|
| `id:` | envelope (derived) | next integer over the ledger, zero-padded to 4; the filesystem is the counter |
| `session_id:` | envelope | |
| `date:` | envelope | UTC, ISO-8601, stamped at capture |
| `model:` | envelope | |
| `cost_usd:` | envelope | |
| `cwd:` | envelope | |
| `role:` | operator | `respondent` default; see [roles.md](roles.md) |
| `tags:` | proposed | comma-separated taxonomy paths, 1–3; new coinages flagged NEW in Side Effects |
| `deps:` | proposed / operator | comma-separated repo-relative paths of prior exchanges this one continues; every path must exist (INV-3); blank = root |

## Sections — three, in order, each under its marker

```
## Prompt
#human-authored
<the operator's words, verbatim — captured from the shell argument,
never from a model's repetition of them>

## Response
#agent-authored
<the model's answer, verbatim from the envelope's result>

## Side Effects
#derived
<machine-written digest: created persistent record (this document) ·
harness digest (num_turns, tools invoked, permission denials) ·
classifier note (model, cost, reason) · NEW-tag flags · dropped-dep
notes · UNCLASSIFIED warning if the proposal was unusable>
```

Side Effects is `#derived` — a deterministic projection of the sidecar,
not a model claim. Anyone can recompute it from the sidecar and diff.

## Example

```
---
id: 0002
session_id: 3b9fd7e2-8c15-4f60-b2a4-91d3c5e7f8a0
date: 2026-08-15T09:12:44Z
model: <model id as reported by the envelope>
cost_usd: 0.0187
cwd: /Users/mark/dev/repos/itsjustshell2
role: respondent
tags: pipeline/capture
deps: exchanges/2026-08-15-first-live-capture.md
---

## Prompt
#human-authored

How should threads be derived from deps fields?

## Response
#agent-authored

Walk every exchange's deps transitively; each chain is a thread...

## Side Effects
#derived

created persistent record (this document)
harness digest: num_turns=1, tools=none, permission_denials=0
tags and deps machine-proposed (classifier cost_usd: 0.0009) — reason: ...
```

## The bootstrap exception

`exchanges/2026-08-15-bootstrap-thread.md` (`role: bootstrap`) records
the multi-turn thread that created this repo — the one record not born
through the one-shot loop. It is schema-complete, its envelope fields
blank where no envelope existed, and the exception is never repeated.
Its deviations are layout-only, declared in the record's own preamble:
the assembler's preface sits **above** the `## Prompt` section, so the
Prompt holds operator words alone under `#human-authored` like every
other record; and both sections carry **navigation apparatus**
(`### Turn n` / `### Agent n.m` headings, with `→` links at the end of
each block chaining turn → response group → next turn) — text between
headings is byte-verbatim.
