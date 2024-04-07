defmodule Ontogen.ConfigError do
  @moduledoc """
  Raised on errors with `Ontogen.Config`.
  """
  defexception [:file, :reason]

  def message(%{file: nil, reason: :missing}) do
    "No config file found"
  end

  def message(%{file: nil, reason: reason}) do
    "Invalid config: #{inspect(reason)}"
  end

  def message(%{file: file, reason: reason}) do
    "Invalid config file #{file}: #{inspect(reason)}"
  end
end

defmodule Ontogen.InvalidRepoSpecError do
  @moduledoc """
  Raised when the repo spec for the creation of a `Ontogen.Repository`
  is invalid.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid repository spec: #{reason}"
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

defmodule Ontogen.Repository.NotReadyError do
  @moduledoc """
  Raised when trying to perform an operation on a repo when it is not ready,
  i.e. not connected with a repository in the store.
  """
  defexception [:operation]

  def message(%{operation: operation}) do
    "Unable to perform #{inspect(operation)}. Repository not ready."
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
