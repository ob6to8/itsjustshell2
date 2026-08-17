---
session_id: 22bd4289-97ca-419e-bc7c-c891e6570095
date: 2026-08-16T08:47:59Z
model: claude-sonnet-5
cost_usd: 0.762942
cwd: /Users/mark/dev/repos/itsjustshell2
role: respondent
tags: pipeline/capture, methodology
deps: exchanges/2026-08-15-bootstrap-thread.md, exchanges/2026-08-16-model-setting.md
---

## Prompt
#human-authored

consider the following approach to how exchanges are run. currently prompts are entered directly on the command line via elixir tools/ask.exs <slug> xxxx. in 2026-08-16-model-setting.md there is an exchange related to setting the model, and what would need to be adjusted to allow for that. this led to an idea: what would it look like to keep exchanges/drafts/, within which there would be prompts that are formatted for submission but not submitted yet? this would allow for them to be created, saved, revised, persisted until submission time. it would mean I could do the writing of the prompt, and editing, in neovim. I am imagining a command, like elixir tools/init.exs <slug> which would init the file, in which I would then proceed to add the prompt. also, i could at that time flag previous exchanges I find to be related, as well as set the model. spec out what this would look like to build out. if feasible, include the build plan at the end of your response

## Response
#agent-authored

## What this changes

Today, `elixir tools/ask.exs <slug> "<prompt>"` couples three things into one shell invocation: composing the prompt, choosing the model, and firing the live call. A drafts layer splits composition from submission — you write and revise in neovim, then submit separately, possibly hours or days later.

## Where drafts live

Not inside `exchanges/`. That directory is doctrinally the ledger — "immutable, dated, flat records," and both `roles.md`'s forbidden-zone list and the checks assume only the capture tool writes there, only new files. A draft is the opposite of a record: mutable, hand-edited, pre-dated, meant to be deleted once consumed. Nesting it under `exchanges/` would work *mechanically* (the checks' wildcards are non-recursive, so `exchanges/drafts/*.md` would slip past `check_exchanges.exs` and `check_deps.exs` by accident) but that's the wrong reason to place it there — it'd be exploiting a glob pattern rather than following the doctrine.

So: a new top-level `drafts/`, sibling to `exchanges/`, `docs/`, `tools/`. `constitution.md` §2 currently says content classes are "exactly three" (ledger/docs/tools); `drafts/` isn't a fourth content class in that sense — it never holds ratified content, only pre-ledger scratch that either graduates into an exchange or gets deleted. It fits better as a new subsection alongside §3 ("Vocabulary and views" already carves out `taxonomy/`/`threads/` as top-level dirs outside the three-class enumeration). This is additive, not a contradiction of §2 — but since `constitution.md` is edit-in-place-with-supersession doctrine, you'd want to actually ratify that framing rather than have me assert it.

One constraint this forces: `tools/check_authorship.exs` globs `**/*.md` and only excludes paths starting with `exchanges/`. It runs on every commit via the pre-commit hook, scanning the whole working tree regardless of what's staged — so a marker-less file anywhere under `drafts/` would block *every* commit repo-wide, not just draft-related ones. That means the draft template must carry a valid authorship marker (`#human-authored`) from the moment it's created, or nothing else can be committed while a draft is in progress.

## Draft file format

`drafts/<slug>.md` — no date prefix, since the slug is chosen before the exchange exists (the real dated filename gets minted at submission time by the existing `ask.exs` logic, same as today).

```
#human-authored

model: 
deps: 

---

<prompt text — multiline, whatever you write>
```

- `model:` — optional, mirrors `ASK_MODEL`. Precedence: `ASK_MODEL` env var (or a future `--model` flag) overrides the draft's field if set; otherwise the draft's field is used; otherwise CLI default. This is the exact ambiguity the model-setting exchange flagged as needing an explicit decision.
- `deps:` — optional, comma-separated, same shape as the exchange schema's `deps:` field. These are operator-flagged, not classifier-proposed — the schema already recognizes `deps:` as `proposed / operator` provenance, so this slots in cleanly: at submission, operator-supplied deps are unioned with whatever the classifier proposes, deduped, and validated through the same kept/dropped logic `IJS.Classifier.run/3` already applies (must start with `exchanges/`, must exist, can't be the target itself). Invalid operator deps get reported in Side Effects distinctly from dropped classifier deps.
- Everything after the `---` is the verbatim prompt, byte-for-byte (no `Enum.join(rest, " ")` collapsing — this is the actual point of the feature, since multi-paragraph prompts are painful to type as shell args).

## `tools/init.exs` (new, small, single-purpose)

```
elixir tools/init.exs <slug>
```

- Refuses to run outside the repo root (same guard pattern as `ask.exs`).
- Refuses to overwrite an existing `drafts/<slug>.md` — if you want to restart, delete it first. No `--force`; that's a corner nobody needs yet.
- `File.mkdir_p!("drafts")`, writes the template above, prints the path and a one-line reminder of the submit command.
- No inference call, no filesystem writes outside `drafts/`. Pure scaffolding — this keeps it clearly separate from the capture job per tripwire T6 (tool fission: one job per tool), and clearly outside the capture pipeline's "single writer of `exchanges/`" property.

