---
session_id: 8fca39b7-4d8b-491c-9c63-20234a682ca9
date: 2026-08-16T08:05:49Z
model: claude-sonnet-5
cost_usd: 0.1870683
cwd: /Users/mark/dev/repos/itsjustshell2
role: respondent
tags: elixir, pipeline/capture
deps: exchanges/2026-08-15-bootstrap-thread.md
---

## Prompt
#human-authored

is it currently possible to set the model when running elixir tools/ask.exs, such as when passing --model claude-fable-5 to claude -p? if not, what would it look like to add this functionality?

## Response
#agent-authored

Yes — but only via an env var, not a CLI flag. `ASK_MODEL` is read at tools/ask.exs:393 and threaded through to the `claude -p ... --model <m>` call in `IJS.Backend.claude_p` (tools/ask.exs:113,117-119). So:

```
ASK_MODEL=claude-fable-5 elixir tools/ask.exs my-slug "prompt"
```

does exactly what `--model claude-fable-5` does on `claude -p` directly.

There's no `--model` flag on `ask.exs` itself — `main/1` only parses `[name | rest]` (tools/ask.exs:374-378) and treats everything after the slug as the prompt, so any `--model` flag would just get swallowed into the prompt text.

**What adding a real `--model` flag would look like:**

1. In `IJS.Ask.main/1`, before treating `argv` as `[name | rest]`, extract `--model <value>` (and maybe `--classify-model <value>`) from anywhere in argv — e.g. via `OptionParser.parse(argv, strict: [model: :string, classify_model: :string])`, then treat `OptionParser.parse`'s remaining args as `[name | prompt_words]`.
2. Pass the parsed value into `opts` at line 393 (`%{stub: ..., model: parsed[:model] || System.get_env("ASK_MODEL")}`), and similarly for the classifier call at line 291-295 with `ASK_CLASSIFY_MODEL`.
3. Decide precedence: flag overrides env var, or vice versa — worth stating explicitly in the header comment (lines 12-17) since that's the existing documented contract.
4. Update the usage string (line 377) and the file-header doc comment to mention the new flag.

Small change, contained entirely to `IJS.Ask.main/1` — `IJS.Backend` already accepts `opts[:model]` and needs no changes.

## Side Effects
#derived

created persistent record (this document)
harness digest: num_turns=3, tools=Bash, Read, permission_denials=0
tags and deps machine-proposed (classifier model: claude-haiku-4-5-20251001, cost_usd: 0.0361011) — reason: Technical implementation of ask.exs for capturing exchanges in the pipeline; extends the exchange workflow infrastructure from the bootstrap thread.
retriever: full text shown for 4 of 4 candidates (shown_list in sidecar)
