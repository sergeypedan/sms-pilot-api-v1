# frozen_string_literal: true

require "json"
require "net/https"
require "uri"

module SmsPilot

  # @!attribute [r] api_key
  #   @return [String] your API key
  #   @example
  #     client.api_key #=> "XXX..."
  #
  # @!attribute [r] error
  #   Error message returned from the API, combined with the error code
  #   @example
  #     client.error #=> "Пользователь временно блокирован (спорная ситуация) (error code: 122)"
  #   @return [nil, String]
  #   @see #error_code
  #   @see #error_description
  #
  # @!attribute [r] locale
  #   Chosen locale (affects only the language of errors)
  #
  #   @return [Symbol]
  #   @example
  #     client.locale #=> :ru
  #
  # @!attribute [r] phone
  #   @return [nil, String] phone after normalization
  #   @example
  #     client.phone #=> "79021234567"
  #
  # @!attribute [r] response_body
  #   Response format is JSON (because we request it that way in {#build_uri}).
  #   @example
  #     "{\"send\":[{\"server_id\":\"10000\",\"phone\":\"79021234567\",\"price\":\"1.68\",\"status\":\"0\"}],\"balance\":\"20006.97\",\"cost\":\"1.68\"}"
  #   @return [nil, String] Unmodified HTTP resonse body that API returned
  #   @see #response_data
  #   @see #response_headers
  #   @see #response_status
  #
  # @!attribute [r] response_headers
  #   @example
  #     client.response_headers #=>
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
  class Client

    # Check current API endpoint URL at {https://smspilot.ru/apikey.php#api1}
    #
    API_ENDPOINT = "https://smspilot.ru/api.php".freeze

    # Locale influences only the language of API errors
    #
    AVAILABLE_LOCALES = [:ru, :en].freeze

    REQUEST_ACCEPT_FORMAT = "json".freeze
    REQUEST_CHARSET = "utf-8".freeze

    attr_reader :api_key
    attr_reader :error
    attr_reader :locale
    attr_reader :phone
    attr_reader :response_body
    attr_reader :response_headers
    attr_reader :response_status


    # @param api_key [String]
    # @param locale [Symbol]
    #
    # @return [SmsPilot::Client]
    # @raise [SmsPilot::InvalidAPIkeyError] if you pass anything but a non-empty String
    # @raise [SmsPilot::InvalidLocaleError] if you pass anything but <tt>:ru</tt> or <tt>:en</tt>
    #
    # @see https://smspilot.ru/my-settings.php Get your production API key here
    # @see https://smspilot.ru/apikey.php Get your development API key here
    # @note Current development API key is <tt>"XXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZXXXXXXXXXXXXYYYYYYYYYYYYZZZZZZZZ"</tt>
    #
    # @example
    #   client = SmsPilot::Client.new(api_key: ENV["SMS_PILOT_API_KEY"])
    #   client = SmsPilot::Client.new(api_key: ENV["SMS_PILOT_API_KEY"], locale: :en)
    #
    def initialize(api_key:, locale: AVAILABLE_LOCALES[0])
      @api_key          = validate_api_key!(api_key)
      @error            = nil
      @locale           = validate_locale!(locale)
      @response_status  = nil
      @response_headers = {}
      @response_body    = nil
    end


    # @!group Main

    # Send HTTP request to the API to ask them to transmit your SMS
    #
    # @return [Boolean] <tt>true</tt> if the SMS has been sent, <tt>false</tt> otherwise
    #
    # @param [String] phone The phone to send the SMS to. In free-form, will be sanitized.
    # @param [String] message The text of your message.
    #
    # @raise [SmsPilot::InvalidPhoneError] if you pass anythig but a String with the <tt>phone</tt> argument
    # @raise [SmsPilot::InvalidMessageError] if you pass anythig but a String with the <tt>message</tt> argument
    # @raise [SmsPilot::InvalidMessageError] if your message is empty
    # @raise [SmsPilot::InvalidPhoneError] if your phone is empty
    # @raise [SmsPilot::InvalidPhoneError] if your phone has no digits
    # @raise [URI::InvalidURIError] but is almost impossible, because we provide the URL ourselves
    #
    # @example
    #   client.send_sms("+7 (902) 123-45-67", "Привет, мир!") # => true
    #   client.send_sms("+7 (902) 123-45-67", "Привет, мир!", "ФССПРФ") # => true
    #
    def send_sms(phone, message, sender_name = nil)
      validate_phone! phone
      validate_message! message
      validate_sender_name! sender_name

      @phone = normalize_phone(phone)
      @uri   = build_uri(@phone, message, sender_name)

      response = persist_response_details Net::HTTP.get_response(@uri)

      @error = "HTTP request failed with code #{response.code}"   and return false unless response.is_a?(Net::HTTPSuccess)
      @error = "#{error_description} (error code: #{error_code})" and return false if rejected?

      true

    rescue JSON::ParserError => error
      @error = "API returned invalid JSON. #{error.message}"
      return false

    rescue SocketError, EOFError, IOError, SystemCallError,
           Timeout::Error, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
           Net::ProtocolError, OpenSSL::SSL::SSLError => error
      @error = error.message
      return false
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
      response_data["balance"]&.to_f if sms_sent?
    end


    # SMS broadcast ID (API documentation calls it “server ID” but it makes no sense, as it is clearly the ID of the transmission, not of a server)
    #
    # @example
    #   client.broadcast_id #=> 10000
    #
    # @return [nil, Integer]
    #
    # @see #response_data
    #
    def broadcast_id
      @response_data.dig("send", 0, "server_id")&.to_i if sms_sent?
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
    #   client.broadcast_status #=> 2
    #
    # @see #sms_status
    #
    def broadcast_status
      @response_data.dig("send", 0, "status")&.to_i if sms_sent?
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
      method_name = (@locale == :ru) ? "description_ru" : "description"
      @response_data.dig("error", method_name) if rejected?
    end


    # Did the API reject your request to send that SMS
    #
    # @return [Boolean] <tt>false</tt> is returned before sending SMS. Otherwise the <tt>Boolean</tt> corresponds to whether your request to send an SMS was rejected.
    # @example
    #   client.rejected? #=> false
    #
    def rejected?
      return false if sms_sent?
      response_data["error"].is_a? Hash
    end


    # Parses <tt>@response_body</tt> and memoizes result in <tt>@response_data</tt>
    #
    # @example
    #   {
    #     "balance" => "20006.97",
    #     "cost" => "1.68",
    #     "send" => [
    #       {
    #         "phone" => "79021234567",
    #         "price" => "1.68",
    #         "server_id" => "10000",
    #         "status" => "0"
    #       }
    #     ]
    #   }
    #
    # @return [Hash]
    # @raise [JSON::ParserError] which is rescued in {#send_sms}
    #
    # @see #response_body
    # @see #response_headers
    # @see #response_status
    #
    def response_data
      return {} unless @response_body
      @response_data ||= JSON.parse @response_body
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
      response_data["cost"]&.to_f if sms_sent?
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
      response_data["send"] != nil
    end


    # @deprecated (in favor of {#broadcast_status})
    #
    def sms_status
      broadcast_status
    end


    # URL generated by combining <tt>API_ENDPOINT</tt>, your API key, SMS text & phone
    #
    # @example
    #   client.url #=> "https://smspilot.ru/api.php?api_key=XXX&format=json&send=TEXT&to=79021234567"
    #
    # @return [nil, String]
    #
    def url
      @uri&.to_s
    end

    # @!endgroup


    # The URI we will send an HTTP request to
    # @private
    #
    # @example
    #   build_uri("79021234567", "Hello, World!")
    #   #=> #<URI::HTTPS https://smspilot.ru/api.php?apikey=XXX…&format=json&send=Hello%2C+World%21&to=79021234567>
    #
    # @return [URI]
    # @raise [URI::InvalidURIError] but is almost impossible, because we provide the URL ourselves
    #
    # @param [String] phone
    # @param [String] text
    # @param [nil, String] sender_name
    #
    # @see #api_key
    # @see #phone
    # @see #validate_phone!
    # @see #validate_message!
    # @see #validate_sender_name!
    #
    private def build_uri(phone, text, sender_name)
      attributes = {
        apikey:  @api_key,
        charset: REQUEST_CHARSET,
        format:  REQUEST_ACCEPT_FORMAT,
        lang:    @locale,
        send:    text,
        to:      phone
      }
      attributes = attributes.merge({ sender: sender_name }) if sender_name

      URI.parse(API_ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(attributes)
      end
    end




    # Cleans up your phone from anything but digits. Also replaces 8 to 7 if it is the first digit.
    #
    # @private
    # @param [String] phone
    # @return [String]
    #
    # @example
    #   normalize_phone("8 (902) 123-45-67") #=> 79021234567
    #   normalize_phone("+7-902-123-45-67")  #=> 79021234567
    #
    private def normalize_phone(phone)
      phone.gsub(/[^0-9]/, '').sub(/^8/, '7').gsub('+7', '8')
    end


    # Saves response details into instance variables
    # @private
    #
    # @return [response]
    # @raise [TypeError] unless a Net::HTTPResponse passed
    #
    private def persist_response_details(response)
      fail TypeError, "Net::HTTPResponse expected, you pass a #{response.class}" unless response.is_a? Net::HTTPResponse
      @response_body    = response.body
      @response_status  = response.code.to_i
      @response_headers = response.each_capitalized.to_h
      response
    end


    # @!group Validations

    # Validates api_key
    #
    # @private
    # @return [String] the original value passed into the method, only if it was valid
    # @param [String] api_key
    #
    # @raise [SmsPilot::InvalidError] if api_key is not a String
    # @raise [SmsPilot::InvalidError] if api_key is an empty String
    #
    private def validate_api_key!(api_key)
      fail SmsPilot::InvalidAPIkeyError, "API key must be a String, you pass a #{api_key.class} (#{api_key})" unless api_key.is_a? String
      fail SmsPilot::InvalidAPIkeyError, "API key cannot be empty" if api_key == ""
      return api_key
    end


    # Validates locale
    #
    # @private
    # @return [Symbol] the original value passed into the method, only if it was valid
    # @param [Symbol] locale
    #
    # @raise [SmsPilot::InvalidError] if locale is not a Symbol
    # @raise [SmsPilot::InvalidError] if locale is unrecognized
    #
    private def validate_locale!(locale)
      fail SmsPilot::InvalidLocaleError, "locale must be a Symbol" unless locale.is_a? Symbol
      fail SmsPilot::InvalidLocaleError, "API does not support locale :#{locale}; choose one of #{AVAILABLE_LOCALES.inspect}" unless AVAILABLE_LOCALES.include? locale
      return locale
    end


    # Validates message
    # @private
    #
    # @param [String] message
    # @return [String] the original value passed into the method, only if it was valid
    #
    # @raise [SmsPilot::InvalidMessageError] if you pass anythig but a String with the <tt>message</tt> argument
    # @raise [SmsPilot::InvalidMessageError] if your message is empty
    #
    private def validate_message!(message)
      fail SmsPilot::InvalidMessageError, "SMS message must be a String, you pass a #{ message.class} (#{ message})" unless message.is_a? String
      fail SmsPilot::InvalidMessageError, "SMS message cannot be empty" if  message == ""
      message
    end


    # Validates phone
    # @private
    #
    # @param [String] phone
    # @return [String] the original value passed into the method, only if it was valid
    #
    # @raise [SmsPilot::InvalidPhoneError] if you pass anythig but a String with the <tt>phone</tt> argument
    # @raise [SmsPilot::InvalidPhoneError] if your phone is empty
    # @raise [SmsPilot::InvalidPhoneError] if your phone has no digits
    #
    private def validate_phone!(phone)
      fail SmsPilot::InvalidPhoneError, "phone must be a String, you pass a #{phone.class} (#{phone})" unless phone.is_a? String
      fail SmsPilot::InvalidPhoneError, "phone cannot be empty" if phone == ""
      fail SmsPilot::InvalidPhoneError, "phone must contain digits" if phone.scan(/\d/).none?
      phone
    end


    # Validates sender name
    # @private
    #
    # @param [nil, String] sender_name
    # @return [String] the original value passed into the method, only if it was valid
    #
    # @raise [SmsPilot::InvalidSenderNameError] if you pass anything but <tt>nil</tt> or non-empty <tt>String</tt>
    #
    private def validate_sender_name!(sender_name)
      fail SmsPilot::InvalidSenderNameError, "sender name must be either nil or String" unless [NilClass, String].include? sender_name.class
      fail SmsPilot::InvalidSenderNameError, "sender name cannot be empty" if sender_name == ""
      sender_name
    end

    # @!endgroup

  end
end
