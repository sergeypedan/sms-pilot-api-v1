# Changelog

## [0.0.9] - 10 May 2021

- Passes `charset` attribute to the API in [`#build_uri`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:build_uri)
- Passes `lang` attribute to the API in [`#build_uri`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:build_uri)

## [0.0.8] - 10 May 2021

- Adds [`#broadcast_id`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:broadcast_id) method
- Adds [roadmap section](https://github.com/sergeypedan/sms-pilot-api-v1#roadmap) in the Readme

## [0.0.7] - 9 May 2021

- Returns original values from validation methods
- Offloads parsing response body to a method
- Improves documentation
- Adds CodeClimate badges
- Writes tests for [`#initialize`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:initialize)
- Writes tests for [`#api_key`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:api_key)

## [0.0.6] - 9 May 2021

- Corrects cost type
- Switches to PRY in console

## [0.0.5] - 9 May 2021

- Adds locale support (RU / EN)

## [0.0.4] - 9 May 2021

- Drop dependence on HTTP.rb gem
- Corrects what [`#send_sms`](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot%2FClient:send_sms) returns (could return String errors instead of Booleans)
- Adds extensive [documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client) via YARD & RubyDoc

## [0.0.3] - 6 May 2021

- Initial release
