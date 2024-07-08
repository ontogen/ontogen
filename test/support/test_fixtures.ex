defmodule Ontogen.TestFixtures do
  @moduledoc """
  Test fixtures.
  """

  alias Ontogen.Service

  import ExUnit.Assertions
  import Ontogen.TestFactories

  def init_commit_history do
    init_commit_history([
      [
        add: graph(),
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

  def ready_service, do: Ontogen.Config.service!() |> ready_service()

  def ready_service(service) do
    {:ok, ready_service} =
      service
      |> Service.set_status(:ready)
      |> Service.set_head(:root)

    ready_service
  end
end
