defmodule Ontogen.Config.GeneratorTest do
  use OntogenCase

  doctest Ontogen.Config.Generator

  alias Ontogen.Config.Generator
  alias Ontogen.Store
  alias Ontogen.Store.Adapters.{Fuseki, Oxigraph}

  @moduletag :tmp_dir

  setup context do
    on_exit(fn -> File.rm_rf!(context.tmp_dir) end)
  end

  @all_adapters [Store, Fuseki, Oxigraph]

  test "initializes service config without adapter", %{tmp_dir: tmp_dir} do
    Generator.generate(tmp_dir)

    assert_files_generated(tmp_dir)

    assert_selected_adapter(
      Path.join(tmp_dir, "service.bog.ttl"),
      Store,
      @all_adapters -- [Store]
    )
  end

  test "initializes service config with adapter", %{tmp_dir: tmp_dir} do
    Generator.generate(tmp_dir, adapter: Fuseki)

    assert_files_generated(tmp_dir)

    assert_selected_adapter(
      Path.join(tmp_dir, "service.bog.ttl"),
      Fuseki,
      @all_adapters -- [Fuseki]
    )

    File.rm_rf!(tmp_dir)

    Generator.generate(tmp_dir, adapter: Oxigraph)

    assert_files_generated(tmp_dir)

    assert_selected_adapter(
      Path.join(tmp_dir, "service.bog.ttl"),
      Oxigraph,
      @all_adapters -- [Oxigraph]
    )
  end

  test "with unknown adapter", %{tmp_dir: tmp_dir} do
    assert_raise ArgumentError, "invalid store adapter: :unknown", fn ->
      Generator.generate(tmp_dir, adapter: :unknown)
    end
  end

  test "force flag", %{tmp_dir: tmp_dir} do
    existing_file = Path.join(tmp_dir, "dataset.bog.ttl")
    File.write!(existing_file, "Original content")

    assert_raise RuntimeError, "File already exists: #{existing_file}", fn ->
      Generator.generate(tmp_dir)
    end

    assert File.read!(existing_file) == "Original content"

    Generator.generate(tmp_dir, force: true)

    refute File.read!(existing_file) == "Original content"
  end

  defp assert_files_generated(tmp_dir) do
    assert File.exists?(Path.join(tmp_dir, "agent.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "service.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "repository.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "dataset.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "store.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "fuseki.bog.ttl"))
    assert File.exists?(Path.join(tmp_dir, "oxigraph.bog.ttl"))
  end

  defp assert_selected_adapter(file, selected_adapter, disabled_adapters) do
    lines =
      file
      |> File.read!()
      |> String.split("\n")

    configured_adapters =
      lines
      |> Enum.map(fn line ->
        case Regex.run(~r/og:serviceStore \[ :this ([a-zA-Z]+):([a-zA-Z]+)\s*\]/, line) do
          [_, prefix, adapter] ->
            {
              case {prefix, adapter} do
                {"og", "Store"} ->
                  Store

                {"oga", adapter_class} ->
                  assert adapter = Store.Adapter.type(adapter_class)
                  adapter
              end,
              not (line |> String.trim_leading() |> String.starts_with?("#"))
            }

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    assert configured_adapters[selected_adapter]

    Enum.each(disabled_adapters, fn disabled_adapter ->
      assert Map.has_key?(configured_adapters, disabled_adapter)
      assert configured_adapters[disabled_adapter] == false
    end)
  end
end
