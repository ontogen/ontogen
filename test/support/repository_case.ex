defmodule Ontogen.RepositoryCase do
  use ExUnit.CaseTemplate

  import Ontogen.TestFactories
  alias Ontogen.Config
  alias Ontogen.Operations.ClearRepositoryCommand

  using do
    quote do
      use OntogenCase, async: false

      alias Ontogen.{Repository, Store, Changeset}

      import unquote(__MODULE__)

      import ExUnit.CaptureIO

      setup_all :start_repo
      setup :clean_repo!

      def start_repo(_) do
        [repo: repo] = clean_repo!(:ok)

        capture_io(fn -> {:ok, _} = start_supervised({Ontogen, [repo: repo.__id__]}) end)

        :ok
      end

      def clean_repo!(_) do
        {:ok, repo} =
          ClearRepositoryCommand.new!()
          |> ClearRepositoryCommand.call(Config.store(), base_repo())

        if Process.whereis(Ontogen) do
          {:ok, ^repo} = Ontogen.reload()
        end

        on_exit(fn ->
          ClearRepositoryCommand.delete_repo(Config.store(), repo)
        end)

        [repo: repo]
      end

      def base_repo, do: repository()

      def stored_repo do
        {:ok, repo} = Store.repository(Config.store(), base_repo().__id__, depth: 1)

        repo
      end

      defoverridable base_repo: 0
    end
  end

  def init_commit_history do
    init_commit_history([
      [
        insert: graph(),
        message: "Initial commit",
        time: datetime() |> DateTime.add(-1, :hour)
      ]
    ])
  end

  def init_commit_history(history) when is_list(history) do
    start_offset = Enum.count(history)
    time = datetime()

    history
    |> Enum.with_index(&{&1, start_offset - &2})
    |> Enum.map(fn {commit_args, time_offset} ->
      commit_args =
        Keyword.put_new(commit_args, :time, DateTime.add(time, 0 - time_offset, :hour))

      assert {:ok, commit} = Ontogen.commit(commit_args)
      assert Ontogen.head() == commit

      commit
    end)
    |> Enum.reverse()
  end
end
