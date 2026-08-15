# tools/ask.exs — the capture pipeline.
#
#   elixir tools/ask.exs <slug|YYYY-MM-DD-slug.md> "<prompt>"
#
# One operator action in, one schema-complete exchange out, plus its
# sidecar. Division of labor per docs/exchange-schema.md: envelope fields
# are machine-harvested (never model-written); tags/deps are model-
# proposed and tool-validated; bodies are verbatim; the operator reads
# the file (the audit) and commits (the ratification). This tool never
# runs git.
#
# Env knobs:
#   ASK_MODEL            model for the answer call (default: CLI default)
#   ASK_CLASSIFY_MODEL   model for the classifier call (default: haiku)
#   ASK_K                retriever top-k full-text candidates (default 4)
#   ASK_STUB             canned answer envelope file (skips live call 1)
#   ASK_STUB_CLASSIFY    canned classifier envelope file (skips call 2)
#
# T6 note (docs/tripwires.md): this file exceeds one screen deliberately.
# Capture is one job with one seam (the backend adapter); splitting the
# pipeline would put the schema's single writer in two places.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule IJS.Util do
  def die(msg) do
    IO.puts(:stderr, "ask: " <> msg)
    System.halt(1)
  end

  def tmp(tag) do
    Path.join(System.tmp_dir!(), "ijs-#{tag}-#{:erlang.unique_integer([:positive])}")
  end

  def need!(exe) do
    System.find_executable(exe) || die("required executable not found: #{exe}")
  end
end

defmodule IJS.JQ do
  import IJS.Util

  def valid?(file) do
    match?({_, 0}, System.cmd("jq", ["-e", ".", file], stderr_to_stdout: true))
  end

  # jq -r over a file; nil when jq fails or the value is empty/null.
  def raw(file, filter) do
    case System.cmd("jq", ["-r", filter, file], stderr_to_stdout: true) do
      {out, 0} ->
        case String.trim(out) do
          "" -> nil
          "null" -> nil
          s -> s
        end

      _ ->
        nil
    end
  end

  def lines(file, filter) do
    case raw(file, filter) do
      nil -> []
      s -> s |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    end
  end

  def build_sidecar(answer_env, classify_env, shown_path, out_path) do
    base = ["-n", "--slurpfile", "answer", answer_env, "--rawfile", "shown", shown_path]

    {args, prog} =
      if classify_env && valid?(classify_env) do
        {base ++ ["--slurpfile", "classify", classify_env],
         "{answer_envelope: $answer[0], classifier_envelope: $classify[0], shown_list: ($shown | split(\"\\n\") | map(select(length>0)))}"}
      else
        {base,
         "{answer_envelope: $answer[0], classifier_envelope: null, shown_list: ($shown | split(\"\\n\") | map(select(length>0)))}"}
      end

    case System.cmd("jq", args ++ [prog], stderr_to_stdout: true) do
      {out, 0} -> File.write!(out_path, out)
      {err, _} -> IJS.Util.die("sidecar assembly failed: #{String.slice(err, 0, 200)}")
    end
  end
end

defmodule IJS.Backend do
  # Backend contract (docs/backend-contract.md): (prompt, opts) -> raw
  # envelope on disk. No tools are ever enabled on the call. Adapter #1
  # is claude -p; the stub adapter reads a canned envelope from a file.
  import IJS.Util

  def ask(prompt, opts) do
    case opts[:stub] do
      nil -> claude_p(prompt, opts)
      stub_file -> stub(stub_file)
    end
  end

  defp stub(stub_file) do
    File.exists?(stub_file) || die("stub envelope not found: #{stub_file}")
    path = tmp("envelope")
    File.cp!(stub_file, path)
    {:ok, path}
  end

  defp claude_p(prompt, opts) do
    need!("claude")

    # Vendor-specific defaults live here, in the adapter: classifier
    # calls default to the cheap tier when no model is requested.
    model = opts[:model] || if opts[:role] == :classifier, do: "haiku", else: nil

    args =
      ["-p", "--output-format", "json", "--verbose"] ++
        case model do
          nil -> []
          m -> ["--model", m]
        end ++ [prompt]

    # claude exits nonzero on error results but still emits the envelope
    # on stdout; we inspect the envelope rather than the exit code.
    {out, _code} = System.cmd("claude", args, stderr_to_stdout: false)
    path = tmp("envelope")
    File.write!(path, out)
    if String.trim(out) == "", do: {:error, "backend produced no output"}, else: {:ok, path}
  end
end

