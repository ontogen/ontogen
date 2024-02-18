defmodule Ontogen.Commit.Changeset do
  alias Ontogen.Commit
  alias Ontogen.Changeset.{Action, Validation, Helper}
  alias RDF.Graph

  import Action, only: [is_action_map: 1]
  import Helper, only: [to_graph: 1]

  defstruct Action.fields()

  @type t :: %__MODULE__{
          insert: Graph.t() | nil,
          delete: Graph.t() | nil,
          update: Graph.t() | nil,
          replace: Graph.t() | nil,
          overwrite: Graph.t() | nil
        }

  @doc """
  Creates a new valid changeset.
  """
  @spec new(t() | Commit.t() | keyword) :: {:ok, t()} | {:error, any()}
  def new(%__MODULE__{} = changeset) do
    validate(changeset)
  end

  def new(%Commit{} = commit) do
    %__MODULE__{
      insert: to_graph(commit.insert),
      delete: to_graph(commit.delete),
      update: to_graph(commit.update),
      replace: to_graph(commit.replace),
      overwrite: to_graph(commit.overwrite)
    }
    |> validate()
  end

  def new(%{} = action_map) when is_action_map(action_map) do
    %__MODULE__{
      insert: to_graph(Map.get(action_map, :insert)),
      delete: to_graph(Map.get(action_map, :delete)),
      update: to_graph(Map.get(action_map, :update)),
      replace: to_graph(Map.get(action_map, :replace)),
      overwrite: to_graph(Map.get(action_map, :overwrite))
    }
    |> validate()
  end

  def new(args) when is_list(args) do
    with {:ok, changeset, _} <- extract(args) do
      {:ok, changeset}
    end
  end

  @doc """
  Creates a new valid changeset.

  As opposed to `new/1` this function fails in error cases.
  """
  @spec new!(t() | Commit.t() | keyword) :: t()
  def new!(args) do
    case new(args) do
      {:ok, changeset} -> changeset
      {:error, error} -> raise error
    end
  end

  @doc """
  Extracts a `Ontogen.Commit.Changeset` from the given keywords and returns it with the remaining unprocessed keywords.
  """
  def extract(keywords) do
    Helper.extract(__MODULE__, keywords)
  end

  @doc """
  Validates the given changeset structure.

  If valid, the given structure is returned unchanged in an `:ok` tuple.
  Otherwise, an `:error` tuple is returned.
  """
  def validate(%__MODULE__{} = changeset) do
    Validation.validate(changeset)
  end

  def merge([first | rest]) do
    with {:ok, changeset} <- new(first) do
      Enum.reduce(rest, changeset, &do_merge(&2, &1))
    else
      {:error, error} -> raise error
    end
  end

  def merge(%__MODULE__{} = changeset, changes) do
    do_merge(changeset, changes)
  end

  def merge(changeset, changes) do
    with {:ok, changeset} <- new(changeset) do
      do_merge(changeset, changes)
    else
      {:error, error} -> raise error
    end
  end

  defp do_merge(changeset, insert: insert) do
    insert = to_graph(insert)

    if insert && not Graph.empty?(insert) do
      %__MODULE__{
        changeset
        | insert:
            graph_add(
              changeset.insert,
              insert
              |> Graph.delete(changeset.update || [])
              |> Graph.delete(changeset.replace || [])
            ),
          delete: graph_delete(changeset.delete, insert),
          overwrite: graph_delete(changeset.overwrite, insert)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, update: update) do
    update = to_graph(update)

    if update && not Graph.empty?(update) do
      %__MODULE__{
        changeset
        | insert: graph_delete(changeset.insert, update),
          update:
            graph_add(
              changeset.update,
              update
              |> Graph.delete(changeset.replace || [])
            ),
          delete: graph_delete(changeset.delete, update),
          overwrite: graph_delete(changeset.overwrite, update)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, replace: replace) do
    replace = to_graph(replace)

    if replace && not Graph.empty?(replace) do
      %__MODULE__{
        changeset
        | insert: graph_delete(changeset.insert, replace),
          update: graph_delete(changeset.update, replace),
          replace: graph_add(changeset.replace, replace),
          delete: graph_delete(changeset.delete, replace),
          overwrite: graph_delete(changeset.overwrite, replace)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, delete: delete) do
    delete = to_graph(delete)

    if delete && not Graph.empty?(delete) do
      %__MODULE__{
        changeset
        | insert: graph_delete(changeset.insert, delete),
          update: graph_delete(changeset.update, delete),
          replace: graph_delete(changeset.replace, delete),
          delete: graph_add(changeset.delete, delete),
          overwrite: graph_delete(changeset.overwrite, delete)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, overwrite: overwrite) do
    overwrite = to_graph(overwrite)

    if overwrite && not Graph.empty?(overwrite) do
      %__MODULE__{
        changeset
        | insert: graph_delete(changeset.insert, overwrite),
          update: graph_delete(changeset.update, overwrite),
          replace: graph_delete(changeset.replace, overwrite),
          delete: graph_delete(changeset.delete, overwrite),
          overwrite: graph_add(changeset.overwrite, overwrite)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, changes) when is_list(changes) do
    changes
    |> Action.sort_changes()
    |> Enum.reduce(changeset, &do_merge(&2, [&1]))
  end

  defp graph_add(nil, additions), do: Graph.new(additions)
  defp graph_add(graph, additions), do: Graph.add(graph, additions)
  defp graph_delete(nil, _), do: nil
  defp graph_delete(graph, deletions), do: graph |> Graph.delete(deletions) |> graph_cleanup()
  defp graph_cleanup(graph), do: unless(Graph.empty?(graph), do: graph)
end
