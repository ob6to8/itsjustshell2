# Workflow — cycles, merges, derivation

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [cycle](glossary.md#cycle) · [derivation job](glossary.md#derivation-job) · [checks](glossary.md#checks) · [derived view](glossary.md#derived-view) · [deps](glossary.md#deps) · [operator](glossary.md#operator)

## The unit of work is the cycle

#human-authored
The idea behind the workflow in this system is similar to that of a feature branch - the user creates a branch `cycle/YYYY-MM-DD-<name>`, where <name> is the expected focus of a series of changes to the repo. Once the cycle has been resolved, or having reached the point that the operator wants to cease work, they issue a pull request, which functions as a ratification step. This step is gated by the operator authoring the squash-merge message and the agent writing the pr description/merge message. Commits made in the branch notably do not include derived views which are deterministically generated - given they are not to be changed by operators or agents, they are retained on main and can only be touched by CI/CD.

#agent-authored
A cycle is a branch: `cycle/YYYY-MM-DD-<name>`, named when it is opened
— intent declared before the work exists. A cycle carries any change
class — exchanges and sidecars, docs, tools, taxonomy nodes — with one
exclusion: **derived views never change on a branch**. Views belong to
`main` and are written only by the derivation job.

## During a cycle

- Each capture is committed to the branch as it is audited:
  `git add exchanges && git commit`. One commit per exchange keeps the
  branch legible; other change classes commit at whatever granularity
  reads well.
- The pre-commit hook runs the **record checks**
  (`tools/check_records.exs`: authorship, exchanges, deps) on every
  commit. `check_views` does not gate branch commits — branch views are
  expected to lag.
- `deps:` may target exchanges on `main` and exchanges earlier in the
  same branch — nothing else. A dep that wants an exchange from another
  open cycle means the two cycles are one cycle, or one merges first.
- Cycles may run in parallel. The only cross-cycle collision surface is
  two branches minting the same `YYYY-MM-DD-<slug>` filename, which git
  surfaces as an ordinary conflict at the second merge.

## Closing a cycle

1. Push the branch and open a PR to `main`.
2. The PR-required CI runs the record checks; red blocks the merge.
3. **When an agent worked the cycle, the agent writes the PR
   description as the merge message it would have written** — the agent
   half of the cycle's dual entry.
4. The operator squash-merges with a **hand-written message describing
   the cycle** — the operator half, and the ratification. `main`'s
   history is one commit per cycle, each carrying the operator's own
   account; divergence between the two halves is visible on the PR
   forever.
5. Nothing merges itself: merging is the operator's act, always.

## After the merge — derivation

On every push to `main`, the derivation job regenerates all derived
views (taxonomy leaf indexes, threads), runs the full check suite
(`check_all`, including `check_views`), and — only when views changed —
commits the regeneration, touching `#derived` paths only, with its own
name on the commit. `main` therefore has exactly two writers: the
operator's merge, and this job (INV-5′). If derivation or any check
fails, the job fails loudly and commits nothing.

## `main` protections

The gate is a repository ruleset on `main` (operator-console act:
recorded here, applied there): a PR is required before merging, the
`records` check is required to pass, and deletions and force pushes
are blocked. Sole bypass actor: deploy keys — one write-enabled key
exists, held by the derivation job as the `DERIVE_SSH_KEY` secret, so
the job is `main`'s only direct pusher. The operator lands work
through PR merges like any writer; the job's workflow token is
read-only, so the deploy key is its single write path. The reasoned
walk-through — every console step and why — is in
[setup.md](setup.md).

## Failure handling

- Red record check on a branch commit: fix the record, commit again —
  the file is not yet ratified; editing it is the audit working.
- Red PR check: same, on the branch, before merge.
- Red derivation job on `main`: the merge introduced a state the checks
  reject — open a correction cycle; never push fixes directly to
  `main`.
