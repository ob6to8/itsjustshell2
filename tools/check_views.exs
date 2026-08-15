# tools/check_views.exs — arms the derivation direction (INV-2, views
# half): every #derived view must equal its own regeneration from the
# ledger. Regenerates indexes and threads in a temp copy and diffs
# against the committed views. A mismatch means a view is stale or was
# edited by hand — either way, what-is-known has drifted from what
# happened. Exit 0 silent when reproducible; diff printed, exit 1
# otherwise.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule CheckViews do
  def main do
    File.dir?("taxonomy") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    tmp = Path.join(System.tmp_dir!(), "ijs-views-#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    for dir <- ["exchanges", "taxonomy", "threads"], File.dir?(dir) do
      {_, 0} = System.cmd("cp", ["-r", dir, Path.join(tmp, dir)])
    end

    tools = Path.expand("tools")

    for deriver <- ["derive_indexes.exs", "derive_threads.exs"] do
      {out, code} =
        System.cmd("elixir", [Path.join(tools, deriver)], cd: tmp, stderr_to_stdout: true)

      if code != 0 do
        IO.puts("check_views: #{deriver} failed in regeneration sandbox:\n#{out}")
        System.halt(1)
      end
    end

    failures =
      for dir <- ["taxonomy", "threads"],
          File.dir?(dir) or File.dir?(Path.join(tmp, dir)),
          reduce: [] do
        acc ->
          File.mkdir_p!(dir)
          File.mkdir_p!(Path.join(tmp, dir))
          {out, code} = System.cmd("diff", ["-r", "-N", dir, Path.join(tmp, dir)])
          if code == 0, do: acc, else: acc ++ ["check_views: #{dir}/ differs from its regeneration:\n#{out}"]
      end

    File.rm_rf!(tmp)

    if failures == [] do
      System.halt(0)
    else
      Enum.each(failures, &IO.puts/1)
      System.halt(1)
    end
  end
end

CheckViews.main()
