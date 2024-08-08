defmodule Ontogen.Commit.Changeset do
  @moduledoc false

  alias Ontogen.Commit
  alias Ontogen.Changeset.{Action, Validation, Helper}
  alias RDF.Graph

  import Ontogen.Utils, only: [bang!: 2]
  import Action, only: [is_action_map: 1]
  import Helper

  defstruct Action.fields()

  @type t :: %__MODULE__{
          add: Graph.t() | nil,
          update: Graph.t() | nil,
          replace: Graph.t() | nil,
          remove: Graph.t() | nil,
          overwrite: Graph.t() | nil
        }

  @doc """
  Creates the empty changeset.
  """
  @spec empty :: t()
  def empty, do: %__MODULE__{}

  @doc """
  Creates a new valid changeset.
  """
  @spec new(t() | Commit.t() | keyword, keyword) :: {:ok, t()} | {:error, any()}
  def new(changes, opts \\ [])

  def new(%__MODULE__{} = changeset, opts) do
    validate(changeset, opts)
  end

  def new(%Commit{} = commit, opts) do
    %__MODULE__{
      add: to_graph(commit.add),
      update: to_graph(commit.update),
      replace: to_graph(commit.replace),
      remove: to_graph(commit.remove),
      overwrite: to_graph(commit.overwrite)
    }
    |> validate(opts)
  end

  def new(%{} = action_map, opts) when is_action_map(action_map) do
    %__MODULE__{
      add: to_graph(Map.get(action_map, :add)),
      update: to_graph(Map.get(action_map, :update)),
      replace: to_graph(Map.get(action_map, :replace)),
      remove: to_graph(Map.get(action_map, :remove)),
      overwrite: to_graph(Map.get(action_map, :overwrite))
    }
    |> validate(opts)
  end

  def new(args, opts) when is_list(args) do
    with {:ok, changeset, _} <- extract(args ++ opts) do
      {:ok, changeset}
    end
  end

  @doc """
  Creates a new valid changeset.

  As opposed to `new/1` this function fails in error cases.
  """
  @spec new!(t() | Commit.t() | keyword, keyword) :: t()
  def new!(args, opts \\ []), do: bang!(&new/2, [args, opts])

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
  def validate(%__MODULE__{} = changeset, opts \\ []) do
    Validation.validate(changeset, opts)
  end

  @doc """
  Returns if the given changeset is empty.
  """
  def empty?(%__MODULE__{add: nil, update: nil, replace: nil, remove: nil, overwrite: nil}),
    do: true

  def empty?(%__MODULE__{}), do: false

  def inserts(%__MODULE__{} = changeset), do: Helper.inserts(changeset)

  def to_rdf(%__MODULE__{} = changeset, opts \\ []), do: Helper.to_rdf(changeset, opts)

  def from_rdf(%RDF.Dataset{} = dataset, opts \\ []),
    do: Helper.from_rdf(dataset, __MODULE__, opts)
  @merge_limitations_warning """
  > #### Warning {: .warning}
  >
  > This function is used internally to collapse the changes of multiple consecutive
  > commits from a commit sequence into one and relies on the fact that these consist of
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
      neutralized_removals = graph_intersection(changeset.remove, add)
      neutralized_overwrites = graph_intersection(changeset.overwrite, add)

      %__MODULE__{
        changeset
        | add:
            graph_add(
              changeset.add,
              add
              |> graph_delete(neutralized_removals)
              |> graph_delete(neutralized_overwrites)
            ),
          remove: graph_delete(changeset.remove, neutralized_removals),
          overwrite: graph_delete(changeset.overwrite, neutralized_overwrites)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, update: update) do
    update = to_graph(update)

    if update && not Graph.empty?(update) do
      neutralized_removals = graph_intersection(changeset.remove, update)
      neutralized_overwrites = graph_intersection(changeset.overwrite, update)

      %__MODULE__{
        changeset
        | update:
            graph_add(
              changeset.update,
              update
              |> graph_delete(neutralized_removals)
              |> graph_delete(neutralized_overwrites)
            ),
          remove: graph_delete(changeset.remove, neutralized_removals),
          overwrite: graph_delete(changeset.overwrite, neutralized_overwrites)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, replace: replace) do
    replace = to_graph(replace)

    if replace && not Graph.empty?(replace) do
      neutralized_removals = graph_intersection(changeset.remove, replace)
      neutralized_overwrites = graph_intersection(changeset.overwrite, replace)

      %__MODULE__{
        changeset
        | replace:
            graph_add(
              changeset.replace,
              replace
              |> graph_delete(neutralized_removals)
              |> graph_delete(neutralized_overwrites)
            ),
          remove: graph_delete(changeset.remove, neutralized_removals),
          overwrite: graph_delete(changeset.overwrite, neutralized_overwrites)
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, remove: remove) do
    remove = to_graph(remove)

    if remove && not Graph.empty?(remove) do
      neutralized_adds = graph_intersection(changeset.add, remove)
      neutralized_updates = graph_intersection(changeset.update, remove)
      neutralized_replaces = graph_intersection(changeset.replace, remove)

      %__MODULE__{
        changeset
        | add: graph_delete(changeset.add, neutralized_adds),
          update: graph_delete(changeset.update, neutralized_updates),
          replace: graph_delete(changeset.replace, neutralized_replaces),
          remove:
            graph_add(
              changeset.remove,
              remove
              |> graph_delete(neutralized_adds)
              |> graph_delete(neutralized_updates)
              |> graph_delete(neutralized_replaces)
            )
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, overwrite: overwrite) do
    overwrite = to_graph(overwrite)

    if overwrite && not Graph.empty?(overwrite) do
      neutralized_adds = graph_intersection(changeset.add, overwrite)
      neutralized_updates = graph_intersection(changeset.update, overwrite)
      neutralized_replaces = graph_intersection(changeset.replace, overwrite)

      %__MODULE__{
        changeset
        | add: graph_delete(changeset.add, neutralized_adds),
          update: graph_delete(changeset.update, neutralized_updates),
          replace: graph_delete(changeset.replace, neutralized_replaces),
          overwrite:
            graph_add(
              changeset.overwrite,
              overwrite
              |> graph_delete(neutralized_adds)
              |> graph_delete(neutralized_updates)
              |> graph_delete(neutralized_replaces)
            )
      }
    else
      changeset
    end
  end

  defp do_merge(changeset, %__MODULE__{} = changes) do
    changeset
    # The order must be kept in sync with Ontogen.Changeset.Action order!
    |> do_merge(overwrite: changes.overwrite)
    |> do_merge(remove: changes.remove)
    |> do_merge(replace: changes.replace)
    |> do_merge(update: changes.update)
    |> do_merge(add: changes.add)
  end

  defp do_merge(changeset, %Commit{} = commit) do
    do_merge(changeset, new!(commit))
  end

  defp do_merge(changeset, changes) when is_list(changes) do
    changes
    # TODO: currently all tests pass without this sorting ...
    |> Action.sort_changes()
    |> Enum.reduce(changeset, &do_merge(&2, [&1]))
  end

  def invert(%__MODULE__{} = changeset) do
    %__MODULE__{
      add: graph_add(changeset.remove, changeset.overwrite),
      remove:
        changeset.add
        |> graph_add(changeset.update)
        |> graph_add(changeset.replace)
    }
  end

  def limit(%__MODULE__{} = changeset, :dataset, nil) do
    changeset
  end

  def limit(%__MODULE__{} = changeset, :resource, resource) do
    %__MODULE__{
      add: graph_take(changeset.add, resource),
      update: graph_take(changeset.update, resource),
      replace: graph_take(changeset.replace, resource),
      remove: graph_take(changeset.remove, resource),
      overwrite: graph_take(changeset.overwrite, resource)
    }
  end

  defp graph_take(nil, _), do: nil

  defp graph_take(graph, subjects),
    do: graph |> Graph.take(List.wrap(subjects)) |> graph_cleanup()
end
