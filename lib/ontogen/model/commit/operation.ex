defmodule Ontogen.CommitOperation do
  use Gno.CommitOperation.Type
  use Mud.Referencable

  alias Ontogen.NS.Og
  alias Gno.Commit.Processor
  alias Ontogen.CommitMiddleware

  import Ontogen.Utils, only: [bang!: 2]

  def_commit_operation Og.CommitOperation do
  end

  @middleware_id RDF.bnode("ontogen-commit-middleware")
  @preliminary_commit_id RDF.bnode(:preliminary_ontogen_commit_id)

  def build(id, args \\ []) do
    with {:ok, schema} <- super(id, args) do
      setup_middleware(schema)
    end
  end

  def build!(id, args \\ []), do: bang!(&build/2, [id, args])

  defp setup_middleware(operation) do
    if Enum.any?(operation.middlewares, fn %type{} -> type == Ontogen.CommitMiddleware end) do
      {:ok, operation}
    else
      {:ok,
       %{
         operation
         | middlewares: [CommitMiddleware.new!(id: @middleware_id) | operation.middlewares]
       }}
    end
  end

  @impl true
  def handle_step(:init, processor) do
    with {:ok, commit_command, processor} <-
           CommitMiddleware.init_ontogen_command(processor, processor.input),
         {:ok, changeset} <- Gno.Changeset.new(commit_command.changes) do
      {:ok,
       %{processor | changeset: changeset}
       |> Processor.set_commit_id(@preliminary_commit_id, false)}
    end
  end

  def handle_step(state, processor), do: super(state, processor)

  @impl true
  def prepare_commit(processor), do: {:ok, processor}

  @impl true
  def result(%{effective_changeset: %Gno.NoEffectiveChanges{} = exception} = processor) do
    {:ok, exception, processor}
  end

  def result(processor) do
    with {:ok, commit} <- CommitMiddleware.commit(processor) do
      {:ok, commit, processor}
    end
  end
end
