locals_without_parens = []

[
  inputs: ["{mix,.formatter,.credo,.dialyzer_ignore,.iex}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:rdf, :grax, :sparql],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
