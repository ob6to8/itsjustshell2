# tools/check_deps.exs — arms INV-3 (deps resolve).
# Every path in every exchange's deps: line resolves to an existing file.
# Exit 0 silent when healthy; "file: missing dep" printed, exit 1
# otherwise.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule CheckDeps do
  def main do
    File.dir?("exchanges") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    failures =
      Path.wildcard("exchanges/*.md")
      |> Enum.flat_map(fn f ->
        f
        |> deps_value()
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.reject(&File.exists?/1)
        |> Enum.map(&"check_deps: #{f}: missing dep: #{&1}")
      end)

    if failures == [] do
      System.halt(0)
    else
      Enum.each(failures, &IO.puts/1)
      System.halt(1)
    end
  end

  defp deps_value(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_value("", fn line ->
      case String.split(line, ":", parts: 2) do
        ["deps", v] -> String.trim(v)
        _ -> nil
      end
    end)
  end
end

CheckDeps.main()