## Changes to `tools/ask.exs`

Extend `main/1`'s argv handling rather than forking a second submission tool — capture stays one job with one seam (the backend), which is the existing T6 justification for `ask.exs`'s oversized-file exception. This just changes where the prompt/model/deps *come from*, not the capture logic itself:

- `[slug, prompt_words...]` (current form) — unchanged behavior.
- `[slug]` alone — look for `drafts/<slug>.md`. If absent, die with a usage message covering both forms. If present, parse the `model:`/`deps:` header and the body-after-`---` as the prompt, and feed the existing pipeline (backend call → harvest → retrieve → classify → write exchange + sidecar) exactly as today, with the draft's `model:` substituted into `opts[:model]` (subject to the precedence above) and the draft's `deps:` merged into the classifier's proposed `deps` before validation.
- On success, delete `drafts/<slug>.md` — the content now lives verbatim in the immutable exchange, and a stale duplicate invites drift. Print that this happened, and note in the final `git add` instructions that the draft's deletion and the exchange's creation are worth committing together (`git add exchanges drafts && git commit`).

`IJS.Backend`, `IJS.Envelope`, `IJS.Retriever`, `IJS.Classifier` need zero changes — they already operate on `(prompt, opts)` and don't care where the caller sourced either from.

## Doctrine touches (yours to ratify, not mine to just do)

- `constitution.md` — new subsection describing `drafts/` as pre-ledger, mutable, operator-owned staging; explicitly outside the three content classes and outside the vocab/views pair.
- `glossary.md` — a `draft` entry, linking to wherever the above lands and to `tools/init.exs`/`tools/ask.exs`.
- `roles.md` — probably nothing; `drafts/` isn't a forbidden zone, and nothing about the capability dial changes.
- `tripwires.md` — nothing fires. T5 (schema drift) only watches ledger frontmatter; the draft header format is deliberately outside that surface.
- The `ask.exs` header comment's T6 justification should get a clause added noting the draft-reading branch is the same job (capture), different input source — otherwise a future reader might reasonably ask why the file grew again.

## Feasibility

Straightforward. No new dependencies, no changes to the checks, no interaction with `check_views.exs` (it only copies `exchanges/`, `taxonomy/`, `threads/`). The one real design decision that needs your sign-off before building is the `constitution.md` framing (fourth-thing-that-isn't-a-content-class) and the model/deps precedence rules above — everything else is mechanical.

## Build plan

1. **`tools/init.exs`** — scaffold-only tool: guard, `mkdir_p`, overwrite refusal, template write, usage print. Small enough to write and test standalone.
2. **Draft parser** — a small module (could live in `tools/ask.exs` alongside `IJS.Ledger`, e.g. `IJS.Draft`) that reads `drafts/<slug>.md`, extracts `model:`/`deps:`/body, and validates the marker + `---` fence are present (fail loud if the operator mangled the template).
3. **`ask.exs` `main/1` branch** — wire the `[slug]`-only case: locate draft → parse → build `opts`/`prompt` → fall through into the existing pipeline unchanged from the harvest step onward.
4. **Deps merge** — extend `IJS.Classifier.run/3` (or wrap its output in `main/1`) to union operator-supplied deps with classifier-proposed deps before the kept/dropped validation, and extend the Side Effects builder to report operator-dropped deps distinctly.
5. **Draft cleanup** — delete the draft file on successful write, adjust the final `git add` instructions.
6. **Stub-mode test** — exercise the new path with `ASK_STUB`/`ASK_STUB_CLASSIFY` fixtures the way the existing pipeline is already tested, covering: draft with model set, draft with deps set, draft with invalid deps, missing draft + no inline prompt.
7. **Doctrine commits** — `constitution.md` subsection, `glossary.md` entry, `ask.exs` header T6 clause — separate commit from the tool changes, since docs and tools are different change classes per `workflow.md`.
8. **`docs/exchange-schema.md` cross-reference** (optional but tidy) — a line noting drafts as the pre-submission staging path, so a reader following the schema doc finds the on-ramp.

All of this fits on one cycle branch (`cycle/2026-08-16-drafts` or similar) as a single change class mix (tools + docs), consistent with how the model-setting question would presumably also land.

## Side Effects
#derived

created persistent record (this document)
harness digest: num_turns=10, tools=Bash, Bash, Bash, Bash, Bash, Bash, Bash, Bash, Bash, permission_denials=0
tags and deps machine-proposed (classifier model: claude-haiku-4-5-20251001, cost_usd: 0.0389511) — reason: Proposes a drafts workflow layer for composing exchanges before submission, directly extending the model-setting discussion and grounding the new directory structure in constitution constraints.
retriever: full text shown for 4 of 5 candidates (shown_list in sidecar)
