defmodule Ontogen.CommitMiddleware do
  use Gno.CommitMiddleware

  alias Gno.Commit.Processor
  alias Ontogen.Operations.CommitCommand
  alias Ontogen.{Service, Commit}
  alias Ontogen.NS.Og

  def_middleware Og.CommitMiddleware do
  end

  @commit_command_assign :ontogen_command

  def new(attrs \\ []) do
    {id, attrs} = Keyword.pop(attrs, :id, RDF.bnode())
    build(id, attrs)
  end

  def new!(attrs \\ []), do: Gno.Utils.bang!(&new/1, [attrs])

  def init_ontogen_command(processor, args) do
    with {:ok, commit_command} <- ontogen_command(args) do
      {:ok, commit_command,
       processor
       |> setup_on_no_effective_changes(commit_command)
       |> setup_additional_metadata(commit_command)
       |> Processor.assign(@commit_command_assign, commit_command)}
    end
  end

  defp ontogen_command(%CommitCommand{} = command), do: {:ok, command}
  defp ontogen_command(args), do: CommitCommand.new(args)

  defp setup_on_no_effective_changes(processor, %{on_no_effective_changes: nil}), do: processor

  defp setup_on_no_effective_changes(processor, %{on_no_effective_changes: handler}) do
    %{
      processor
      | input_options: Keyword.put(processor.input_options, :on_no_effective_changes, handler)
    }
  end

  defp setup_additional_metadata(processor, %{additional_metadata: nil}), do: processor

  defp setup_additional_metadata(processor, %{additional_metadata: metadata}) do
    Processor.add_metadata(processor, metadata)
  end

  def handle_state(:prepared, _, %{effective_changeset: %Gno.NoEffectiveChanges{}} = processor) do
    {:ok, processor}
  end

  def handle_state(:prepared, _, processor) do
    with {:ok, commit} <-
           build_commit(
             processor.assigns[@commit_command_assign],
             processor.effective_changeset,
             head_id(processor)
           ) do
      {:ok,
       processor
       |> Processor.set_commit_id(commit.__id__)
       |> Processor.add_metadata(Grax.to_rdf!(commit))}
    end
  end

  def handle_state(:applying_changes, _middleware, processor) do
    with {:ok, processor} <-
           Processor.add_additional_changes(processor, :history, add: processor.metadata) do
      Processor.add_additional_changes(processor, :repo,
        add: processor.service.repository.__id__ |> Og.head(Processor.commit_id(processor)),
        remove: processor.service.repository.__id__ |> Og.head(head_id(processor))
      )
    end
  end

  def handle_state(:changes_applied, _middleware, processor) do
    with {:ok, commit} <- commit(processor),
         {:ok, service} <- set_head(processor, commit) do
      {:ok, %{processor | service: service}}
    end
  end

  def handle_state(state, middleware, processor), do: super(state, middleware, processor)

  defp build_commit(%{commit_attrs: commit_attrs} = _commit_command, changeset, parent_commit) do
    commit_attrs
    |> Keyword.put(:changeset, changeset)
    |> Keyword.put(:parent, parent_commit)
    |> Commit.new()
  end

  def commit(processor) do
    Commit.load(processor.metadata, Processor.commit_id(processor))
  end

  defp head_id(processor), do: Service.head_id(processor.service)
  defp set_head(processor, commit), do: Service.set_head(processor.service, commit)
end
