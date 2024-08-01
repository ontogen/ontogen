defmodule Ontogen.MixProject do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :ontogen,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],

      # Dialyzer
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Ontogen.Application, []}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      ignore_warnings: ".dialyzer_ignore.exs",
      # Error out when an ignore rule is no longer useful so we can remove it
      list_unused_filters: true
    ]
  end

  defp deps do
    [
      rdf_ex_dep(:rdf, "~> 2.0"),
      rdf_ex_dep(:grax, "~> 0.4"),
      rdf_ex_dep(:sparql_client, "~> 0.4"),
      rdf_ex_dep(:rtc, "~> 0.1"),
      rdf_ex_dep(:prov, "~> 0.1"),
      rdf_ex_dep(:dcat, "~> 0.1"),
      rdf_ex_dep(:foaf, "~> 0.1"),
      {:hkdf, "~> 0.2"},
      {:uniq, "~> 0.6"},
      # we are using YuriTemplate, because we have it already as a dependency of Grax
      {:yuri_template, "~> 1.1"},
      {:hackney, "~> 1.17"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: [:dev, :test], runtime: false},
      {:magma, path: "../../../Magma/src/magma", only: [:dev, :test], runtime: true},
      {:openai, "~> 0.6", only: [:dev, :test]},
      {:excoveralls, "~> 0.16", only: :test}
    ]
  end

  defp rdf_ex_dep(:rtc, version) do
    case System.get_env("RDF_EX_PACKAGES_SRC") do
      "LOCAL" -> {:rtc, path: "../../../RTC/src/rtc-ex"}
      _ -> {:rtc, version}
    end
  end

  defp rdf_ex_dep(dep, version) do
    case System.get_env("RDF_EX_PACKAGES_SRC") do
      "LOCAL" -> {dep, path: "../../../RDF.ex/src/#{dep}"}
      _ -> {dep, version}
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "test --warnings-as-errors",
        "credo"
      ]
    ]
  end
end
