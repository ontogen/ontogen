defmodule Ontogen.Changeset.FormatterTest do
  use OntogenCase

  doctest Ontogen.Changeset.Formatter

  alias Ontogen.Changeset.Formatter
  alias Ontogen.Commit

  describe "short_stat" do
    test "commit" do
      assert Formatter.format(commit(), :short_stat) ==
               " 3 resources changed, 3 insertions(+), 1 deletions(-)"

      assert Formatter.format(commit(changeset: [overwrite: graph()]), :short_stat) ==
               " 2 resources changed, 3 overwrites(~)"
    end

    test "speech act" do
      assert Formatter.format(speech_act(), :short_stat) ==
               " 2 resources changed, 3 insertions(+)"
    end

    test "changeset" do
      assert Formatter.format(commit_changeset(), :short_stat) ==
               " 3 resources changed, 3 insertions(+), 1 deletions(-)"

      assert Formatter.format(speech_act_changeset(), :short_stat) ==
               " 3 resources changed, 3 insertions(+), 1 deletions(-)"
    end

    test "revert commit" do
      assert Formatter.format(revert(), :short_stat) ==
               " 3 resources changed, 3 insertions(+), 1 deletions(-)"
    end
  end

  describe "resource_only" do
    test "commit" do
      assert Formatter.format(commit(), :resource_only) ==
               """
               http://example.com/Foo
               http://example.com/S1
               http://example.com/S2
               """
               |> String.trim_trailing()
    end

    test "speech act" do
      assert Formatter.format(speech_act(), :resource_only) ==
               """
               http://example.com/S1
               http://example.com/S2
               """
               |> String.trim_trailing()
    end

    test "changeset" do
      assert Formatter.format(commit_changeset(), :resource_only) ==
               """
               http://example.com/Foo
               http://example.com/S1
               http://example.com/S2
               """
               |> String.trim_trailing()

      assert Formatter.format(speech_act_changeset(), :resource_only) ==
               """
               http://example.com/Foo
               http://example.com/S1
               http://example.com/S2
               """
               |> String.trim_trailing()
    end
  end

  describe "stat" do
    test "commit" do
      assert Formatter.format(commit(), :stat) ==
               """
                http://example.com/Foo | 1 \e[32m\e[0m\e[31m-\e[0m\e[91m\e[0m
                http://example.com/S1  | 1 \e[32m+\e[0m\e[31m\e[0m\e[91m\e[0m
                http://example.com/S2  | 2 \e[32m++\e[0m\e[31m\e[0m\e[91m\e[0m
                3 resources changed, 3 insertions(+), 1 deletions(-)
               """
               |> String.trim_trailing()
    end

    test "speech act" do
      assert Formatter.format(speech_act(), :stat) ==
               """
                http://example.com/S1 | 1 \e[32m+\e[0m\e[31m\e[0m\e[91m\e[0m
                http://example.com/S2 | 2 \e[32m++\e[0m\e[31m\e[0m\e[91m\e[0m
                2 resources changed, 3 insertions(+)
               """
               |> String.trim_trailing()
    end

    test "changeset" do
      assert Formatter.format(commit_changeset(), :stat, color: false) ==
               """
                http://example.com/Foo | 1 -
                http://example.com/S1  | 1 +
                http://example.com/S2  | 2 ++
                3 resources changed, 3 insertions(+), 1 deletions(-)
               """
               |> String.trim_trailing()

      assert Formatter.format(speech_act_changeset(), :stat, color: false) ==
               """
                http://example.com/Foo | 1 -
                http://example.com/S1  | 1 +
                http://example.com/S2  | 2 ++
                3 resources changed, 3 insertions(+), 1 deletions(-)
               """
               |> String.trim_trailing()
    end

    test "lines are never wrapped" do
      large_commit =
        commit(
          add: 1..3 |> Enum.to_list() |> graph(),
          update: 1..100 |> Enum.map(&{10, &1}) |> graph()
        )

      #      IO.puts("\n" <> Formatter.format(large_commit, :stat))

      assert_no_line_wrap(Formatter.format(large_commit, :stat, color: false))

      large_resource =
        commit(
          add:
            graph([
              {"http://example.com/#{String.duplicate("very", terminal_width())}long", EX.P, EX.O}
            ]),
          remove: 1..100 |> Enum.map(&{10, &1}) |> graph()
        )

      #      IO.puts("\n" <> Formatter.format(large_resource, :stat))

      assert_no_line_wrap(Formatter.format(large_resource, :stat, color: false))
    end
  end

  describe "changes" do
    test "commit" do
      assert commit(
               add: statement(1),
               update: statements([2, {1, 2}]),
               replace: statement(3),
               remove: statement(4),
               overwrite: statement(5)
             )
             |> Formatter.format(:changes) ==
               """
               \e[0m  <http://example.com/s1>
               \e[32m+     <http://example.com/p1> <http://example.com/o1> ;
               \e[36m±     <http://example.com/p2> <http://example.com/o2> .

               \e[0m  <http://example.com/s2>
               \e[36m±     <http://example.com/p2> <http://example.com/o2> .

               \e[0m  <http://example.com/s3>
               \e[96m⨦     <http://example.com/p3> <http://example.com/o3> .

               \e[0m  <http://example.com/s4>
               \e[31m-     <http://example.com/p4> <http://example.com/o4> .

               \e[0m  <http://example.com/s5>
               \e[91m~     <http://example.com/p5> <http://example.com/o5> .
               \e[0m
               """
               |> String.trim_trailing()
    end

    test "speech act" do
      assert speech_act(
               add: statement(1),
               update: statements([2, {1, 2}]),
               replace: statement(3),
               remove: statement(4)
             )
             |> Formatter.format(:changes, color: false) ==
               """
                 <http://example.com/s1>
               +     <http://example.com/p1> <http://example.com/o1> ;
               ±     <http://example.com/p2> <http://example.com/o2> .

                 <http://example.com/s2>
               ±     <http://example.com/p2> <http://example.com/o2> .

                 <http://example.com/s3>
               ⨦     <http://example.com/p3> <http://example.com/o3> .

                 <http://example.com/s4>
               -     <http://example.com/p4> <http://example.com/o4> .
               """
    end

    test "changeset" do
      assert speech_act_changeset(
               add: statement(1),
               update: statements([2, {1, 2}]),
               replace: statement(3),
               remove: statement(4)
             )
             |> Formatter.format(:changes) ==
               """
               \e[0m  <http://example.com/s1>
               \e[32m+     <http://example.com/p1> <http://example.com/o1> ;
               \e[36m±     <http://example.com/p2> <http://example.com/o2> .

               \e[0m  <http://example.com/s2>
               \e[36m±     <http://example.com/p2> <http://example.com/o2> .

               \e[0m  <http://example.com/s3>
               \e[96m⨦     <http://example.com/p3> <http://example.com/o3> .

               \e[0m  <http://example.com/s4>
               \e[31m-     <http://example.com/p4> <http://example.com/o4> .
               \e[0m
               """
               |> String.trim_trailing()

      assert Commit.Changeset.new!(
               add: graph([1]),
               update: graph([2, {1, 2}], prefixes: [ex: EX]),
               overwrite: graph([{2, 1}])
             )
             |> Formatter.format(:changes, color: false) ==
               """
               @prefix ex: <http://example.com/> .

                 ex:s1
               +     ex:p1 ex:o1 ;
               ±     ex:p2 ex:o2 .

                 ex:s2
               ~     ex:p1 ex:o1 ;
               ±     ex:p2 ex:o2 .
               """
    end

    test ":context_data opt" do
      assert Commit.Changeset.new!(
               add: graph([1]),
               update: graph([2, {1, 2}], prefixes: [ex: EX]),
               overwrite: graph([{2, 1}])
             )
             |> Formatter.format(:changes,
               context_data: [
                 statement({1, 3}),
                 statement(3)
               ]
             ) ==
               """
               @prefix ex: <http://example.com/> .

               \e[0m  ex:s1
               \e[32m+     ex:p1 ex:o1 ;
               \e[36m±     ex:p2 ex:o2 ;
               \e[0m      ex:p3 ex:o3 .

               \e[0m  ex:s2
               \e[91m~     ex:p1 ex:o1 ;
               \e[36m±     ex:p2 ex:o2 .

               \e[0m  ex:s3
               \e[0m      ex:p3 ex:o3 .
               \e[0m
               """
               |> String.trim_trailing()
    end
  end

  describe "speech_changes" do
    test "commit" do
      assert Formatter.format(commit(), :speech_changes, color: false) ==
               """
                 <http://example.com/Foo>
               -     <http://example.com/bar> 42 .

                 <http://example.com/S1>
               +     <http://example.com/p1> <http://example.com/O1> .

                 <http://example.com/S2>
               +     <http://example.com/p2> 42 ;
               +     <http://example.com/p2> "Foo" .
               """
    end

    test "revert" do
      assert Formatter.format(revert(), :speech_changes) ==
               "# Revert without speech act"
    end

    test "other change struct fail" do
      assert_raise ArgumentError, fn ->
        Formatter.format(speech_act(), :speech_changes)
      end

      assert_raise ArgumentError, fn ->
        Formatter.format(speech_act_changeset(), :speech_changes, color: false)
      end

      assert_raise ArgumentError, fn ->
        Formatter.format(commit_changeset(), :speech_changes)
      end
    end
  end

  describe "combined_changes" do
    test "commit" do
      commit =
        commit(
          add: graph([1], prefixes: [ex: EX]),
          replace: graph([3]),
          remove: graph([4]),
          overwrite: graph([{3, 1}]),
          speech_act:
            speech_act(
              add: graph([1, 11], prefixes: [ex: EX]),
              update: graph([2]),
              replace: graph([3]),
              remove: graph([{4, 44}])
            )
        )

      assert Formatter.format(commit, :combined_changes) ==
               """
               \e[0m   <http://example.com/s1>
               \e[0m \e[32m+     <http://example.com/p1> <http://example.com/o1> .

               \e[0m\e[37m\e[2m#  \e[9m<http://example.com/s11>
               \e[0m\e[37m\e[2m#\e[32m+ \e[9m    <http://example.com/p11> <http://example.com/o11> .

               \e[0m\e[37m\e[2m#  \e[9m<http://example.com/s2>
               \e[0m\e[37m\e[2m#\e[36m± \e[9m    <http://example.com/p2> <http://example.com/o2> .

               \e[0m   <http://example.com/s3>
               \e[0m \e[91m~     <http://example.com/p1> <http://example.com/o1> ;
               \e[0m \e[96m⨦     <http://example.com/p3> <http://example.com/o3> .

               \e[0m   <http://example.com/s4>
               \e[0m \e[31m-     <http://example.com/p4> <http://example.com/o4> ;
               \e[0m\e[37m\e[2m#\e[31m- \e[9m    <http://example.com/p44> <http://example.com/o44> .
               \e[0m
               """
               |> String.trim_trailing()

      commit =
        commit(
          add: graph([{2, 3}, 3]),
          speech_act: speech_act(add: graph([2, {2, 3}, 3]))
        )

      assert Formatter.format(commit, :combined_changes,
               color: true,
               context_data: graph([2, {2, 1}])
             ) ==
               """
               \e[0m   <http://example.com/s2>
               \e[0m       <http://example.com/p1> <http://example.com/o1> ;
               \e[0m\e[37m\e[2m#\e[32m+ \e[9m    <http://example.com/p2> <http://example.com/o2> ;
               \e[0m \e[32m+     <http://example.com/p3> <http://example.com/o3> .

               \e[0m   <http://example.com/s3>
               \e[0m \e[32m+     <http://example.com/p3> <http://example.com/o3> .
               \e[0m
               """
               |> String.trim_trailing()
    end

    test ":context_data opt" do
      commit =
        commit(
          add: graph([1], prefixes: [ex: EX]),
          replace: graph([3]),
          remove: graph([4]),
          overwrite: graph([{3, 1}]),
          speech_act:
            speech_act(
              add: graph([1, 11], prefixes: [ex: EX]),
              update: graph([2]),
              replace: graph([3]),
              remove: graph([{4, 44}])
            )
        )

      assert Formatter.format(commit, :combined_changes,
               color: false,
               context_data: graph([11, {11, 2}, {3, 1}, 4, 5])
             ) ==
               """
                  <http://example.com/s1>
                +     <http://example.com/p1> <http://example.com/o1> .

               #  <http://example.com/s11>
               #+     <http://example.com/p11> <http://example.com/o11> ;
                      <http://example.com/p2> <http://example.com/o2> .

               #  <http://example.com/s2>
               #±     <http://example.com/p2> <http://example.com/o2> .

                  <http://example.com/s3>
                ~     <http://example.com/p1> <http://example.com/o1> ;
                ⨦     <http://example.com/p3> <http://example.com/o3> .

                  <http://example.com/s4>
                -     <http://example.com/p4> <http://example.com/o4> ;
               #-     <http://example.com/p44> <http://example.com/o44> .

                  <http://example.com/s5>
                      <http://example.com/p5> <http://example.com/o5> .
               """
    end

    test "revert" do
      assert Formatter.format(revert(), :combined_changes, color: false) ==
               """
                 <http://example.com/Foo>
               -     <http://example.com/bar> 42 .

                 <http://example.com/S1>
               +     <http://example.com/p1> <http://example.com/O1> .

                 <http://example.com/S2>
               +     <http://example.com/p2> 42 ;
               +     <http://example.com/p2> "Foo" .
               """
    end

    test "other change struct fail" do
      assert_raise ArgumentError, fn ->
        Formatter.format(speech_act(), :combined_changes)
      end

      assert_raise ArgumentError, fn ->
        Formatter.format(speech_act_changeset(), :combined_changes, color: false)
      end

      assert_raise ArgumentError, fn ->
        Formatter.format(commit_changeset(), :combined_changes)
      end
    end
  end

  def assert_no_line_wrap(text) do
    text
    |> String.split("\n")
    |> Enum.each(fn line ->
      assert String.length(line) <= terminal_width()
    end)
  end
end
