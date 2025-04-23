defmodule Ontogen.Manifest.Generator do
  @moduledoc """
  Generator for the manifest files of an Ontogen repository.
  """

  def default_template_dir do
    :ontogen |> :code.priv_dir() |> Path.join("manifest_template")
  end

  @doc """
  Generates the manifest files for an Ontogen repository.

  The `destination` is the target directory where the generated configuration
  files are written to. If the directory does not exist, it is created.

  ## Options

  - `:adapter` - Initial store adapter (optional, default: `Gno.Store` for the generic store)
  - `:template_dir` - Custom template directory
  - `:force` - Flag to overwrite existing files (default: `false`)
  - `:assigns` - Additional assigns for EEx templates

  """
  @spec generate(Path.t(), keyword()) :: :ok
  def generate(destination, opts \\ []) do
    adapter = Keyword.get(opts, :adapter)
    template_dir = Keyword.get(opts, :template_dir, default_template_dir())
    force = Keyword.get(opts, :force, false)
    custom_assigns = Keyword.get(opts, :assigns, [])

    unless is_nil(adapter) or (is_atom(adapter) and Gno.Store.Adapter.type?(adapter)) do
      raise ArgumentError, "invalid store adapter: #{inspect(adapter)}"
    end

    unless File.exists?(destination), do: File.mkdir_p(destination)

    template_dir
    |> File.ls!()
    |> Enum.each(fn file ->
      base_file = Path.basename(file, ".eex")
      eex? = file != base_file
      source = Path.join(template_dir, file)
      dest = Path.join(destination, base_file)

      if File.exists?(dest) and not force do
        raise "File already exists: #{dest}"
      end

      copy_file!(
        source,
        dest,
        eex? &&
          Keyword.merge(custom_assigns,
            adapter: adapter
          )
      )
    end)

    Mud.setup()

    :ok
  end

  defp copy_file!(source, dest, false), do: File.copy!(source, dest)

  defp copy_file!(source, dest, assigns) do
    File.write!(dest, EEx.eval_file(source, assigns: assigns))
  end
end
