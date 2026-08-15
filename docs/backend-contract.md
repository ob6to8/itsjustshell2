# Backend contract

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [adapter](glossary.md#adapter) · [backend](glossary.md#backend) · [envelope](glossary.md#envelope) · [harness](glossary.md#harness) · [inner loop](glossary.md#inner-loop) · [outer loop](glossary.md#outer-loop)

Roles are defined harness-independently. All inference travels through an
**adapter** that normalizes the vendor's output. Vendor names — CLIs,
model tiers, defaults — live in exactly two places: the adapters and the
prerequisites list; the contract itself is vendor-blank. (While the
adapters live inside `ask.exs` this is held by review; when a second
backend lands in its own file, a vendor-name grep over everything except
`tools/backend-*` becomes armable — see [tripwires.md](tripwires.md)
T1.) The system owns the outer loop — capture, provenance, context
assembly, role routing, audit. The inner loop — tool-call orchestration,
retries, streaming, auth, model routing — is rented, never rebuilt.

## The interface

An adapter takes `(prompt, opts)` — opts may carry `model` and nothing
that widens capability — invokes its backend with **no tools enabled**,
and yields:

- the **raw envelope**, saved verbatim to a file (ground truth for the
  sidecar), and
- the normalized fields harvested from it: `text` (the response),
  `session_id`, `model`, `cost_usd`, `cwd` — any of which may be blank if
  the backend does not report them. Blank, never invented.

Adapters implemented in `tools/ask.exs`:

- **claude-p** (backend #1): `claude -p --output-format json --verbose`.
  `--verbose` is load-bearing — it yields the array-shaped envelope whose
  init message carries `model` and `cwd`; the plain object shape carries
  neither. Harvest is shape-proof (object and array both handled).
- **stub**: reads a canned envelope from a file (`ASK_STUB`,
  `ASK_STUB_CLASSIFY`). The stub backend is a first-class citizen: it is
  how the pipeline is tested without inference, and how fixtures pin the
  envelope shapes a vendor emitted on a given date.

## Adding a backend — fixtures first

Write one adapter honoring the interface (a raw-API `curl`, another
vendor's CLI). Nothing else changes — not the schema, not the roles, not
the tools. The recipe, in order:

1. **Discover the vendor CLI's headless surface**: the non-interactive
   flag, the machine-readable output flag, and which normalized fields
   its output can actually supply (session/run id, model, cost, cwd).
   Fields it cannot supply stay blank — never synthesized.
2. **Pin the envelope before writing any code**: run the vendor CLI
   once by hand, save its raw output verbatim as
   `tools/stub-fixtures/<vendor>-answer-1.json` (plus an error-shaped
   one). This is how backend #1 was built: the shipped fixtures pin the
   claude CLI's one-object and `--verbose`-array shapes as captured
   from the real binary — the fixture is the shape's proof, and the
   adapter is written against the fixture, not against documentation
   or memory.
3. **Write the adapter** in its own `tools/backend-<vendor>` file:
   invoke with no tools enabled, save the raw envelope to disk, harvest
   the normalized fields.
4. **Run the pipeline in stub mode** against the new fixtures before
   the first live call.
5. **Arm vendor isolation**: the moment a second adapter file exists,
   add the vendor-name grep (everything outside `tools/backend-*` and
   the prerequisites list must be vendor-blank) — see
   [tripwires.md](tripwires.md) T1.

Codex and pi are the intended next adapters. Their envelope shapes are
deliberately **not** described here: this contract records no shape it
has not pinned as a fixture, and step 2 is where those shapes enter —
captured empirically on the operator's machine, not asserted from
memory. Divorce triggers for backend #1 are listed in
[tripwires.md](tripwires.md); the response to any of them is a new
adapter, not a rewrite.