defmodule IJS.Envelope do
  # Shape-proof harvest: `-p --output-format json` emits one object,
  # adding --verbose emits an array of messages; both normalize first.
  @norm "[if type==\"array\" then .[] else . end]"

  defp q(file, tail), do: IJS.JQ.raw(file, @norm <> " | " <> tail)

  def harvest(file) do
    %{
      result: q(file, "map(select(.type==\"result\"))[0].result // empty"),
      is_error: q(file, "map(select(.type==\"result\"))[0].is_error // false"),
      session_id:
        q(file, "map(select(.type==\"system\" and .subtype==\"init\"))[0].session_id // empty") ||
          q(file, "map(select(.type==\"result\"))[0].session_id // empty"),
      model:
        q(file, "map(select(.type==\"system\" and .subtype==\"init\"))[0].model // empty") ||
          q(file, "(map(select(.type==\"result\"))[0].modelUsage // {}) | keys | .[0] // empty"),
      cwd: q(file, "map(select(.type==\"system\" and .subtype==\"init\"))[0].cwd // empty"),
      cost: q(file, "map(select(.type==\"result\"))[0].total_cost_usd // empty"),
      num_turns: q(file, "map(select(.type==\"result\"))[0].num_turns // empty"),
      denials: q(file, "(map(select(.type==\"result\"))[0].permission_denials // []) | length"),
      tools:
        q(
          file,
          "[.[] | select(.type==\"assistant\") | .message.content[]? | select(.type==\"tool_use\") | .name] | join(\", \")"
        )
    }
  end
end

defmodule IJS.Ledger do
  def files(exclude \\ nil) do
    Path.wildcard("exchanges/*.md")
    |> Enum.reject(&(&1 == exclude))
    |> Enum.sort()
  end

  def next_id do
    max =
      files()
      |> Enum.map(&frontmatter_value(&1, "id"))
      |> Enum.filter(&(&1 && Regex.match?(~r/^\d+$/, &1)))
      |> Enum.map(&String.to_integer/1)
      |> Enum.max(fn -> 0 end)

    max + 1 |> Integer.to_string() |> String.pad_leading(4, "0")
  end

  def frontmatter_value(file, key) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      case String.split(line, ":", parts: 2) do
        [^key, v] -> String.trim(v)
        _ -> nil
      end
    end)
  end

  def first_prompt_line(file) do
    lines = file |> File.read!() |> String.split("\n")
    idx = Enum.find_index(lines, &(&1 == "## Prompt"))

    if idx do
      lines
      |> Enum.drop(idx + 1)
      |> Enum.take_while(&(!String.starts_with?(&1, "## ")))
      |> Enum.find("", fn l ->
        t = String.trim(l)
        t != "" && !String.starts_with?(t, "#")
      end)
      |> String.trim()
    else
      ""
    end
  end
end

defmodule IJS.Retriever do
  @stop ~w(the a an and or but of to in on for with is are was were be been being it its this that these those as at by from into over under about you your i we they he she them his her our what which who whom how why when where do does did done not no yes if then else so than too very just can could should would may might must will shall have has had having there here also)

  def tokens(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, " ")
    |> String.split()
    |> Enum.reject(&(String.length(&1) < 3 || &1 in @stop))
    |> MapSet.new()
  end

  # Deterministic pre-sort: shared-token count, ties by recency (name desc).
  def rank(query_text, candidate_files, k) do
    q = tokens(query_text)

    scored =
      candidate_files
      |> Enum.map(fn f -> {f, MapSet.size(MapSet.intersection(q, tokens(File.read!(f))))} end)

    top =
      scored
      |> Enum.filter(fn {_, s} -> s > 0 end)
      |> Enum.sort_by(fn {f, s} -> {-s, f} end)
      |> Enum.take(k)

    {top, scored}
  end
end

