defmodule Ontogen.Local.ConfigError do
  @moduledoc """
  Raised on errors with `Ontogen.Local.Config`.
  """
  defexception [:file, :reason]

  def message(%{file: nil, reason: :missing}) do
    "No local config file found"
  end

  def message(%{file: nil, reason: reason}) do
    "Invalid local config: #{inspect(reason)}"
  end

  def message(%{file: file, reason: reason}) do
    "Invalid local config file #{file}: #{inspect(reason)}"
  end
end

defmodule Ontogen.InvalidRepoSpecError do
  @moduledoc """
  Raised when the repo spec for the creation of a `Ontogen.Local.Repo`
  is invalid.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid repo spec: #{reason}"
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

defmodule Ontogen.InvalidUtteranceError do
  @moduledoc """
  Raised on invalid `Ontogen.Utterance` args.
  """
  defexception [:reason]

  def message(%{reason: reason}) do
    "Invalid utterance: #{reason}"
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

defmodule Ontogen.Local.Repo.NotReadyError do
  @moduledoc """
  Raised when trying to perform an operation on a repo when it is not ready,
  i.e. not connected with a repository in the local store.
  """
  defexception [:operation]

  def message(%{operation: operation}) do
    "Unable to perform #{inspect(operation)}. Repo not ready."
  end
end
