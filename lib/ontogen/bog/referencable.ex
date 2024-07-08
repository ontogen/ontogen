defmodule Ontogen.Bog.Referencable do
  use Grax.Schema

  alias RDF.{Graph, IRI}
  alias Ontogen.Bog
  alias Ontogen.Bog.NotMinted
  alias Ontogen.Bog.Referencable.Id

  import Ontogen.Utils, only: [bang!: 2]
  import RDF.Utils.Guards

  schema Bog.Referencable do
    property __class__: RDF.type(),
             type: :iri,
             required: true,
             from_rdf: :__class__from_rdf

    # the value used as the UUIDv5 name of the Ontogen UUIDv5 namespace (see id_spec.ex)
    property __hash__: Bog.refHash(),
             type: :string,
             required: true

    # This field is for local use only, it MUST NOT be stored or hashed!
    property __ref__: Bog.ref(), type: :string, required: true
  end

  def __class__from_rdf(types, description, _graph) do
    case Enum.filter(types, &type?/1) do
      [class] ->
        {:ok, class}

      [] ->
        {:error, "no referencable class for #{inspect(description)}"}

      multiple ->
        {:error,
         "multiple referencable classes for #{inspect(description)}: #{inspect(multiple)}"}
    end
  end

  @type ref :: String.t()

  @callback deref_id(ref()) :: {:ok, RDF.IRI.t()} | {:error, any}
  @callback deref(ref(), Graph.t()) :: {:ok, Grax.Schema.t()} | {:error, any}

  @callback this_ref :: ref()
  @callback this_id :: {:ok, RDF.IRI.t()} | {:error, any}
  @callback this(Graph.t()) :: {:ok, Grax.Schema.t()} | {:error, any}

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def mint(ref), do: unquote(__MODULE__).mint(ref, __MODULE__)
      def mint!(ref), do: unquote(__MODULE__).mint!(ref, __MODULE__)

      @impl true
      def deref_id(ref), do: unquote(__MODULE__).deref_id(__MODULE__, ref)
      def deref_id!(ref), do: unquote(__MODULE__).deref_id!(__MODULE__, ref)

      @impl true
      def deref(ref, graph, opts \\ []),
        do: unquote(__MODULE__).deref(__MODULE__, ref, graph, opts)

      def deref!(ref, graph, opts \\ []),
        do: unquote(__MODULE__).deref!(__MODULE__, ref, graph, opts)

      @impl true
      def this(graph, opts \\ []), do: deref(:this, graph, opts)
      def this!(graph, opts \\ []), do: deref!(:this, graph, opts)

      @impl true
      def this_id, do: deref_id(:this)
      def this_id!, do: deref_id!(:this)

      @impl true
      def this_ref, do: unquote(__MODULE__).this_ref(__MODULE__)
    end
  end

  def new(ref, schema, opts \\ [])

  def new(:this, schema, opts), do: schema |> this_ref() |> new(schema, opts)

  def new(ref, schema, opts) when maybe_module(schema),
    do: new(ref, RDF.iri(schema.__class__()), opts)

  def new(ref, %IRI{} = class, opts) when is_binary(ref) do
    %__MODULE__{
      __ref__: ref,
      __class__: class
    }
    |> Id.generate(opts)
  end

  def new!(ref, schema_or_class, opts \\ []), do: bang!(&new/3, [ref, schema_or_class, opts])

  def mint(ref, class), do: new(ref, class, mint: true)
  def mint!(ref, schema_or_class), do: bang!(&mint/2, [ref, schema_or_class])

  def load_from_rdf(graph, id, opts \\ []) do
    with {:ok, referencable} <- load(graph, id, Keyword.put(opts, :validate, false)) do
      validate(referencable, minted: false)
    end
  end

  def load_from_rdf!(graph, id, opts \\ []), do: bang!(&load_from_rdf/3, [graph, id, opts])

  def validate(%__MODULE__{} = referencable, opts \\ []) do
    {minted, opts} = Keyword.pop(opts, :minted)

    if minted do
      Grax.validate(referencable, opts)
    else
      with {:ok, _} <- %{referencable | __hash__: "unminted"} |> Grax.validate(opts) do
        {:ok, referencable}
      end
    end
  end

  @doc """
  Returns the IRI of the referencable resource of the given `schema`.
  """
  def deref_id(schema, ref)

  def deref_id(schema, :this), do: deref_id(schema, this_ref(schema))

  def deref_id(schema, ref) do
    with {:ok, referencable} <- new(ref, schema) do
      {:ok, referencable.__id__}
    end
  end

  def deref_id!(schema, ref) do
    case deref_id(schema, ref) do
      {:ok, id} -> id
      {:error, %NotMinted{}} -> nil
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the fully instantiated referencable singleton resource of the given `schema` loaded from the given `graph`.
  """
  def deref(schema, ref, graph, opts \\ [])

  def deref(schema, :this, graph, opts), do: deref(schema, this_ref(schema), graph, opts)

  def deref(schema, ref, graph, opts) do
    with {:ok, id} <- deref_id(schema, ref) do
      schema.load(graph, id, Keyword.put_new(opts, :depth, 99))
    end
  end

  def deref!(schema, ref, graph, opts \\ []) do
    case deref(schema, ref, graph, opts) do
      {:ok, schema} -> schema
      {:error, %NotMinted{}} -> nil
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the ref name for the referencable singleton instance of the given schema or class IRI.

  ### Examples

      iex> Ontogen.Bog.Referencable.this_ref(~I<https://w3id.org/ontogen#Service>)
      "service"

      iex> Ontogen.Bog.Referencable.this_ref(~I<http://xmlns.com/foaf/0.1/Agent>)
      "agent"

      iex> Ontogen.Bog.Referencable.this_ref(Ontogen.Agent)
      "agent"

      iex> Ontogen.Bog.Referencable.this_ref(FOAF.Agent)
      "agent"
  """
  def this_ref(%IRI{} = class) do
    case IRI.parse(class) do
      %URI{fragment: nil, path: path} -> Path.basename(path)
      %URI{fragment: fragment} -> fragment
    end
    |> String.split_at(1)
    |> case do
      {first_letter, rest} ->
        downcased = String.downcase(first_letter)

        if first_letter == downcased do
          raise "invalid class URI #{class}; must start with a uppercase letter"
        else
          downcased <> rest
        end
    end
  end

  def this_ref(schema), do: schema.__class__() |> RDF.iri() |> this_ref()

  def on_to_rdf(%{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Bog.Referencable})
    }
  end

  @doc """
  Checks if the given `module` is a `Ontogen.Bog.Referencable`.

  ## Examples

      iex> Ontogen.Bog.Referencable.type?(Ontogen.Repository)
      true

      iex> Ontogen.Bog.Referencable.type?(Ontogen.Commit)
      false

  """
  @spec type?(module) :: boolean
  def type?(module) when is_atom(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :deref, 3)
  end

  def type?(%IRI{} = iri), do: iri |> Grax.schema() |> type?()
  def type?(_), do: false
end
