# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Changed

- Migration to the extracted Mud processor (previously called Bog)
  - All Ontogen configuration files now use the `.og.ttl` extension instead of 
    `.bog.ttl`.
  - Due to changes in the UUIDv5 URI generation algorithm, salts from previous 
    versions of Ontogen will now generate different URIs. 
- The paths of the global configuration files have changed:
  - the system-wide config is now searched for at `/etc/og.ttl`
  - the user config is now searched for at `~/.og.ttl`


[Compare v0.1.2...HEAD](https://github.com/ontogen/ontogen/compare/v0.1.2...HEAD)



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