defmodule IJS.Classifier do
  def vocab do
    tax =
      Path.wildcard("taxonomy/**")
      |> Enum.filter(&File.dir?/1)
      |> Enum.map(&String.replace_prefix(&1, "taxonomy/", ""))
      |> Enum.reject(&(&1 == "taxonomy"))

    used =
      IJS.Ledger.files()
      |> Enum.flat_map(fn f ->
        case IJS.Ledger.frontmatter_value(f, "tags") do
          nil -> []
          v -> v |> String.split(",") |> Enum.map(&String.trim/1)
        end
      end)

    (tax ++ used) |> Enum.reject(&(&1 in ["", "UNCLASSIFIED"])) |> Enum.uniq() |> Enum.sort()
  end

  def build_prompt(question, answer, vocab, top, all_scored, target) do
    stub_lines =
      all_scored
      |> Enum.map(fn {f, _} ->
        "#{f} | tags: #{IJS.Ledger.frontmatter_value(f, "tags") || "none"} | prompt: #{IJS.Ledger.first_prompt_line(f)}"
      end)

    full_texts =
      top
      |> Enum.map(fn {f, score} ->
        "----- CANDIDATE (full text, score #{score}): #{f} -----\n" <>
          String.slice(File.read!(f), 0, 3000)
      end)

    """
    You are the classification step of an exchange-capture pipeline.
    Reply with ONLY one JSON object, no code fences, no prose:
    {"tags": ["<taxonomy path>", ...], "deps": ["<repo-relative path>", ...], "reason": "<one sentence>"}
    Rules:
    - tags: 1 to 3 entries. Prefer EXISTING TAGS verbatim; only if none fits, coin a new lowercase slash-path in the same style.
    - deps: zero or more paths chosen ONLY from the candidate exchanges listed below — prior exchanges the new one directly continues. Never invent a path. Never include #{target}.
    - reason: one sentence justifying both.

    EXISTING TAGS:
    #{Enum.join(vocab, "\n")}

    CANDIDATE EXCHANGES (every existing exchange, one line each):
    #{if stub_lines == [], do: "none", else: Enum.join(stub_lines, "\n")}

    TOP CANDIDATES (full text):
    #{if full_texts == [], do: "none", else: Enum.join(full_texts, "\n\n")}

    NEW EXCHANGE PROMPT:
    #{String.slice(question, 0, 600)}

    NEW EXCHANGE RESPONSE (may be truncated):
    #{String.slice(answer, 0, 2000)}
    """
  end

  # -> %{tags:, new_tags:, deps:, dropped:, reason:, cost:, env: path|nil, unusable: bool}
  def run(prompt, vocab, target) do
    opts = %{
      stub: System.get_env("ASK_STUB_CLASSIFY"),
      model: System.get_env("ASK_CLASSIFY_MODEL"),
      role: :classifier
    }

    empty = %{tags: [], new_tags: [], deps: [], dropped: [], reason: nil, cost: nil, cmodel: nil, env: nil, unusable: true}

    case IJS.Backend.ask(prompt, opts) do
      {:error, _} ->
        empty

      {:ok, env} ->
        h = IJS.Envelope.harvest(env)
        text = h.result
        cost = h.cost
        cmodel = h.model

        parsed = parse(text)

        case parsed do
          nil ->
            %{empty | cost: cost, cmodel: cmodel, env: env}

          file ->
            tags = IJS.JQ.lines(file, "(.tags // []) | if type==\"array\" then .[] else . end")
            deps = IJS.JQ.lines(file, "(.deps // []) | if type==\"array\" then .[] else . end")
            reason = IJS.JQ.raw(file, ".reason // empty")

            valid_tags =
              tags
              |> Enum.filter(&Regex.match?(~r{^[a-z0-9][a-z0-9._/-]*$}, &1))
              |> Enum.take(3)

            new_tags = Enum.reject(valid_tags, &(&1 in vocab))

            {kept, dropped} =
              Enum.split_with(deps, fn d ->
                String.starts_with?(d, "exchanges/") && File.exists?(d) && d != target
              end)

            %{
              tags: valid_tags,
              new_tags: new_tags,
              deps: kept,
              dropped: dropped,
              reason: reason,
              cost: cost,
              cmodel: cmodel,
              env: env,
              unusable: valid_tags == []
            }
        end
    end
  end

  # Strip fence lines (models fence JSON despite instructions), then
  # validate as a JSON object; returns a temp file path or nil.
  defp parse(nil), do: nil

  defp parse(text) do
    cleaned =
      text
      |> String.split("\n")
      |> Enum.reject(&Regex.match?(~r/^\s*```/, &1))
      |> Enum.join("\n")

    file = IJS.Util.tmp("classify-json")
    File.write!(file, cleaned)

    if IJS.JQ.valid?(file) && IJS.JQ.raw(file, "if type==\"object\" then \"y\" else empty end"),
      do: file,
      else: nil
  end
end

defmodule IJS.Ask do
  import IJS.Util

  def main(argv) do
    need!("jq")
    File.dir?("exchanges") && File.dir?("docs") || die("run from the itsjustshell2 repo root")

    {name, prompt} =
      case argv do
        [n | rest] when rest != [] -> {n, Enum.join(rest, " ")}
        _ -> die("usage: elixir tools/ask.exs <slug> \"<prompt>\"")
      end

    file_name =
      if String.ends_with?(name, ".md"),
        do: name,
        else: Date.to_iso8601(Date.utc_today()) <> "-" <> name <> ".md"

    Regex.match?(~r/^\d{4}-\d{2}-\d{2}-.+\.md$/, file_name) ||
      die("name must be a slug or YYYY-MM-DD-<slug>.md (got: #{file_name})")

    target = "exchanges/" <> file_name
    sidecar = "exchanges/envelopes/" <> String.replace_suffix(file_name, ".md", ".json")
    File.exists?(target) && die("refusing to overwrite #{target} — exchanges are immutable")

    id = IJS.Ledger.next_id()

    # ---- call 1: the exchange itself ------------------------------------
    opts = %{stub: System.get_env("ASK_STUB"), model: System.get_env("ASK_MODEL")}

    env =
      case IJS.Backend.ask(prompt, opts) do
        {:ok, e} -> e
        {:error, why} -> die(why)
      end

    IJS.JQ.valid?(env) || die("backend output is not JSON (envelope: #{env})")
    h = IJS.Envelope.harvest(env)
    h.is_error == "true" && die("backend returned an error result — nothing filed (envelope: #{env})")
    h.result || die("empty result (envelope: #{env})")

    date = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    # ---- retrieval (deterministic) + classification (proposal) ----------
    k = String.to_integer(System.get_env("ASK_K") || "4")
    candidates = IJS.Ledger.files(target)
    {top, all_scored} = IJS.Retriever.rank(prompt <> " " <> h.result, candidates, k)

    vocab = IJS.Classifier.vocab()
    cprompt = IJS.Classifier.build_prompt(prompt, h.result, vocab, top, all_scored, target)
    c = IJS.Classifier.run(cprompt, vocab, target)

    tags_value = if c.unusable, do: "UNCLASSIFIED", else: Enum.join(c.tags, ", ")

    # ---- shown-list: no silent caps (docs/tripwires.md T3) ---------------
    shown_path = tmp("shown")

    shown_lines =
      ["retriever k=#{k}; full-text shown: #{length(top)} of #{length(candidates)} candidates"] ++
        Enum.map(top, fn {f, s} -> "full: #{f} (score #{s})" end) ++
        Enum.map(all_scored -- top, fn {f, s} -> "stub: #{f} (score #{s})" end)

    File.write!(shown_path, Enum.join(shown_lines, "\n") <> "\n")

    # ---- side effects: a #derived projection of the sidecar -------------
    digest =
      "harness digest: num_turns=#{h.num_turns || "?"}, tools=#{if h.tools in [nil, ""], do: "none", else: h.tools}, permission_denials=#{h.denials || "0"}"

    classifier_note =
      "tags and deps machine-proposed (classifier model: #{c.cmodel || "unreported"}" <>
        if(c.cost, do: ", cost_usd: #{c.cost}", else: "") <>
        ")" <> if(c.reason, do: " — reason: #{c.reason}", else: "")

    side_effects =
      ["created persistent record (this document)", digest, classifier_note] ++
        ["retriever: full text shown for #{length(top)} of #{length(candidates)} candidates (shown_list in sidecar)"] ++
        if(c.new_tags != [], do: ["NEW tag not yet in taxonomy: #{Enum.join(c.new_tags, ", ")} — audit before commit"], else: []) ++
        if(c.dropped != [], do: ["classifier proposed invalid deps (dropped): #{Enum.join(c.dropped, ", ")}"], else: []) ++
        if(c.unusable, do: ["classifier output unusable — tags left UNCLASSIFIED; set by hand before commit"], else: [])

    # ---- write the exchange + sidecar ------------------------------------
    content = """
    ---
    id: #{id}
    session_id: #{h.session_id || ""}
    date: #{date}
    model: #{h.model || ""}
    cost_usd: #{h.cost || ""}
    cwd: #{h.cwd || File.cwd!()}
    role: respondent
    tags: #{tags_value}
    deps: #{Enum.join(c.deps, ", ")}
    ---

    ## Prompt
    #human-authored

    #{prompt}

    ## Response
    #agent-authored

    #{h.result}

    ## Side Effects
    #derived

    #{Enum.join(side_effects, "\n")}
    """

    File.mkdir_p!("exchanges/envelopes")
    File.write!(target, content)
    IJS.JQ.build_sidecar(env, c.env, shown_path, sidecar)

    # Mechanical tail: refresh the derived views so the commit lands with
    # views current — check_views enforces exactly this at the hook.
    System.cmd("elixir", ["tools/derive_indexes.exs"], stderr_to_stdout: true)
    System.cmd("elixir", ["tools/derive_threads.exs"], stderr_to_stdout: true)
    IO.puts("derived views refreshed (indexes, threads)")

    IO.puts("wrote #{target}")
    IO.puts("      #{sidecar}")
    IO.puts("  id: #{id} | tags: #{tags_value}#{if c.new_tags != [], do: " (NEW)", else: ""} | deps: #{if c.deps == [], do: "<blank>", else: Enum.join(c.deps, ", ")}")
    IO.puts("  answer cost_usd: #{h.cost || "?"}")
    IO.puts("review the file, then commit it yourself:")
    IO.puts("  git add -A && git commit   # -A: the refreshed derived views belong in the same commit")
  end
end

IJS.Ask.main(System.argv())
