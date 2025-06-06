defmodule Ontogen.Manifest do
  use Gno.Manifest.Type
  use Grax.Schema

  alias Ontogen.{Agent, Repository, Dataset, History, Service}

  alias Ontogen.NS.Og

  import Ontogen.Utils, only: [bang!: 2]

  schema Og.Manifest < Gno.Manifest do
    link service: Og.manifestService(), type: Service, required: true
    link agent: Og.manifestAgent(), type: Agent, required: true
  end

  # the og:serviceStore must be set manually to a Store adapter or the generic [ :this og:Store ]
  @service_structure """
                     #{RDF.turtle_prefixes(og: Og, gno: Gno, "": Mud)}

                     [ :this og:Service
                         ; og:serviceRepository [ :this og:Repository
                             ; og:repositoryDataset [ :this og:Dataset ]
                             ; og:repositoryHistory [ :this og:History ]
                         ]
                         ; gno:serviceCommitOperation [ :this og:CommitOperation ]
                         ; og:serviceOperator :I
                     ] .
                     """
                     |> RDF.Turtle.read_string!()
  def service_structure, do: @service_structure

  @impl true
  def generator_template do
    Application.get_env(
      :ontogen,
      :manifest_template_dir,
      :ontogen |> :code.priv_dir() |> Path.join("manifest_template")
    )
  end

  @impl true
  def generate(project_dir, opts \\ []) do
    with :ok <- super(project_dir, opts) do
      Mud.setup(project_dir)
    end
  end

  @impl true
  def init_graph(_opts), do: Mud.process(@service_structure)

  @impl true
  def load_file(file, opts \\ []) do
    with {:ok, graph} <- super(file, opts) do
      Mud.process(graph)
    end
  end

  @impl true
  def load_manifest(
        %_manifest_type{__id__: _, graph: graph, load_path: _, service: _} = manifest,
        _opts
      ) do
    with {:ok, service} <- service_type().load(graph, service_id(ref: :this), depth: 99),
         {:ok, agent} <- Agent.load(graph, agent_id(ref: :this), depth: 99) do
      manifest
      |> Grax.put!(:agent, agent)
      |> Grax.put(:service, service)
    end
  end

  [
    agent: Agent,
    service: Service,
    repository: Repository,
    dataset: Dataset,
    history: History
  ]
  |> Enum.each(fn {name, schema} ->
    bang_name = String.to_atom("#{name}!")

    def unquote(:"#{name}_id")(opts \\ []) do
      case Keyword.pop(opts, :ref) do
        {nil, opts} ->
          unquote(bang_name)(opts).__id__

        {:this, opts} ->
          opts |> Keyword.put(:ref, {:this, unquote(schema)}) |> unquote(:"#{name}_id")()

        {ref, _opts} ->
          Mud.deref_id!(ref)
      end
    end

    if name not in [:agent, :history] do
      def unquote(name)(opts \\ []) do
        case Keyword.pop(opts, :ref) do
          {nil, opts} ->
            super(opts)

          {ref, opts} ->
            with {:ok, %{graph: graph}} <- manifest(opts), do: unquote(schema).deref(ref, graph)
        end
      end

      def unquote(bang_name)(opts \\ []) do
        case unquote(name)(opts) do
          {:ok, result} -> result
          {:error, error} -> raise error
        end
      end
    end
  end)

  def agent(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} -> with {:ok, manifest} <- manifest(opts), do: {:ok, manifest.agent}
      {ref, opts} -> with {:ok, %{graph: graph}} <- manifest(opts), do: Agent.deref(ref, graph)
    end
  end

  def agent!(opts \\ []), do: bang!(&agent/1, [opts])

  defdelegate user(), to: __MODULE__, as: :agent
  defdelegate user!(), to: __MODULE__, as: :agent!

  def history(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} -> with {:ok, repository} <- repository(opts), do: {:ok, repository.history}
      {ref, opts} -> with {:ok, %{graph: graph}} <- manifest(opts), do: History.deref(ref, graph)
    end
  end

  def history!(opts \\ []), do: bang!(&history/1, [opts])

  def store(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} -> with {:ok, service} <- service(opts), do: {:ok, service.store}
      {_ref, _opts} -> raise "not implemented"
    end
  end

  def store!(opts \\ []), do: bang!(&store/1, [opts])
end
