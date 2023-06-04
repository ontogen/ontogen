defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Expression, Utterance}
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

    commit = build!(RDF.bnode(:tmp), args)
    id = Id.generate(commit)

    commit
    |> Grax.reset_id(id)
    |> Grax.validate()
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  defp normalize_expression(_, nil), do: nil
  defp normalize_expression(_, %Expression{} = expression), do: expression
  defp normalize_expression(:insertion, %Utterance{insertion: expression}), do: expression
  defp normalize_expression(:deletion, %Utterance{deletion: expression}), do: expression
  defp normalize_expression(_, statements), do: Expression.new!(statements)

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
