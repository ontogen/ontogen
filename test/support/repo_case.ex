defmodule Ontogen.Local.Repo.Test.Case do
  use ExUnit.CaseTemplate

  alias Ontogen.Local.Repo

  import ExUnit.CaptureIO

  using do
    quote do
      use Ontogen.Test.Case, async: false

      alias Ontogen.Repository
      alias Ontogen.{Local, Store}
      alias Ontogen.Local.Repo

      import unquote(__MODULE__)

      import ExUnit.CaptureIO

      setup_all :start_repo
      setup :clean_repo!

      def start_repo(_) do
        [repo: repo] = clean_repo!(:ok)

        capture_io(fn -> {:ok, _} = start_supervised({Repo, [repo: repo.__id__]}) end)

        :ok
      end

      def clean_repo!(_) do
        {:ok, repo} = Ontogen.Commands.ClearRepo.call(Local.store(), base_repo())

        if Process.whereis(Repo) do
          {:ok, ^repo} = Repo.reload()
        end

        on_exit(fn -> Ontogen.Commands.ClearRepo.delete_repo(Local.store(), repo) end)

        [repo: repo]
      end

      def base_repo, do: repository()

      def stored_repo do
        {:ok, repo} = Ontogen.Commands.RepoInfo.call(Local.store(), base_repo().__id__, depth: 1)
        repo
      end

      defoverridable base_repo: 0
    end
  end
end
