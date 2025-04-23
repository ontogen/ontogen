import Config

config :mud,
  i_class: Ontogen.NS.Og.Agent

config :gno,
  env: Mix.env(),
  load_path: "config/ontogen",
  manifest_adapter: Ontogen.Manifest.Adapter

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
