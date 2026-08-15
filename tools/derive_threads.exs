# tools/derive_threads.exs — materializes the deps graph as thread views.
# A thread is the chain reachable by following first-listed deps up to a
# root. Output: threads/thread-<root-slug>.md, #derived, links only —
# regenerated wholesale on every run (stale thread files for vanished
# roots are removed).
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule DeriveThreads do
  def main do
    File.dir?("exchanges") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    exchanges = Path.wildcard("exchanges/*.md") |> Enum.sort()
    parents = Map.new(exchanges, fn f -> {f, first_dep(f)} end)

    children =
      Enum.reduce(parents, %{}, fn
        {_child, nil}, acc -> acc
        {child, parent}, acc -> Map.update(acc, parent, [child], &(&1 ++ [child]))
      end)

    roots =
      exchanges
      |> Enum.filter(fn f -> parents[f] == nil && Map.has_key?(children, f) end)

    File.mkdir_p!("threads")
    Path.wildcard("threads/thread-*.md") |> Enum.each(&File.rm!/1)

    if roots == [] do
      IO.puts("derive_threads: no deps chains yet; nothing to derive")
    else
      Enum.each(roots, fn root ->
        chain = walk(root, children)
        slug = root |> Path.basename(".md") |> String.slice(11..-1//1)

        body =
          [
            "# Thread: #{slug}",
            "",
            "#derived",
            "Regenerate via `elixir tools/derive_threads.exs` — do not hand-edit.",
            ""
          ] ++ Enum.map(chain, fn {f, depth} -> String.duplicate("  ", depth) <> "- #{f}" end)

        File.write!("threads/thread-#{slug}.md", Enum.join(body, "\n") <> "\n")
        IO.puts("derive_threads: wrote threads/thread-#{slug}.md (#{length(chain)} records)")
      end)
    end
  end

  defp walk(node, children, depth \\ 0) do
    [{node, depth}] ++
      (children |> Map.get(node, []) |> Enum.flat_map(&walk(&1, children, depth + 1)))
  end

  defp first_dep(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      case String.split(line, ":", parts: 2) do
        ["deps", v] ->
          v |> String.split(",") |> List.first() |> String.trim() |> case do
            "" -> nil
            dep -> dep
          end

        _ ->
          nil
      end
    end)
  end
end

DeriveThreads.main()
