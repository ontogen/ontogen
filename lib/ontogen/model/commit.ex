defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Expression, EffectiveExpression, Utterance, InvalidCommitError}
  alias Ontogen.Commit.Id
  alias RDF.Graph

  schema Og.Commit < PROV.Activity do
    link parent: Og.parentCommit(), type: Ontogen.Commit

    link insertion: Og.committedInsertion(), type: Expression
    link deletion: Og.committedDeletion(), type: Expression

    link committer: Og.committer(), type: Ontogen.Agent, required: true

    property message: Og.commitMessage(), type: :string
    property ended_at: PROV.endedAtTime(), type: :date_time, required: true
  end

  def new(args) do
    args =
      args
      |> Keyword.update(:insertion, nil, &normalize_expression(:insertion, &1))
      |> Keyword.update(:deletion, nil, &normalize_expression(:deletion, &1))

    with {:ok, commit} <- build(RDF.bnode(:tmp), args),
         {:ok, id} <- Id.generate(commit) do
      commit
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  def effective(%__MODULE__{}, nil, nil), do: {:ok, :no_effective_changes}

  def effective(%__MODULE__{} = origin, effective_insertion, effective_deletion) do
    effective_commit = %{origin | insertion: effective_insertion, deletion: effective_deletion}

    with {:ok, id} <- Id.generate(effective_commit) do
      effective_commit
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  defp normalize_expression(_, nil), do: nil
  defp normalize_expression(_, %Expression{} = expression), do: expression
  defp normalize_expression(_, %EffectiveExpression{} = expression), do: expression
  defp normalize_expression(:insertion, %Utterance{insertion: expression}), do: expression
  defp normalize_expression(:deletion, %Utterance{deletion: expression}), do: expression
  defp normalize_expression(_, statements), do: Expression.new!(statements)

  def validate(commit) do
    with :ok <- check_statements_present(commit.insertion, commit.deletion),
         {:ok, commit} <- check_statement_uniqueness(commit) do
      Grax.validate(commit)
    end
  end

  defp check_statements_present(nil, nil),
    do: {:error, InvalidCommitError.exception(reason: "no statements")}

  defp check_statements_present(_, _), do: :ok

  defp check_statement_uniqueness(commit) do
    shared_statements =
      shared_statements(
        Expression.graph(commit.insertion),
        Expression.graph(commit.deletion)
      )

    if Enum.empty?(shared_statements) do
      {:ok, commit}
    else
      {:error,
       InvalidCommitError.exception(
         reason:
           "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
       )}
    end
  end

  defp shared_statements(nil, _), do: []
  defp shared_statements(_, nil), do: []

  defp shared_statements(inserts, deletes) do
    Enum.filter(deletes, &Graph.include?(inserts, &1))
  end

  def root?(%__MODULE__{parent: nil}), do: true
  def root?(%__MODULE__{}), do: false

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Commit})
    }
  end
end
