defmodule Ontogen.Changeset do
  defstruct [:insertion, :deletion]

  alias Ontogen.{Expression, Utterance, EffectiveExpression, InvalidChangesetError}
  alias RDF.Graph

  def new(%__MODULE__{} = changeset) do
    validate(changeset)
  end

  def new(%Utterance{} = utterance) do
    __MODULE__
    |> struct(Map.from_struct(utterance))
    |> validate()
  end

  def new(args) do
    case extract(args) do
      {:ok, changeset, _} -> {:ok, changeset}
      error -> error
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, changeset} -> changeset
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {insert, args} = Keyword.pop(args, :insert)
    {delete, args} = Keyword.pop(args, :delete)

    case Keyword.pop(args, :changeset) do
      {nil, args} ->
        with {:ok, insertion} <- normalize_expression(insert),
             {:ok, deletion} <- normalize_expression(delete),
             {:ok, changeset} <- validate(%__MODULE__{insertion: insertion, deletion: deletion}) do
          {:ok, changeset, args}
        end

      {_changeset, _args} when not (is_nil(insert) and is_nil(delete)) ->
        {:error,
         InvalidChangesetError.exception(
           reason: "a changeset can not be used with additional changes"
         )}

      {changeset, args} ->
        with {:ok, changeset} <- new(changeset) do
          {:ok, changeset, args}
        end
    end
  end

  defp normalize_expression(nil), do: {:ok, nil}
  defp normalize_expression([]), do: {:ok, nil}
  defp normalize_expression(%Expression{} = expression), do: {:ok, expression}
  defp normalize_expression(%EffectiveExpression{} = expression), do: {:ok, expression}
  defp normalize_expression(statements), do: Expression.new(statements)

  def validate(changeset) do
    with :ok <- check_statements_present(changeset.insertion, changeset.deletion) do
      check_statement_uniqueness(changeset)
    end
  end

  defp check_statements_present(nil, nil),
    do: {:error, InvalidChangesetError.exception(reason: :empty)}

  defp check_statements_present(_, _), do: :ok

  defp check_statement_uniqueness(changeset) do
    shared_statements =
      shared_statements(
        Expression.graph(changeset.insertion),
        Expression.graph(changeset.deletion)
      )

    if Enum.empty?(shared_statements) do
      {:ok, changeset}
    else
      {:error,
       InvalidChangesetError.exception(
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
end
