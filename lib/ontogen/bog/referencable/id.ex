defmodule Ontogen.Bog.Referencable.Id do
  @moduledoc false

  alias Ontogen.Bog
  alias Ontogen.Bog.{Referencable, NotMinted, AlreadyMinted}

  alias Uniq.UUID

  import Ontogen.Utils, only: [bang!: 2]

  @hash_algorithm :sha256
  @hash_key_size 16

  @hash_schema [:__class__]
  def hash_schema, do: @hash_schema

  def generate(%Referencable{} = referencable, opts \\ []) do
    with {:ok, salt} <-
           (if Keyword.get(opts, :mint, false) do
              load_or_generate_salt(referencable)
            else
              load_salt(referencable)
            end),
         {:ok, hash_material} <- hash_material(referencable, salt) do
      {:ok,
       %Referencable{referencable | __hash__: generate_hash(hash_material, opts)}
       # reapply Grax.Id initialization to let Grax.Id resolve to the Grax.Id.Spec'ified URI
       |> Grax.reset_id()}
    end
  end

  def generate!(referencable, opts \\ []), do: bang!(&generate/2, [referencable, opts])

  defp generate_hash(hash_key_material, opts) do
    if opts[:debug] do
      dbg(hash_key_material)
    else
      @hash_algorithm
      |> HKDF.derive(hash_key_material, @hash_key_size)
      |> Base.encode16(case: :lower)
    end
  end

  def hash_material(%Referencable{} = referencable, salt) do
    {
      :ok,
      [
        ["salt: ", salt]
        | Enum.map(
            @hash_schema,
            &[
              normalize_hash_material_field(&1),
              ": ",
              as_hash_material(Map.fetch!(referencable, &1))
            ]
          )
      ]
      |> Enum.intersperse("\n")
      |> IO.iodata_to_binary()
    }
  end

  defp normalize_hash_material_field(field) do
    field |> to_string() |> String.replace("__", "")
  end

  defp as_hash_material(nil), do: ""
  defp as_hash_material(value), do: to_string(value)

  defp load_or_generate_salt(%Referencable{} = ref) do
    case load_salt(ref) do
      {:ok, _} = ok_loaded -> ok_loaded
      {:error, %NotMinted{}} -> generate_salt(ref)
      {:error, _} = error -> error
    end
  end

  defp load_salt(%Referencable{} = referencable) do
    salt_path = salt_path(referencable)

    if File.exists?(salt_path) do
      File.read(salt_path)
    else
      {:error, NotMinted.exception(referencable: referencable)}
    end
  end

  defp generate_salt(%Referencable{} = referencable) do
    salt_path = salt_path(referencable)

    if File.exists?(salt_path) do
      {:error, AlreadyMinted.exception(referencable: referencable)}
    else
      salt = UUID.uuid4()

      with :ok <- File.write(salt_path, salt) do
        {:ok, salt}
      end
    end
  end

  def salt_path(%Referencable{__ref__: ref}), do: salt_path(ref)

  def salt_path(ref) when is_binary(ref) do
    Path.join(Bog.salt_base_path(), "#{ref}.salt")
  end
end
