defmodule Ontogen.Local.Repo.IdFile do
  @repo_id_filename ".ontogen_repo"
  @env_repo_id_filename "#{@repo_id_filename}_#{Mix.env()}"
  @repo_id_filenames [@env_repo_id_filename, @repo_id_filename]

  @create_repo_id_file Application.compile_env(:ontogen, :create_repo_id_file, true)

  def create(repository, opts) when is_list(opts) do
    opts
    |> Keyword.get(:create_repo_id_file, @create_repo_id_file)
    |> do_create_repo_id_file(repository.__id__)
  end

  defp do_create_repo_id_file(nil, _), do: :skipped
  defp do_create_repo_id_file(false, _), do: :skipped

  defp do_create_repo_id_file(true, repo_id),
    do: do_create_repo_id_file(@repo_id_filename, repo_id)

  defp do_create_repo_id_file(:env, repo_id),
    do: do_create_repo_id_file(@env_repo_id_filename, repo_id)

  defp do_create_repo_id_file(filename, repo_id) do
    File.write!(filename, to_string(repo_id))
  end

  def read do
    Enum.find_value(@repo_id_filenames, fn filename ->
      if File.exists?(filename) do
        filename
        |> File.read!()
        |> String.trim()
      end
    end)
  end
end
