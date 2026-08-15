# tools/check_authorship.exs — arms INV-4 (marker presence).
# Every markdown file outside exchanges/ carries exactly one authorship
# marker line (#human-authored | #agent-authored | #derived) within its
# first 15 lines. Exchange files are composite and are checked by
# check_exchanges.exs instead. Exit 0 silent when healthy; offending
# paths printed, exit 1 otherwise.
#
# #agent-authored — provenance: exchanges/2026-08-15-bootstrap-thread.md

defmodule CheckAuthorship do
  @marker ~r/^#(human-authored|agent-authored|derived)$/

  def main do
    File.dir?("docs") || (IO.puts(:stderr, "run from the repo root") && System.halt(1))

    offenders =
      Path.wildcard("**/*.md")
      |> Enum.reject(&String.starts_with?(&1, "exchanges/"))
      |> Enum.reject(&String.contains?(&1, ".git/"))
      |> Enum.filter(fn f ->
        count =
          f
          |> File.read!()
          |> String.split("\n")
          |> Enum.take(15)
          |> Enum.count(&Regex.match?(@marker, String.trim(&1)))

        count != 1
      end)

    if offenders == [] do
      System.halt(0)
    else
      Enum.each(offenders, &IO.puts("check_authorship: missing or multiple markers: #{&1}"))
      System.halt(1)
    end
  end
end

CheckAuthorship.main()
