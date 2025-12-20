import Config

config :mud,
  i_class: Ontogen.NS.Og.Agent

config :dcatr,
  env: Mix.env(),
  manifest_type: Ontogen.Manifest,
  load_path: "config/ontogen"

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
