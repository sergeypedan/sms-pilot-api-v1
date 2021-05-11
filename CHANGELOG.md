# Changelog

## [0.0.10] - 2021-05-11

### Added

- Accepts sender name in [`#initialize`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:initialize)
- Tests for `send_sms`

## [0.0.9] - 2021-05-10

### Added

- Passes `charset` attribute to the API in [`#build_uri`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:build_uri)
- Passes `lang` attribute to the API in [`#build_uri`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:build_uri)

### Changed

- Stores constant request params in constants

### Deprecated

- Deprecates [`#sms_status`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:sms_status) in favor of [`#broadcast_status`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:broadcast_status)

## [0.0.8] - 2021-05-10

### Added

- [`#broadcast_id`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:broadcast_id) method
- [roadmap section](https://github.com/sergeypedan/sms-pilot-api-v1#roadmap) in the Readme

## [0.0.7] - 2021-05-09

### Changed

- Returns original values from validation methods
- Offloads parsing response body to a method
- Improves documentation

### Added

- Adds CodeClimate badges
- Writes tests for [`#initialize`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:initialize)
- Writes tests for [`#api_key`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:api_key)

## [0.0.6] - 2021-05-09

### Fixed

- Corrects cost type

### Changed

- Switches to PRY in console

## [0.0.5] - 2021-05-09

### Added

- Adds locale support (RU / EN)

## [0.0.4] - 2021-05-09

### Fixed

- Corrects what [`#send_sms`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:send_sms) returns (could return String errors instead of Booleans)

### Changed

- Drop dependence on HTTP.rb gem

### Added

- Adds extensive [documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client) via YARD & RubyDoc

## [0.0.3] - 2021-05-06

- Initial release
