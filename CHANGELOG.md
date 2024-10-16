# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## v0.1.2 - 2024-10-16

### Fixed

- Remove timeouts that were caused by the internally used HTTP client used
  for SPARQL access
- Failure to connect to the configured SPARQL server resulted in a 
  "no function clause matching" error. 
- Fix indentation in service config template used on init


[Compare v0.1.1...v0.1.2](https://github.com/ontogen/ontogen/compare/v0.1.1...v0.1.2)



## v0.1.1 - 2024-08-20

### Fixed

- Introduce `Ontogen.ansi_enabled?/0` as the new default fallback for color output.
  This change decouples color support from `IO.ANSI.enabled?/0`, addressing issues
  with Burrito executables built in CI environments where `IO.ANSI.enabled?/0`
  may not consistently return `:true`. This ensures more reliable color output
  across different build and runtime environments.
  

[Compare v0.1.0...v0.1.1](https://github.com/ontogen/ontogen/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2024-08-08

Initial release
