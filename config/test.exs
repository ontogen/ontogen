import Config

config :ontogen,
  config_load_paths: [:local]

config :mud,
  index_directory: "tmp/test/data/mud/index",
  seed_path: "tmp/test/data/mud/seeds"
