defmodule Ontogen.Config.Repository.IdFile do
  alias Ontogen.Repository

  @default_path ".ontogen_repo"

  def path do
    Application.get_env(:ontogen, :repo_id_file, @default_path)
  end

  def create(%Repository{} = repository), do: create(repository.__id__)

  def create(%RDF.IRI{} = repository_id) do
    File.write!(path(), to_string(repository_id))
  end

  def read do
    if (filename = path()) && File.exists?(filename) do
      filename
      |> File.read!()
      |> String.trim()
    end
  end
end
