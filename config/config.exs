import Config

config :ontogen,
  grax_id_spec: Ontogen.IdSpec

config :tesla, adapter: Tesla.Adapter.Hackney

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

import_config "#{Mix.env()}.exs"
