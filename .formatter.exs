locals_without_parens = [
  api: 1,
  include_api: 1
]

[
  inputs: ["{mix,.formatter,.credo,.dialyzer_ignore,.iex}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:rdf, :grax, :sparql],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
