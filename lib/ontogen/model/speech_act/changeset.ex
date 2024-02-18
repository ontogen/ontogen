defmodule Ontogen.SpeechAct.Changeset do
  alias Ontogen.SpeechAct
  alias Ontogen.Changeset.{Action, Validation, Helper}
  alias RDF.Graph

  import Action, only: [is_action_map: 1]
  import Helper, only: [to_graph: 1]

  defstruct Action.fields() -- [:overwrite]

  @type t :: %__MODULE__{
          insert: Graph.t() | nil,
          delete: Graph.t() | nil,
          update: Graph.t() | nil,
          replace: Graph.t() | nil
        }

  @doc """
  Creates a new valid changeset.
  """
  @spec new(t() | SpeechAct.t() | keyword) :: {:ok, t()} | {:error, any()}
  def new(%__MODULE__{} = changeset) do
    validate(changeset)
  end

  def new(%SpeechAct{} = speech_act) do
    %__MODULE__{
      insert: to_graph(speech_act.insert),
      delete: to_graph(speech_act.delete),
      update: to_graph(speech_act.update),
      replace: to_graph(speech_act.replace)
    }
    |> validate()
  end

  def new(%{} = action_map) when is_action_map(action_map) do
    %__MODULE__{
      insert: to_graph(Map.get(action_map, :insert)),
      delete: to_graph(Map.get(action_map, :delete)),
      update: to_graph(Map.get(action_map, :update)),
      replace: to_graph(Map.get(action_map, :replace))
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
  @spec new!(t() | SpeechAct.t() | keyword) :: t()
  def new!(args) do
    case new(args) do
      {:ok, changeset} -> changeset
      {:error, error} -> raise error
    end
  end

  @doc """
  Extracts a `Ontogen.SpeechAct.Changeset` from the given keywords and returns it with the remaining unprocessed keywords.
  """
  def extract(keywords), do: Helper.extract(__MODULE__, keywords)

  @doc """
  Validates the given changeset structure.

  If valid, the given structure is returned unchanged in an `:ok` tuple.
  Otherwise, an `:error` tuple is returned.
  """
  def validate(%__MODULE__{} = changeset) do
    Validation.validate(changeset)
  end
end
