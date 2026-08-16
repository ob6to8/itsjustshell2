# Setup — first contact and testing

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [capture](glossary.md#capture) · [checks](glossary.md#checks) · [envelope](glossary.md#envelope) · [adapter](glossary.md#adapter) · [backend](glossary.md#backend) · [sidecar](glossary.md#sidecar) · [tags](glossary.md#tags) · [deps](glossary.md#deps) · [cycle](glossary.md#cycle) · [derivation job](glossary.md#derivation-job) · [operator](glossary.md#operator)

## Prerequisites

git · Elixir 1.14+ · jq 1.6+ · the `claude` CLI, logged in (inference
backend #1). Verify all four before anything else:

```
elixir --version && jq --version && claude --version
```

## What actually runs when you capture

```
elixir tools/ask.exs <slug> "<your question>"
```

makes exactly **two inference calls, both through the CLI harness in
print mode** — command-line calls to a harnessed agent, not raw HTTP API
calls; this repo contains no API client:

1. **respondent** — your question, at your CLI's default model
   (`ASK_MODEL` overrides), no tools enabled;
2. **classifier** — a second, cheap call (the adapter defaults it to the
   backend's cheap tier; `ASK_CLASSIFY_MODEL` overrides) that proposes
   `tags:` and `deps:` as JSON, which the tool validates before writing.

Everything else is deterministic Elixir + jq. The backend is a swappable
seam — see [backend-contract.md](backend-contract.md), including the
recipe for integrating a different vendor CLI.

## First contact

The full operating protocol — cycles, branches, merges, derivation — is
[workflow.md](workflow.md); this is the walk-through.

1. **Clone and verify**: `git clone <repo> && cd <repo>` — then
   `elixir tools/check_all.exs; echo $?`. Expect **no output, exit 0**
   (a few seconds; several Elixir processes run, including the view
   regeneration sandbox). Any printed path means a broken clone.
2. **Arm the hook** (once per clone): `git config core.hooksPath
   tools/hooks`. No output.
3. **Open a cycle**: `git checkout -b cycle/YYYY-MM-DD-<name>` — the
   cycle is named before its work exists, the same declaration of
   intent as naming an exchange.
4. **Capture**: run the `ask.exs` command above. Expect 10–40 seconds
   (two model calls), then: the exchange and sidecar paths, a
   `tags | deps` summary line, the answer's cost, and a review
   reminder.
5. **Audit** — open the exchange file and check, in order: envelope
   fields populated (session, UTC date, model, cost, cwd; blank only
   where the backend reported nothing); your prompt **verbatim**; the
   answer **verbatim**; Side Effects carries the harness digest, the
   classifier note, and the retriever coverage line. Tags silly? Edit
   the `tags:` line by hand — pre-commit, that is the audit working.
   Side Effects flags a **NEW** tag you accept? `mkdir -p
   taxonomy/<path>` and commit the empty leaf's index at the next
   derivation.
6. **Commit to the branch**: `git add exchanges && git commit`. The
   hook runs the record checks; silence, then the commit lands. Repeat
   4–6 per exchange for the rest of the cycle.
7. **Close the cycle**: push the branch, open a PR, let the required
   record checks pass, then **squash-merge with a hand-written message
   describing the cycle** — the merge is the ratification. The
   derivation job then regenerates the views on `main` and commits
   them itself.

## The `main` gate — why it exists and how to stand it up

The long-form version of [workflow.md](workflow.md)'s protections
paragraph: every console step, plus the reasoning, in plain terms. It
assumes a cloned repo and admin rights on the GitHub repository.

### The principle

The repo runs on one promise: nothing reaches `main` except a cycle
the operator read and ratified by merging it, and the derivation job's
regeneration of derived views. Every doc here states that promise;
stating it enforces nothing. A rule that lives only in prose binds
exactly as long as everyone remembers it and every tool behaves — and
the moment an agent holds write credentials, "remember not to push" is
a contract with a failure mode. The gate moves the rule out of prose
and into the host: GitHub itself rejects the pushes the protocol
forbids. Mechanism replacing contract.

The gate must solve one awkward problem: it has to block *everyone* —
operator and agents alike — while still letting the derivation job
push view commits straight to `main`. So it is built from two parts: a
**ruleset** (the wall) and a **deploy key** (the one keyed door).

### The wall — a repository ruleset

A ruleset is GitHub's branch-protection mechanism with a bypass list;
this repo's ruleset targets the default branch and enforces four
rules:

- **Require a pull request before merging, approvals = 0.** The rule
  that closes `main` to direct pushes: commits arrive only through a
  merged PR — exactly the protocol's shape, where the operator's
  hand-written squash merge is the ratification. Approvals stay 0
  because on a solo repo GitHub will not let you approve your own PR;
  requiring 1 would deadlock every cycle.
- **Require status checks to pass, check = `records`.** The machine
  half of the merge gate: red record checks block the button. The
  operator ratifies content; the checks hold the schema.
- **Restrict deletions** and **Block force pushes.** Ledger
  immutability at the host level: `main`'s history can be added to,
  never rewritten or removed.

Two look tempting and are deliberately off: **Restrict updates** would
demand bypass permission for every update including the operator's own
PR merges (stricter than the protocol), and **Require linear history**
is redundant when every landing is a squash or a single derive commit.

The **bypass list** is who the wall does not apply to, and it holds
exactly one entry: **Deploy keys**. Not the operator — the gate is
supposed to bind you, and your writes go through PR merges anyway. Not
any agent app — a bypass there would hand an agent the direct write to
`main` that INV-5′ exists to forbid.

### The door — one deploy key

The derivation job is a GitHub Actions workflow, and workflows
normally push with GitHub's built-in token — but GitHub offers no way
to put that built-in token on a bypass list. The two identities that
can hold a bypass are a custom GitHub App (an app to register, plus a
token-minting step in the workflow) and a deploy key — an SSH key pair
registered on this one repository. One repo, one job: the deploy key
is the right size.

The arrangement:

- The **public half** is registered as a deploy key with write access
  — the lock on the door.
- The **private half** lives in one place: the repository secret
  `DERIVE_SSH_KEY`, injected into the derivation job and shown to no
  one. The key to the door.
- `derive.yml` checks out with `ssh-key: ${{ secrets.DERIVE_SSH_KEY }}`,
  so the job's later `git push` authenticates as the deploy key — a
  bypass actor — and passes the wall.
- The job's own workflow token is `contents: read`, deliberately: the
  job cannot push any way *except* the key, so the bypass list is a
  complete inventory of who may write to `main` directly.

Two side conditions, already in `derive.yml`, that only matter because
a key is involved:

- The derive commit message ends in `[skip ci]`. Token pushes never
  trigger workflows (GitHub's recursion guard); deploy-key pushes do —
  the marker is what keeps the derivation job from re-triggering
  itself.
- The job's path guard refuses to commit anything outside `taxonomy/`
  and `threads/` — holding the key does not widen what the job may
  write.

What the gate does not cover: GitHub gates what may merge, not who
presses the button, so nothing at the host level stops a write-capable
agent from merging a green PR. The never-merge half of INV-5′ remains
contract, owned in the methods residue.

### Standing it up, in order

Order matters for one reason: a ruleset activated before the key works
strands the derivation job — its next push is rejected and views stop
regenerating. Recoverable, but pointless. Build the door before
activating the wall.

1. **Create the ruleset, Disabled.** Settings → Rules → Rulesets →
   New branch ruleset. Name it anything; **Enforcement status:
   Disabled** for now. **Bypass list → Add bypass → Deploy keys.**
   **Target branches → Include default branch.** Tick the four rules
   above — each rule's sub-settings (the approvals count, the check
   picker) appear only after its parent box is ticked; set
   **Required approvals: 0** and **Add checks → `records`** (the name
   is known to GitHub once the check has run on any PR). Create.
2. **Mint the key** on your machine:
   `ssh-keygen -t ed25519 -f derive_key -N "" -C "derivation-job"` —
   produces `derive_key` (private) and `derive_key.pub` (public).
3. **Install the lock.** Settings → Deploy keys → Add deploy key →
   paste the contents of `derive_key.pub`, **check "Allow write
   access"**, Add. Expect the entry labeled **Read/write** — a
   Read-only label means the box was missed; delete the entry and
   re-add it (there is no edit).
4. **Install the key.** Settings → Secrets and variables → Actions →
   New repository secret, name exactly `DERIVE_SSH_KEY`, value = the
   entire contents of `derive_key`, BEGIN/END lines included. GitHub
   shows the name, never the value.
5. **Destroy the local copies:** `rm derive_key derive_key.pub`. The
   repository settings now hold the only copies that matter.
6. **Prove the door.** Merge any cycle, or re-run the derive workflow
   from the Actions tab. Green means the job checked out over SSH with
   the key. Red at checkout with `Permission denied (publickey)` means
   the secret is missing, misnamed, or mismatched with the registered
   key.
7. **Activate the wall.** Edit the ruleset → Enforcement status:
   **Active** → Save.

### What you should see once it is on

- A cycle PR shows `records` as a **Required** check; the merge button
  stays blocked while it is red.
- A direct push to `main` — anyone, any clone — is rejected with a
  ruleset violation. That is correct behavior, operator included: land
  it as a cycle instead.
- After a ratified merge that changes views, the derivation job still
  lands its `derive: regenerate views` commit. That push succeeding
  *is* the bypass working.

### Gate failure notes

- **Derive push rejected after activation**: the bypass list lost
  "Deploy keys", or the push is not using the key (secret gone or
  renamed). Fix the setting or the secret, then re-run the failed job
  from the Actions tab — it committed nothing.
- **Key rotation**: mint a new pair (steps 2–5) and delete the old
  deploy key entry. Nothing in the repo's files changes; the key never
  appears in them.
- **A second writer arrives**: the bypass class is *all* write-enabled
  deploy keys on this repo — revisit T8 in
  [tripwires.md](tripwires.md) before handing anyone else keys.

## Failure behavior, so nothing surprises

- Backend errors (auth, network) → `nothing filed`, exit 1, no file.
- Classifier garbage → the file lands with `tags: UNCLASSIFIED` and a
  Side Effects instruction to set it by hand; capture never blocks on
  classification.
- Same slug, same day → `refusing to overwrite … exchanges are
  immutable`.
- Hand-edited derived view at commit → the hook prints the diff and
  refuses; run the deriver instead.

## Testing without spending inference — the stub tier

The shipped fixtures pin real backend envelope shapes, so the whole
pipeline runs with zero model calls:

```
ASK_STUB=tools/stub-fixtures/answer-1.json \
ASK_STUB_CLASSIFY=tools/stub-fixtures/classify-1.json \
elixir tools/ask.exs stub-test "any question"
```

Expect a complete exchange + sidecar, canned content, real machinery
(validation, digest, sidecar assembly). `classify-2.json` exercises
the ugly paths: a fenced reply, a NEW tag, and an invalid dep that gets
dropped with a note. **Stub runs write real files into the ledger** —
test in a scratch clone, or delete the generated exchange + sidecar
before committing anything.

## Testing the live classifier cheaply — the mixed tier

The classifier is the one judgment component; test it live without
paying for a live answer by stubbing call 1 only:

```
ASK_STUB=tools/stub-fixtures/answer-1.json \
elixir tools/ask.exs classifier-test "any question"
```

Call 2 goes live at the cheap tier (fractions of a cent). Audit what it
proposed: are the tags drawn sensibly from the taxonomy? Are the deps
real continuations, given what the shown-list says it was shown? Repeat
with different fixtures and `ASK_CLASSIFY_MODEL` values to compare
tiers. Same ledger-pollution caveat: scratch clone, or clean up.

## Knobs

`ASK_MODEL` (answer call) · `ASK_CLASSIFY_MODEL` (classifier call) ·
`ASK_K` (retriever top-k, default 4) · `ASK_STUB` /
`ASK_STUB_CLASSIFY` (fixture envelopes instead of live calls).
