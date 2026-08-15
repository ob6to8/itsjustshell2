# Roles and the capability dial

#agent-authored
Provenance: [../exchanges/2026-08-15-bootstrap-thread.md](../exchanges/2026-08-15-bootstrap-thread.md)
Terms: [capability dial](glossary.md#capability-dial) · [respondent](glossary.md#respondent) · [planner](glossary.md#planner) · [generator](glossary.md#generator) · [classifier](glossary.md#classifier) · [verifier](glossary.md#verifier) · [executor](glossary.md#executor) · [sidecar](glossary.md#sidecar)

## Binding invariants, all modes

1. **No agent ever commits.** The commit is the operator's ratification
   gate.
2. **All effects land in a git working tree** — the diff is complete
   evidence of change.
3. **Forbidden zones** are enforced mechanically at commit, not by
   memory. Zones: `test/` (acceptance home, operator-only),
   `exchanges/` (immutable; only the capture tool writes there, and only
   new files).
4. **Every run persists its sidecar.**
5. **Least capability per task**: a role is granted the minimum the task
   needs. Audit cost scales with capability; verification (checks +
   operator commit) is identical in every mode and never skipped.

## The dial, low to high

| mode | tools | what comes back | audit surface |
|---|---|---|---|
| pure function | none | text/data | the content itself |
| fenced return | none | one artifact as a fenced block; a deterministic tool installs it | the artifact, against its contract and acceptance |
| workspace executor | read/write in the tree | a diff | diff + sidecar + checks |

Read-only tool calls are permitted in any mode; they change nothing and
create no verification debt.

## The roles

| `role:` | mode | returns | notes |
|---|---|---|---|
| `respondent` | pure function | an answer | the default; call 1 of every capture |
| `classifier` | pure function | metadata proposal (tags, deps, reason) as JSON | validated by the capture tool; proposal, not authority |
| `verifier` | pure function (+ read-only) | findings | never edits; reviews are shaped for refutation, see [methods.md](methods.md) |
| `planner` | pure function (+ read-only) | a plan artifact | a plan with open questions is not executable — the gate is mechanical (exit-code check), not social |
| `generator` | fenced return | one artifact against a contract + acceptance test | least-privilege authoring; installation is mechanical |
| `executor` | workspace executor | a diff | for multi-file work; cannot commit; diff + sidecar + checks are the audit |
| `bootstrap` | (exception) | — | marks the init exchange only; never used again |

The operator performs no mechanical work in steady state: tools extract,
place, stage; the operator judges and commits. Escalating a task beyond
the working tree (network, system state) requires an explicit per-task
operator grant — see [tripwires.md](tripwires.md).
