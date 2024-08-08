defmodule Ontogen.MixProject do
  use Mix.Project

  @scm_url "https://github.com/ontogen/ontogen"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :ontogen,
      version: @version,
      elixir: "~> 1.16",
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
      dialyzer: dialyzer(),

      # Docs
      name: "Ontogen",
      docs: docs()
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
      rdf_ex_dep(:grax, "~> 0.5"),
      rdf_ex_dep(:sparql_client, "~> 0.5"),
      rdf_ex_dep(:rtc, "~> 0.2"),
      rdf_ex_dep(:prov, "~> 0.1"),
      rdf_ex_dep(:dcat, "~> 0.1"),
      rdf_ex_dep(:foaf, "~> 0.1"),
      {:hkdf, "~> 0.2"},
      {:uniq, "~> 0.6"},
      # we are using YuriTemplate, because we have it already as a dependency of Grax
      {:yuri_template, "~> 1.1"},
      {:timex, "~> 3.7"},
      {:hackney, "~> 1.17"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      # This dependency is needed for ExCoveralls when OTP < 25
      {:castore, "~> 1.0", only: :test}
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

  defp docs do
    [
      main: "Ontogen",
      source_url: @scm_url,
      source_ref: "v#{@version}",
      logo: "logo-transparent.png",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: [
        {:"README.md", [title: "About"]},
        {:"CHANGELOG.md", [title: "CHANGELOG"]},
        {:"LICENSE.md", [title: "License"]}
      ],
      groups_for_modules: [
        Models: [
          Ontogen.Proposition,
          Ontogen.SpeechAct,
          Ontogen.Agent,
          Ontogen.Commit,
          Ontogen.Commit.Ref,
          Ontogen.Commit.Range,
          Ontogen.Repository,
          Ontogen.Dataset,
          Ontogen.History,
          Ontogen.Service,
          Ontogen.Store,
          Ontogen.Store.Adapter,
          Ontogen.Store.GenSPARQL,
          Ontogen.Store.SPARQL.Operation,
          Ontogen.Operation,
          Ontogen.Operation.Command,
          Ontogen.Operation.Query
        ],
        "Store Adapter": [
          Ontogen.Store.Adapters.Fuseki,
          Ontogen.Store.Adapters.Oxigraph,
          Ontogen.Store.Adapters.GraphDB
        ],
        Operations: [
          Ontogen.Operations.BootCommand,
          Ontogen.Operations.SetupCommand,
          Ontogen.Operations.CommitCommand,
          Ontogen.Operations.RevertCommand,
          Ontogen.Operations.CleanCommand,
          Ontogen.Operations.RepositoryQuery,
          Ontogen.Operations.DatasetQuery,
          Ontogen.Operations.EffectiveChangesetQuery,
          Ontogen.Operations.ChangesetQuery,
          Ontogen.Operations.RevisionQuery,
          Ontogen.Operations.HistoryQuery,
          Ontogen.Operations.DiffQuery
        ],
        "History Types": [
          Ontogen.HistoryType,
          Ontogen.HistoryType.Native,
          Ontogen.HistoryType.Raw,
          Ontogen.HistoryType.Formatter
        ],
        Config: [
          Ontogen.Config,
          Ontogen.Config.Generator
        ],
        Bog: [
          Ontogen.Bog,
          Ontogen.Bog.Precompiler,
          Ontogen.Bog.Referencable
        ],
        Namespaces: [
          Ontogen.NS,
          Ontogen.NS.Og,
          Ontogen.NS.OgA,
          Ontogen.NS.Bog
        ]
      ]
    ]
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
