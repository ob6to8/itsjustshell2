# tools/check_all.exs — runs every check; fails if any fails.
# The pre-commit hook execs this (tools/hooks/pre-commit).
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule CheckAll do
  @checks [
    "tools/check_authorship.exs",
    "tools/check_exchanges.exs",
    "tools/check_deps.exs",
    "tools/check_views.exs"
  ]

  def main do
    results =
      Enum.map(@checks, fn script ->
        {out, code} = System.cmd("elixir", [script], stderr_to_stdout: true)
        if String.trim(out) != "", do: IO.write(out)
        {script, code}
      end)

    if Enum.all?(results, fn {_, code} -> code == 0 end) do
      System.halt(0)
    else
      failed = for {s, c} <- results, c != 0, do: s
      IO.puts("check_all: FAILED: #{Enum.join(failed, ", ")}")
      System.halt(1)
    end
  end
end

CheckAll.main()
