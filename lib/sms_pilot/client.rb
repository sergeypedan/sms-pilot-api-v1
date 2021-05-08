# frozen_string_literal: true

require "json"
require "net/https"
require "uri"

module SmsPilot

  # @!attribute [r] api_key
  #   @return [String] Your API key.
  #
  # @!attribute [r] error
  #   Error message returned from the API, combined with the error code
  #   @example
  #     client.error #=> "Пользователь временно блокирован (спорная ситуация) (error code: 122)"
  #   @return [nil, String]
  #   @see #error_code
  #   @see #error_description
  #
  # @!attribute [r] response_body
  #   Response format is JSON (because we request it that way in {#build_uri}.
  #   @example
  #     "{\"send\":[{\"server_id\":\"10000\",\"phone\":\"79021234567\",\"price\":\"1.68\",\"status\":\"0\"}],\"balance\":\"20006.97\",\"cost\":\"1.68\"}"
  #   @return [nil, String] Unmodified HTTP resonse body that API returned
  #   @see #response_data
  #   @see #response_headers
  #   @see #response_status
  #
  # @!attribute [r] response_data
  #   Parsed <tt>@response_body</tt>. May be an empty <tt>Hash</tt> if parsing fails.
  #   @example
  #     {
  #       "balance" => "20006.97",
  #       "cost" => "1.68",
  #       "send" => [
  #         {
  #           "phone" => "79021234567",
  #           "price" => "1.68",
  #           "server_id" => "10000",
  #           "status" => "0"
  #         }
  #       ]
  #     }
  #   @return [Hash]
  #   @see #response_body
  #   @see #response_headers
  #   @see #response_status
  #
  # @!attribute [r] response_headers
  #   @example
  #     {
  #       "Access-Control-Allow-Origin" => "*",
  #       "Connection" => "close",
  #       "Content-Length" => "179",
  #       "Content-Type" => "application/json; charset=utf-8",
  #       "Date" => "Thu, 06 May 2021 04:52:58 GMT",
  #       "Server" => "nginx"
  #     }
  #   @return [nil, String] Unmodified HTTP resonse headers that API returned.
  #   @see #response_body
  #   @see #response_data
  #   @see #response_status
  #
  # @!attribute [r] response_status
  #   HTTP status of the request to the API. 200 in case of success.
  #   @example
  #     client.response_status #=> 200
  #
  #   @return [nil, Integer]
  #   @see #response_body
  #   @see #response_data
  #   @see #response_headers
  #
  # @!attribute [r] url
  #   @example
  #     client.url #=> "https://smspilot.ru/api.php?api_key=XXX&format=json&send=TEXT&to=79021234567"
  #   @return [String] URL generated by combining <tt>API_ENDPOINT</tt>, your API key, SMS text & phone
  #
  class Client

    # Check current API endpoint URL at {https://smspilot.ru/apikey.php#api1}
    #
    API_ENDPOINT = "https://smspilot.ru/api.php".freeze

    attr_reader :api_key
    attr_reader :error
    attr_reader :phone
    attr_reader :response_body
    attr_reader :response_data
    attr_reader :response_headers
    attr_reader :response_status
    attr_reader :url


    # @param api_key [String]
    # @return [SmsPilot::Client]
    # @raise [SmsPilot::InvalidAPIkeyError] if you pass anything but a non-empty String
    # @see https://smspilot.ru/my-settings.php Get your production API key here
    # @see https://smspilot.ru/apikey.php Get your development API key here
    # @note Current development API key is <tt>"XXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZXXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZ"</tt>
    #
    # @example
    #   client = SmsPilot::Client.new(api_key: ENV["SMS_PILOT_API_KEY"])
    #
    def initialize(api_key:)
      fail SmsPilot::InvalidAPIkeyError, "API key must be a String, you pass a #{api_key.class} (#{api_key})" unless api_key.is_a? String
      fail SmsPilot::InvalidAPIkeyError, "API key cannot be empty" if api_key == ""

      @api_key          = api_key
      @error            = nil
      @response_status  = nil
      @response_headers = {}
      @response_body    = nil
      @response_data    = {}
      @url              = nil
    end


    # @!group Main

    # Send HTTP request to the API to ask them to transmit your SMS
    #
    # @return [Boolean] <tt>true</tt> if the SMS has been sent, <tt>false</tt> otherwise
    #
    # @param [String] phone The phone to send the SMS to. In free-form, will be sanitized.
    # @param [String] text The text of your message.
    #
    # @raise [SmsPilot::InvalidPhoneError] if you pass anythig but a String with the <tt>phone</tt> argument
    # @raise [SmsPilot::InvalidMessageError] if you pass anythig but a String with the <tt>text</tt> argument
    # @raise [SmsPilot::InvalidMessageError] if your text is empty
    # @raise [SmsPilot::InvalidPhoneError] if your phone is empty
    # @raise [SmsPilot::InvalidPhoneError] if your phone has no digits
    #
    # @example
    #   client.send_sms("+7 (902) 123-45-67", "Привет, мир!") # => true
    #
    def send_sms(phone, text)
      fail SmsPilot::InvalidPhoneError,  "`phone` must be a String, you pass a #{phone.class} (#{phone})" unless phone.is_a? String
      fail SmsPilot::InvalidMessageError, "`text` must be a String, you pass a #{ text.class} (#{ text})" unless text.is_a? String
      fail SmsPilot::InvalidPhoneError,  "`phone` cannot be empty" if phone == ""
      fail SmsPilot::InvalidMessageError, "`text` cannot be empty" if  text == ""
      fail SmsPilot::InvalidPhoneError,  "`phone` must contain digits" if phone.scan(/\d/).none?

      @phone = normalize_phone(phone)
      uri    = build_uri(@phone, text)
      @url   = uri.to_s

      response = Net::HTTP.get_response(uri)
      @response_status  = response.code.to_i
      @response_headers = response.header
      @response_body    = response.body

      unless response.code == "200"
        @error = "HTTP request failed with code #{response.code}"
        return false
      end

      @response_data = JSON.parse @response_body

      return @error = "#{error_description} (error code: #{error_code})" if rejected?
      return true

    rescue JSON::ParserError => error
      @error = "API returned invalid JSON. #{error.message}"

    rescue SocketError, EOFError, IOError, SystemCallError,
           Timeout::Error, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
           Net::ProtocolError, OpenSSL::SSL::SSLError => error
      @error = error.message

    rescue => error
      @error = error.message
    end

    # @!endgroup


    # @!group State accessors

    # Your current balance, remaining after sending that latest SMS.
    #
    # @return [nil, Float] Always <tt>nil</tt> before you send SMS and if the SMS was not sent, always Float after successfull SMS transmission.
    # @example
    #   client.balance #=> 20215.25
    #
    def balance
      @response_data["balance"]&.to_f if sms_sent?
    end


    # Numerical code of the error that occured when sending the SMS. In the range from 0 to 715 (which may change).
    #
    # @return [nil, Integer] <tt>nil</tt> is returned before sending SMS. Otherwise <tt>Integer</tt>
    # @example
    #   client.error_code #=> 122
    # @see #error
    # @see #error_description
    # @see https://smspilot.ru/apikey.php#err Error codes at the API documentation website
    #
    def error_code
      @response_data.dig("error", "code")&.to_i if rejected?
    end


    # Description of the error that occured when sending the SMS
    #
    # @return [nil, String] <tt>nil</tt> is returned before sending SMS. Otherwise <tt>String</tt>
    # @example
    #   client.error_description #=> "Пользователь временно блокирован (спорная ситуация)"
    # @see #error
    # @see #error_code
    # @see https://smspilot.ru/apikey.php#err Error codes at the API documentation website
    #
    def error_description
      @response_data.dig("error", "description_ru") if rejected?
    end


    # Did the API reject your request to send that SMS
    #
    # @return [Boolean] <tt>false</tt> is returned before sending SMS. Otherwise the <tt>Boolean</tt> corresponds to whether your request to send an SMS was rejected.
    # @example
    #   client.rejected? #=> false
    #
    def rejected?
      return false if sms_sent?
      @response_data["error"].is_a? Hash
    end


    # Did the API block you
    #
    # Error code | Description
    # :---|:------------------
    # 105 | из-за низкого баланса
    # 106 | за спам/ошибки
    # 107 | за недостоверные учетные данные / недоступна эл. почта / проблемы с телефоном
    # 122 | спорная ситуация
    #
    # @return [Boolean] <tt>nil</tt> is returned before sending SMS. Otherwise the <tt>Boolean</tt> corresponds to whether the API has blocked you.
    # @example
    #   client.sender_blocked? #=> false
    # @see #error
    # @see https://smspilot.ru/apikey.php#err Error codes at the API documentation website
    #
    def sender_blocked?
      [105, 106, 107, 122].include? error_code
    end


    # The cost of the SMS that has just been sent, in RUB
    #
    # @return [nil, Float]
    # @example
    #   client.sms_cost #=> 2.63
    #
    def sms_cost
      @response_data["cost"] if sms_sent?
    end


    # Has the SMS transmission been a success.
    #
    # @return [Boolean] <tt>nil</tt> is returned before sending SMS. Otherwise the <tt>Boolean</tt> corresponds to the result of SMS transmission.
    # @see #sms_status
    # @see #rejected?
    # @see #error
    #
    # @example
    #   client.sms_sent? #=> true
    #
    def sms_sent?
      @response_data["send"] != nil
    end


    # SMS delivery status, as returned by the API
    #
    # @return [nil, Integer] <tt>nil</tt> is returned before sending SMS or if the request was rejected. Otherwise an <tt>Integer</tt> in the range of [-2..3] is returned.
    # @see https://smspilot.ru/apikey.php#status List of available statuses at API documentation website
    #
    # Code | Name          | Final? | Description
    # ----:|:--------------|:-------|:-------------
    # -2   | Ошибка        | Да     | Ошибка, неправильные параметры запроса
    # -1   | Не доставлено | Да     | Сообщение не доставлено (не в сети, заблокирован, не взял трубку), PING — не в сети, HLR — не обслуживается (заблокирован)
    #  0   | Новое         | Нет    | Новое сообщение/запрос, ожидает обработки у нас на сервере
    #  1   | В очереди     | Нет    | Сообщение или запрос ожидают отправки на сервере оператора
    #  2   | Доставлено    | Да     | Доставлено, звонок совершен, PING — в сети, HLR — обслуживается
    #  3   | Отложено      | Нет    | Отложенная отправка, отправка сообщения/запроса запланирована на другое время
    #
    # @example
    #   client.sms_status #=> 2
    #
    def sms_status
      @response_data.dig("send", 0, "status")&.to_i if sms_sent?
    end

    # @!endgroup


    # The URI we will send an HTTP request to
    #
    # @private
    # @return [URI]
    # @raise [URI::InvalidURIError] but is very unlikely because we provide the URL ourselves
    #
    # @example
    #   build_uri("79021234567", "Hello, World!")
    #   #=> #<URI::HTTPS https://smspilot.ru/api.php?apikey=XXX…&format=json&send=Hello%2C+World%21&to=79021234567>
    #
    private def build_uri(phone, text)
      URI.parse(API_ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form({ apikey: @api_key, format: :json, send: text, to: phone })
      end
    end


    # Cleans up your phone from anything but digits. Also replaces 8 to 7 if it is the first digit.
    #
    # @private
    # @return [String]
    #
    # @example
    #   normalize_phone("8 (902) 123-45-67") #=> 79021234567
    #   normalize_phone("+7-902-123-45-67")  #=> 79021234567
    #
    private def normalize_phone(phone)
      phone.gsub(/[^0-9]/, '').sub(/^8/, '7').gsub('+7', '8')
    end

  end
end
