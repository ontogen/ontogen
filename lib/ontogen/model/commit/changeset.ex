defmodule Ontogen.Commit.Changeset do
  alias Ontogen.Commit
  alias Ontogen.Changeset.{Action, Validation, Helper}
  alias RDF.Graph

  import Action, only: [is_action_map: 1]
  import Helper, only: [to_graph: 1]

  defstruct Action.fields()

  @type t :: %__MODULE__{
          add: Graph.t() | nil,
          update: Graph.t() | nil,
          replace: Graph.t() | nil,
          remove: Graph.t() | nil,
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
      add: to_graph(commit.add),
      update: to_graph(commit.update),
      replace: to_graph(commit.replace),
      remove: to_graph(commit.remove),
      overwrite: to_graph(commit.overwrite)
    }
    |> validate()
  end

  def new(%{} = action_map) when is_action_map(action_map) do
    %__MODULE__{
      add: to_graph(Map.get(action_map, :add)),
      update: to_graph(Map.get(action_map, :update)),
      replace: to_graph(Map.get(action_map, :replace)),
      remove: to_graph(Map.get(action_map, :remove)),
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

  @merge_limitations_warning """
  > #### Warning {: .warning}
  >
  > This function is used internally to collapse the changes of multiple consecutive
  > commits from a commit sequence into one and relies on the fact that these consist
  > complete effective changes incl. overwrites, which might lead to surprising results
  > and limits its general applicability. E.g. a single merged `replace` does not
  > remove the statements with only matching subjects from the other actions, but only
  > the fully matching statements, since we rely on the fact that a complete commit
  > includes also the `overwrite`s of these statements, leading to the removals of
  > these statements during the merge.
  """

  @doc """
  Merge the changes of a list commit into one.

  #{@merge_limitations_warning}
  """
  def merge([first | rest]) do
    with {:ok, changeset} <- new(first) do
      Enum.reduce(rest, changeset, &do_merge(&2, &1))
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Merge the changes of two commit changesets into one.

  #{@merge_limitations_warning}
  """
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

  defp do_merge(changeset, add: add) do
    add = to_graph(add)

    if add && not Graph.empty?(add) do
      %__MODULE__{
        changeset
        | add:
            graph_add(
              changeset.add,
              add
              |> Graph.delete(changeset.update || [])
              |> Graph.delete(changeset.replace || [])
            ),
          remove: graph_delete(changeset.remove, add),
          overwrite: graph_delete(changeset.overwrite, add)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, update: update) do
    update = to_graph(update)

    if update && not Graph.empty?(update) do
      # We don't need to consider the special update semantics here, since we rely on complete
      # commit changes, which include all overwritten statements in the overwrite graph.
      %__MODULE__{
        changeset
        | add: graph_delete(changeset.add, update),
          update:
            graph_add(
              changeset.update,
              update
              |> Graph.delete(changeset.replace || [])
            ),
          remove: graph_delete(changeset.remove, update),
          overwrite: graph_delete(changeset.overwrite, update)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, replace: replace) do
    replace = to_graph(replace)

    if replace && not Graph.empty?(replace) do
      # We don't need to consider the special replace semantics here, since we rely on complete
      # commit changes, which include all overwritten statements in the overwrite graph.
      %__MODULE__{
        changeset
        | add: graph_delete(changeset.add, replace),
          update: graph_delete(changeset.update, replace),
          replace: graph_add(changeset.replace, replace),
          remove: graph_delete(changeset.remove, replace),
          overwrite: graph_delete(changeset.overwrite, replace)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, remove: remove) do
    remove = to_graph(remove)

    if remove && not Graph.empty?(remove) do
      %__MODULE__{
        changeset
        | add: graph_delete(changeset.add, remove),
          update: graph_delete(changeset.update, remove),
          replace: graph_delete(changeset.replace, remove),
          remove: graph_add(changeset.remove, remove),
          overwrite: graph_delete(changeset.overwrite, remove)
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
        | add: graph_delete(changeset.add, overwrite),
          update: graph_delete(changeset.update, overwrite),
          replace: graph_delete(changeset.replace, overwrite),
          remove: graph_delete(changeset.remove, overwrite),
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
  defp graph_delete(graph, removals), do: graph |> Graph.delete(removals) |> graph_cleanup()
  defp graph_cleanup(graph), do: unless(Graph.empty?(graph), do: graph)
end
