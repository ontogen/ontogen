defmodule Ontogen.ConfigError do
  @moduledoc """
  Raised on errors with `Ontogen.Config`.
  """
  defexception [:file, :reason]

  def message(%{file: nil, reason: :missing}) do
    "No config found"
  end

  def message(%{file: nil, reason: :econnrefused}) do
    "Unable to connect to configured store"
  end

  def message(%{file: nil, reason: reason}) do
    "Invalid config: #{inspect(reason)}"
  end

  def message(%{file: file, reason: reason}) do
    "Invalid config file #{file}: #{inspect(reason)}"
  end
end

defmodule Ontogen.InvalidSPARQLOperationError do
  @moduledoc """
  Raised when creating an invalid `Ontogen.Store.SPARQL.Operation`.
  """

  defexception [:message]

  def exception(value) do
    %__MODULE__{message: "Invalid SPARQL operation: #{value}"}
  end
end

defmodule Ontogen.InvalidStoreEndpointError do
  @moduledoc """
  Raised on invalid `Ontogen.Store.Endpoint`s.
  """
  defexception [:message]

  def exception(value) do
    %__MODULE__{message: "Invalid store endpoint: #{value}"}
  end
end

defmodule Ontogen.EmptyRepositoryError do
  @moduledoc """
  Raised when the current repository does not have any commits.
  """
  defexception [:repository]

  def message(%{repository: repository}) do
    "Repository#{if repository, do: " #{Ontogen.IdUtils.to_iri(repository)}"} does not have any commits yet"
  end
end

defmodule Ontogen.InvalidCommitError do
  @moduledoc """
  Raised on invalid `Ontogen.Commit` args.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid commit: #{reason}"
  end
end

defmodule Ontogen.InvalidSpeechActError do
  @moduledoc """
  Raised on invalid `Ontogen.SpeechAct` args.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid speech act: #{reason}"
  end
end

defmodule Ontogen.InvalidCommitRefError do
  @moduledoc """
  Raised on invalid commit refs.
  """
  defexception [:value]

  def message(%{value: invalid}) do
    "Invalid commit ref: #{invalid}"
  end
end

defmodule Ontogen.InvalidCommitRangeError do
  @moduledoc """
  Raised on invalid `Ontogen.Commit.Range` specs or when a commit is not in the specified range.
  """
  defexception [:reason]

  def message(%{reason: :out_of_range}) do
    "Invalid commit range: out of range"
  end

  def message(%{reason: :head_base}) do
    "Invalid commit range: HEAD is not a valid value for base"
  end

  def message(%{reason: :target_before_base}) do
    "Invalid commit range: target commit is before base"
  end

  def message(%{reason: :no_head}) do
    "Invalid commit range: unable to fetch head from empty commit id chain"
  end

  def message(%{reason: nil}) do
    "Invalid commit range"
  end

  def message(%{reason: reason}) do
    "Invalid commit range: #{reason}"
  end
end

defmodule Ontogen.InvalidChangesetError do
  @moduledoc """
  Raised on invalid `Ontogen.Changeset` args.
  """
  defexception [:reason]

  def message(%{reason: :empty}) do
    "Invalid changeset: no changes provided"
  end

  def message(%{reason: reason}) do
    "Invalid changeset: #{reason}"
  end
end

defmodule Ontogen.IdGenerationError do
  @moduledoc """
  Raised on failing id generations.
  """
  defexception [:schema, :reason]

  def message(%{schema: nil, reason: reason}) do
    "Unable to generate id: #{reason}"
  end

  def message(%{schema: schema, reason: reason}) do
    "Unable to generate id for #{schema}: #{reason}"
  end
end

defmodule Ontogen.Repository.NotSetupError do
  @moduledoc """
  Raised when an attempt is made to perform an operation on the `Ontogen.Service`
  instance with a `Ontogen.Store` where the `Ontogen.Repository`
  was not initialized with `Ontogen.setup/1`.
  """

  defexception [:service, :operation]

  def message(%{service: service}) do
    "Repository of service #{inspect(service)} not setup on the store"
  end
end

defmodule Ontogen.Repository.SetupError do
  @moduledoc """
  Raised when an attempt is made to setup a `Ontogen.Store` where the
   `Ontogen.Repository` is already setup.
  """

  defexception [:reason, :service]

  def message(%{service: service, reason: :already_setup}) do
    "Repository of service #{inspect(service)} already setup on the store"
  end
end

defmodule Ontogen.NoEffectiveChanges do
  @moduledoc """
  Raised when some changes wouldn't have any effects against the current repository.
  """
  defexception []

  def message(%__MODULE__{}) do
    "No effective changes."
  end
end
