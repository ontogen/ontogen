import Config

config :mud,
  i_class: Ontogen.NS.Og.Agent

config :tesla, adapter: Tesla.Adapter.Hackney

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

import_config "#{Mix.env()}.exs"
