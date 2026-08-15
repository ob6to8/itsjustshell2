# test/prop_checks.exs — the property loop over the schema checks.
# Operator-only zone: agents never write in test/.
#
# Property: a randomly assembled VALID exchange passes every check; a
# valid exchange with one random mutation applied is caught by the check
# that owns the violated invariant. ~15 rounds. Generated files are
# removed after each round; on failure the offending content is printed.
#
# Run from the repo root:  elixir test/prop_checks.exs
#
# #human-authored (seeded at bootstrap for the operator to own and grow)

defmodule PropChecks do
  @words ~w(banana ledger fence marker thread capture taxonomy invariant sidecar audit)

  def main do
    File.dir?("exchanges") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))
    existing = Path.wildcard("exchanges/*.md") |> List.first()

    rounds = 15

    Enum.each(1..rounds, fn i ->
      slug = "prop-#{Enum.random(@words)}-#{:erlang.unique_integer([:positive])}"
      file = "exchanges/#{Date.to_iso8601(Date.utc_today())}-#{slug}.md"
      valid = valid_exchange(existing)

      # healthy: all checks pass
      File.write!(file, valid)
      assert_all_pass(file, valid)

      # mutated: the owning check fails
      {label, mutant, owner} = mutate(valid)
      File.write!(file, mutant)
      {_out, code} = run(owner)

      if code == 0 do
        IO.puts("FAIL round #{i}: mutation #{label} not caught by #{owner}")
        IO.puts("--- mutant content ---\n#{mutant}")
        File.rm(file)
        System.halt(1)
      end

      File.rm!(file)
    end)

    IO.puts("prop_checks: PASS (#{rounds} rounds, healthy + 1 mutation each)")
  end

  defp assert_all_pass(file, content) do
    Enum.each(
      ["tools/check_exchanges.exs", "tools/check_deps.exs", "tools/check_authorship.exs"],
      fn check ->
        {out, code} = run(check)

        if code != 0 do
          IO.puts("FAIL: valid exchange rejected by #{check}\n#{out}")
          IO.puts("--- content ---\n#{content}")
          File.rm(file)
          System.halt(1)
        end
      end
    )
  end

  defp run(script), do: System.cmd("elixir", [script], stderr_to_stdout: true)

  defp valid_exchange(existing_dep) do
    deps = if existing_dep && Enum.random([true, false]), do: existing_dep, else: ""

    """
    ---
    id: #{Enum.random(1..9999) |> Integer.to_string() |> String.pad_leading(4, "0")}
    session_id: #{Enum.random(100_000..999_999)}-stub
    date: #{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}
    model: claude-opus-5
    cost_usd: 0.0#{Enum.random(100..999)}
    cwd: /tmp/prop
    role: respondent
    tags: #{Enum.random(["shell", "elixir", "pipeline/capture"])}
    deps: #{deps}
    ---

    ## Prompt
    #human-authored

    What is a #{Enum.random(@words)}?

    ## Response
    #agent-authored

    A #{Enum.random(@words)} of the #{Enum.random(@words)} kind.

    ## Side Effects
    #derived

    created persistent record (this document)
    """
  end

  defp mutate(valid) do
    Enum.random([
      {"drop a frontmatter key", String.replace(valid, ~r/^model: .*\n/m, "", global: false),
       "tools/check_exchanges.exs"},
      {"insert an undeclared key",
       String.replace(valid, "role: respondent\n", "role: respondent\nlayer: L4\n", global: false),
       "tools/check_exchanges.exs"},
      {"fence not at byte zero", "2026-01-01-label-line.md\n" <> valid,
       "tools/check_exchanges.exs"},
      {"drop a section",
       String.replace(valid, "## Side Effects\n#derived\n", "", global: false),
       "tools/check_exchanges.exs"},
      {"wrong marker under Response",
       String.replace(valid, "## Response\n#agent-authored", "## Response\n#human-authored",
         global: false
       ), "tools/check_exchanges.exs"},
      {"nonexistent dep",
       String.replace(valid, ~r/^deps: .*$/m, "deps: exchanges/9999-99-99-nope.md",
         global: false
       ), "tools/check_deps.exs"}
    ])
  end
end

PropChecks.main()
