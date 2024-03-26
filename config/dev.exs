import Config

config :ontogen,
  create_repo_id_file: :env

config :magma,
  default_tags: ["magma-vault"]

config :openai,
  api_key: {:system, "OPENAI_API_KEY"},
  organization_key: {:system, "OPENAI_ORGANIZATION_KEY"},
  http_options: [recv_timeout: 300_000]
