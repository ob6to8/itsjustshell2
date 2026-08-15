# tools/derive_indexes.exs — materializes tag facets as taxonomy leaf
# indexes. For every leaf directory of taxonomy/, rewrites index.md with
# links (never copies) to each exchange carrying that tag. #derived,
# regenerated wholesale.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule DeriveIndexes do
  def main do
    File.dir?("taxonomy") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    dirs = Path.wildcard("taxonomy/**") |> Enum.filter(&File.dir?/1)
    leaves = Enum.filter(dirs, fn d -> !Enum.any?(dirs, &String.starts_with?(&1, d <> "/")) end)

    exchanges = Path.wildcard("exchanges/*.md") |> Enum.sort()

    Enum.each(leaves, fn leaf ->
      tag = String.replace_prefix(leaf, "taxonomy/", "")

      records =
        Enum.filter(exchanges, fn f ->
          f |> tags_value() |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.member?(tag)
        end)

      listing =
        if records == [],
          do: ["No records tagged `#{tag}` yet."],
          else: Enum.map(records, fn f -> "- #{f} — #{first_prompt_line(f)}" end)

      body =
        [
          "# Index: #{tag}",
          "",
          "#derived",
          "Regenerate via `elixir tools/derive_indexes.exs` — do not hand-edit.",
          ""
        ] ++ listing

      File.write!(Path.join(leaf, "index.md"), Enum.join(body, "\n") <> "\n")
    end)

    IO.puts("derive_indexes: rewrote #{length(leaves)} leaf indexes")
  end

  defp tags_value(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_value("", fn line ->
      case String.split(line, ":", parts: 2) do
        ["tags", v] -> String.trim(v)
        _ -> nil
      end
    end)
  end

  defp first_prompt_line(file) do
    lines = file |> File.read!() |> String.split("\n")

    case Enum.find_index(lines, &(&1 == "## Prompt")) do
      nil ->
        ""

      idx ->
        lines
        |> Enum.drop(idx + 1)
        |> Enum.take_while(&(!String.starts_with?(&1, "## ")))
        |> Enum.find("", fn l ->
          t = String.trim(l)
          t != "" && !String.starts_with?(t, "#")
        end)
        |> String.trim()
    end
  end
end

DeriveIndexes.main()
