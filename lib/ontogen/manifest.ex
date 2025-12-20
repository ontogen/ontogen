defmodule Ontogen.Manifest do
  use Gno.Manifest.Type
  use Grax.Schema

  alias Ontogen.{Agent, Repository, History, Service}

  alias Ontogen.NS.Og

  import Ontogen.Utils, only: [bang!: 2]

  schema Og.Manifest < Gno.Manifest do
    link service: Og.manifestService(), type: Service, required: true
    link agent: Og.manifestAgent(), type: Agent, required: true
  end

  # the og:serviceStore must be set manually to a Store adapter or the generic [ :this og:Store ]
  @service_structure """
                     #{RDF.turtle_prefixes(og: Og, gno: Gno, dcatr: DCATR, "": Mud)}

                     _:service-manifest {
                         [ :this og:Service
                             ; og:serviceRepository [ :this og:Repository ]
                             ; gno:serviceCommitOperation [ :this og:CommitOperation ]
                             ; og:serviceOperator :I
                         ] .
                     }

                     _:repository-manifest {
                         [ :this og:Repository
                             ; dcatr:repositoryManifestGraph [ :this dcatr:RepositoryManifestGraph ]
                             ; dcatr:repositoryDataset [ :this dcatr:Dataset ]
                             ; dcatr:repositoryPrimaryGraph [ :this dcatr:DataGraph ]
                             ; og:repositoryHistory [ :this og:History ]
                         ] .

                         [ :this dcatr:Dataset
                             ; dcatr:dataGraph [ :this dcatr:DataGraph ]
                         ] .
                     }
                     """
                     |> RDF.TriG.read_string!()
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
    with :ok <- Gno.Manifest.Generator.generate(__MODULE__, project_dir, opts) do
      Mud.setup(project_dir)
    end
  end

  @impl true
  def init_dataset(_opts) do
    @service_structure
    |> RDF.Dataset.graphs()
    |> Enum.reduce_while({:ok, RDF.Dataset.new()}, fn graph, {:ok, dataset} ->
      case Mud.process(graph) do
        {:ok, graph} -> {:cont, {:ok, RDF.Dataset.put_graph(dataset, graph)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @impl true
  def load_file(file, opts \\ []) do
    with {:ok, graph} <- super(file, opts) do
      Mud.process(graph)
    end
  end

  @impl true
  def load_manifest(%_manifest_type{__id__: _, dataset: dataset, load_path: _} = manifest, opts) do
    opts_with_service_id = Keyword.put(opts, :service_id, service_id(ref: :this))

    with {:ok, manifest} <- super(manifest, opts_with_service_id),
         {:ok, agent} <-
           responsible_manifest_graph(:agent, dataset)
           |> Agent.load(agent_id(ref: :this), depth: 99) do
      Grax.put(manifest, :agent, agent)
    end
  end

  [
    agent: Agent,
    service: Service,
    repository: Repository,
    dataset: DCATR.Dataset,
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
  end)

  def agent(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} ->
        with {:ok, manifest} <- manifest(opts), do: {:ok, manifest.agent}

      {ref, opts} ->
        with {:ok, %{dataset: dataset}} <- manifest(opts) do
          Agent.deref(ref, responsible_manifest_graph(:agent, dataset))
        end
    end
  end

  def agent!(opts \\ []), do: bang!(&agent/1, [opts])

  defdelegate user(), to: __MODULE__, as: :agent
  defdelegate user!(), to: __MODULE__, as: :agent!

  def service(opts \\ []) do
    if Keyword.has_key?(opts, :ref) do
      with {:ok, %{dataset: manifest_dataset}} <- manifest(opts) do
        Service.load_from_dataset(manifest_dataset, service_id(opts))
      end
    else
      with {:ok, manifest} <- manifest(opts), do: {:ok, manifest.service}
    end
  end

  def service!(opts \\ []), do: bang!(&service/1, [opts])

  def repository(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} ->
        super(opts)

      {ref, opts} ->
        with {:ok, %{dataset: manifest_dataset}} <- manifest(opts) do
          Repository.deref(ref, responsible_manifest_graph(:repository, manifest_dataset))
        end
    end
  end

  def repository!(opts \\ []), do: bang!(&repository/1, [opts])

  def dataset(opts \\ []) do
    if Keyword.has_key?(opts, :ref) do
      with {:ok, %{dataset: manifest_dataset}} <- manifest(opts) do
        responsible_manifest_graph(:dataset, manifest_dataset)
        |> DCATR.Dataset.load(dataset_id(opts))
      end
    else
      with {:ok, repository} <- repository(opts), do: {:ok, repository.dataset}
    end
  end

  def history(opts \\ []) do
    case Keyword.pop(opts, :ref) do
      {nil, opts} ->
        with {:ok, repository} <- repository(opts), do: {:ok, repository.history}

      {ref, opts} ->
        with {:ok, %{dataset: manifest_dataset}} <- manifest(opts) do
          History.deref(ref, responsible_manifest_graph(:history, manifest_dataset))
        end
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

  defp responsible_manifest_graph(resource, dataset)
       when resource in [:repository, :dataset, :history],
       do: RDF.Dataset.graph(dataset, DCATR.Manifest.Loader.repository_manifest_graph_name())

  defp responsible_manifest_graph(:agent, dataset), do: RDF.Graph.new(dataset)
end
