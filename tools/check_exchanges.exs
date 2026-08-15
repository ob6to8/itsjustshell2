# tools/check_exchanges.exs — arms INV-1 (schema completeness).
# Every exchanges/*.md: frontmatter fence at byte zero, exactly the nine
# keys in schema order (extra keys fail too — that arms tripwire T5),
# the three sections in order, each followed by its marker as the next
# non-empty line. Exit 0 silent when healthy; offending path + reason,
# exit 1 otherwise.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule CheckExchanges do
  @keys ~w(session_id date model cost_usd cwd role tags deps)
  @sections [
    {"## Prompt", "#human-authored"},
    {"## Response", "#agent-authored"},
    {"## Side Effects", "#derived"}
  ]

  def main do
    File.dir?("exchanges") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    failures =
      Path.wildcard("exchanges/*.md")
      |> Enum.flat_map(fn f -> Enum.map(problems(f), &"check_exchanges: #{f}: #{&1}") end)

    if failures == [] do
      System.halt(0)
    else
      Enum.each(failures, &IO.puts/1)
      System.halt(1)
    end
  end

  defp problems(file) do
    lines = file |> File.read!() |> String.split("\n")

    fence_problems =
      case lines do
        ["---" | rest] ->
          case Enum.find_index(rest, &(&1 == "---")) do
            nil ->
              ["frontmatter fence never closes"]

            close ->
              keys =
                rest
                |> Enum.take(close)
                |> Enum.map(fn l -> l |> String.split(":", parts: 2) |> hd() end)

              if keys == @keys,
                do: [],
                else: ["frontmatter keys must be exactly #{Enum.join(@keys, ", ")} in order (got: #{Enum.join(keys, ", ")})"]
          end

        _ ->
          ["frontmatter fence not at byte zero"]
      end

    fence_problems ++ section_problems(lines)
  end

  defp section_problems(lines) do
    {problems, cursor} =
      Enum.reduce(@sections, {[], 0}, fn {header, marker}, {probs, from} ->
        case find_from(lines, header, from) do
          nil ->
            {probs ++ ["missing section: #{header}"], from}

          idx ->
            next =
              lines
              |> Enum.drop(idx + 1)
              |> Enum.find(&(String.trim(&1) != ""))

            if next == marker,
              do: {probs, idx + 1},
              else: {probs ++ ["#{header} must be followed by #{marker}"], idx + 1}
        end
      end)

    _ = cursor
    problems
  end

  defp find_from(lines, value, from) do
    lines
    |> Enum.drop(from)
    |> Enum.find_index(&(&1 == value))
    |> case do
      nil -> nil
      i -> i + from
    end
  end
end

CheckExchanges.main()
