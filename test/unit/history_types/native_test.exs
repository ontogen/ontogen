defmodule Ontogen.HistoryType.NativeTest do
  use Ontogen.BogCase

  doctest Ontogen.HistoryType.Native

  alias Ontogen.HistoryType.Native
  alias Ontogen.Commit
  alias RDF.Graph

  test "DESC parent order (default)" do
    {commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits,
             order: {:desc, :parent, to_commit_chain(commits)}
           ) ==
             reloaded_commits(commits)

    assert native_dataset_history(history_graph, commits) ==
             native_dataset_history(history_graph, commits,
               order: {:desc, :parent, to_commit_chain(commits)}
             )
  end

  test "ASC parent order" do
    {commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits,
             order: {:asc, :parent, to_commit_chain(commits)}
           ) ==
             commits
             |> reloaded_commits()
             |> Enum.reverse()
  end

  test "DESC time order" do
    {commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits, order: {:time, :desc}) ==
             commits
             |> reloaded_commits()
             |> Enum.reverse()
  end

  test "ASC time order" do
    {commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits, order: {:time, :asc}) ==
             reloaded_commits(commits)
  end

  test "ASC speech time order" do
    {[fourth, third, second, first] = commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits, order: {:speech_time, :asc}) ==
             [second, third, fourth, first]
             |> reloaded_commits()
  end

  test "DESC speech time order" do
    {[fourth, third, second, first] = commits, history_graph} = commit_history()

    assert native_dataset_history(history_graph, commits, order: {:speech_time, :desc}) ==
             [second, third, fourth, first]
             |> Enum.reverse()
             |> reloaded_commits()
  end

  defp to_commit_chain(commits), do: Enum.map(commits, & &1.__id__)

  defp reloaded_commits(commits) do
    Enum.map(commits, fn
      %Commit{speech_act: nil} = revert -> revert
      commit -> flatten_property(commit, [:speech_act, :data_source])
    end)
  end

  defp native_dataset_history(history_graph, commits, opts \\ []) do
    native_history(history_graph, commits, :dataset, nil, opts)
  end

  defp native_history(history_graph, commits, subject_type, subject, opts) do
    opts = Keyword.put_new(opts, :order, {:desc, :parent, to_commit_chain(commits)})
    assert {:ok, history} = Native.history(history_graph, subject_type, subject, opts)
    history
  end

  defp commit_history() do
    commits =
      commits([
        [
          add: graph(1),
          message: "Initial commit",
          time: datetime(-1),
          speech_act: [time: datetime(-1)]
        ],
        [
          add: graph(2),
          remove: graph(1),
          committer: agent(:agent_jane),
          message: "Second commit",
          time: datetime(-2),
          speech_act: [
            time: datetime(-4)
          ]
        ],
        [
          revert: true,
          time: datetime(-3)
        ],
        [
          update: graph([2, 3, 4]),
          time: datetime(-4),
          speech_act: [
            time: datetime(-2)
          ]
        ]
      ])

    history_graph = Enum.reduce(commits, RDF.graph(), &Graph.add(&2, Grax.to_rdf!(&1)))

    {commits, history_graph}
  end
end
