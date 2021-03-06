# SmsPilot API v1 client

[![Gem Version](https://badge.fury.io/rb/sms-pilot-api-v1.svg)](https://badge.fury.io/rb/sms-pilot-api-v1)
[![Maintainability](https://api.codeclimate.com/v1/badges/42765c3098d5f531a3f7/maintainability)](https://codeclimate.com/github/sergeypedan/sms-pilot-api-v1/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/42765c3098d5f531a3f7/test_coverage)](https://codeclimate.com/github/sergeypedan/sms-pilot-api-v1/test_coverage)
[![Inch CI documentation](https://inch-ci.org/github/sergeypedan/sms-pilot-api-v1.svg?branch=master&amp;style=flat)](https://inch-ci.org/github/sergeypedan/sms-pilot-api-v1)

Simple wrapper around SMS pilot API v1. Version 1 because it returns more data within its standard response.

## Installation

from RubyGems:

```ruby
gem "sms-pilot-api-v1"
```

from GitHub:

```ruby
gem "sms-pilot-api-v1", git: "https://github.com/sergeypedan/sms-pilot-api-v1.git"
```

## Playground

Test sending SMS from console with a test API key (find it at the end of this page):

```sh
cd $(bundle info sms-pilot-api-v1 --path)
bin/console
```


## Usage

### Initialize

```ruby
require "sms_pilot"

key = "XXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZXXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZ"

client = SmsPilot::Client.new(api_key: key)
client = SmsPilot::Client.new(api_key: key, locale: :en) # Available locales are [:en, :ru]
```

Method [documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client#initialize-instance_method) at RubyDoc.

### Before sending

There are a bunch of methods describing the state of affairs:

```ruby
client.api_key          # => "YOUR API KEY"
client.balance          # => nil
client.broadcast_id     # => nil
client.error            # => nil
client.phone            # => nil
client.rejected?        # => false
client.response_body    # => nil
client.response_data    # => {}
client.response_headers # => {}
client.response_status  # => nil
client.sender_blocked?  # => false
client.sms_cost         # => nil
client.sms_sent?        # => false
client.sms_status       # => nil
client.url              # => nil
```

before the request is sent they return obvious nils or empty structures; after the request they are populated with data.

See [structured documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client) for those methods at RubyDoc.

### Sending SMS

```ruby
client.send_sms("+7 (902) 123-45-67", "????????????, ??????!")
client.send_sms("+7 (902) 123-45-67", "????????????, ??????!", "????????????")
# => true
```

Returns result of `sms_sent?`, so it???s either `true` or `false`.

Method [documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client#send_sms-instance_method) at RubyDoc.

### Sending SMS succeeded

```ruby
client.api_key          # => "YOUR API KEY"
client.balance          # => 20006.97
client.broadcast_id     # => 10000
client.error            # => nil
client.phone            # => "79021234567"
client.rejected?        # => false
client.response_body    # => "{\"send\":[{\"server_id\":\"10000\",\"phone\":\"79021234567\",\"price\":\"1.68\",\"status\":\"0\"}],\"balance\":\"20006.97\",\"cost\":\"1.68\"}"
client.response_data    # => {"send"=>[{"server_id"=>"10000", "phone"=>"79021234567", "price"=>"1.68", "status"=>"0"}], "balance"=>"20006.97", "cost"=>"1.68"}
client.response_headers # => {"Server"=>"nginx", "Date"=>"Thu, 06 May 2021 04:52:58 GMT", "Content-Type"=>"application/json; charset=utf-8", "Content-Length"=>"179", "Connection"=>"close", "Access-Control-Allow-Origin"=>"*"}
client.response_status  # => 200
client.sender_blocked?  # => false
client.sms_cost         # => 1.68
client.sms_sent?        # => true
client.sms_status       # => 1
client.url              # => "https://smspilot.ru/api.php?apikey=1234567890&format=json&send=%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82%2C+%D0%BC%D0%B8%D1%80%21&to=79021234567"
```

### Sending SMS failed (but HTTP request succeeded)

```ruby
client.api_key          # => "YOUR API KEY"
client.balance          # => nil
client.broadcast_id     # => nil
client.error            # => "???????????????????????? API-???????? (????. ?????????????????? API ?? ???????????? ????????????????) (?????? ????????????: 101)"
client.phone            # => "79021234567"
client.rejected?        # => true
client.response_body    # => "{\"error\":{\"code\":\"101\",\"description\":\"APIKEY is invalid\",\"description_ru\":\"???????????????????????? API-???????? (????. ?????????????????? API ?? ???????????? ????????????????)\"}}"
client.response_data    # => {"error"=>{"code"=>"101", "description"=>"APIKEY is invalid", "description_ru"=>"???????????????????????? API-???????? (????. ?????????????????? API ?? ???????????? ????????????????)"}}
client.response_headers # => {"Server"=>"nginx", "Date"=>"Thu, 06 May 2021 04:52:58 GMT", "Content-Type"=>"application/json; charset=utf-8", "Content-Length"=>"179", "Connection"=>"close", "Access-Control-Allow-Origin"=>"*"}
client.response_status  # => 200
client.sender_blocked?  # => false
client.sms_cost         # => nil
client.sms_sent?        # => false
client.sms_status       # => nil
client.url              # => "https://smspilot.ru/api.php?apikey=1234567890&format=json&send=%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82%2C+%D0%BC%D0%B8%D1%80%21&to=79021234567"
```

### HTTP request failed

```ruby
client.api_key          # => "YOUR API KEY"
client.balance          # => nil
client.broadcast_id     # => nil
client.error            # => "HTTP request failed with code 404"
client.phone            # => "79021234567"
client.rejected?        # => false
client.response_body    # => "<html>\r\n<head><title>404 Not Found</title></head>\r\n<body>\r\n<center><h1>404 Not Found</h1></center>\r\n<hr><center>nginx</center>\r\n</body>\r\n</html>\r\n"
client.response_data    # => {}
client.response_headers # => {"Server"=>"nginx", "Date"=>"Thu, 06 May 2021 05:30:23 GMT", "Content-Type"=>"text/html", "Content-Length"=>"146", "Connection"=>"close"}
client.response_status  # => 404
client.sender_blocked?  # => false
client.sms_cost         # => nil
client.sms_sent?        # => false
client.sms_status       # => nil
client.url              # => "https://smspilot.ru/api.php?apikey=1234567890&format=json&send=%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82%2C+%D0%BC%D0%B8%D1%80%21&to=79021234567"
```


## SMS pilot API docs

- [Web version](https://smspilot.ru/apikey.php) ?????????. ?????????????? PHP, ?? ?????????????????? ???????????? ??????
- [PDF version](https://smspilot.ru/download/SMSPilotRu-HTTP-v1.9.19.pdf) ??????????? ?????????????? ??????????????????
- [API error code](https://smspilot.ru/apikey.php#err)


## Test API key

https://smspilot.ru/apikey.php

```
"XXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZXXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZ"
```


## API response examples

SMS sent:

```json
{
  "balance": "11908.50",
  "cost": "1.68",
  "send": [
    { "server_id": "10000", "phone": "79021234567", "price": "1.68", "status": "0" }
  ]
}
```

SMS rejected:

```json
{
  "error": {
    "code": "400",
    "description": "User not found",
    "description_ru": "???????????????????????? ???? ????????????"
  }
}
```


## Documentation

See [structured documentation](https://rubydoc.info/github/sergeypedan/sms-pilot-api-v1/master/SmsPilot/Client) at RubyDoc.


## Roadmap

- [ ] Switch to POST to escape 1024 symbolos GET request limit
- [ ] Switch to result object pattern
- [ ] ???????????????? ???????????????? SMS
- [ ] ???????????????? ??????????????
- [ ] ???????????????????? ?? ????????????????????????
