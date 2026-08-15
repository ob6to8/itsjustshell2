# Workflow — cycles, merges, derivation

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [cycle](glossary.md#cycle) · [derivation job](glossary.md#derivation-job) · [checks](glossary.md#checks) · [derived view](glossary.md#derived-view) · [deps](glossary.md#deps) · [operator](glossary.md#operator)

## The unit of work is the cycle

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

Intended repository settings (operator-console acts; record here, apply
there): require a PR before merging; require the `records` check to
pass; restrict direct pushes, with the derivation job as the sole
push-capable exception. Until enabled, these are held by convention and
by the hook — enabling them is mechanism replacing contract.

## Failure handling

- Red record check on a branch commit: fix the record, commit again —
  the file is not yet ratified; editing it is the audit working.
- Red PR check: same, on the branch, before merge.
- Red derivation job on `main`: the merge introduced a state the checks
  reject — open a correction cycle; never push fixes directly to
  `main`.
