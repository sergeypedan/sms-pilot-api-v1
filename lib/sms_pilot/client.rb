# frozen_string_literal: true

require "http"
require "uri"

module SmsPilot

  API_ENDPOINT = "https://smspilot.ru/api.php".freeze

  class Client

    attr_reader :api_key
    attr_reader :error
    attr_reader :phone
    attr_reader :response_body
    attr_reader :response_data
    attr_reader :response_headers
    attr_reader :response_status
    attr_reader :url


    def initialize(api_key:)
      fail TypeError, "API key must be a String, you pass a #{api_key.class} (#{api_key})" unless api_key.is_a? String
      fail TypeError, "API key cannot be empty" if api_key == ""

      @api_key          = api_key
      @error            = nil
      @response_status  = nil
      @response_headers = nil
      @response_body    = nil
      @response_data    = {}
      @url              = nil
    end

    def send_sms(phone, text)
      fail TypeError, "`phone` must be a String, you pass a #{phone.class} (#{phone})" unless phone.is_a? String
      fail TypeError,  "`text` must be a String, you pass a #{ text.class} (#{ text})" unless text.is_a? String
      fail ArgumentError, "`phone` cannot be empty" if phone == ""
      fail ArgumentError,  "`text` cannot be empty" if  text == ""
      fail ArgumentError, "`phone` must contain digits" if phone.scan(/\d/).none?

      @phone = normalize_phone(phone)
      @url   = build_url(@phone, text)

      response = HTTP.timeout(connect: 15, read: 30).accept(:json).get(@url)
      @response_status  = response.status.code
      @response_headers = response.headers.to_h
      @response_body    = response.body.to_s

      unless response.status.success?
        @error = "HTTP request failed with code #{response.status.code}"
        return false
      end

      @response_data = JSON.parse @response_body

      return @error = "#{error_description} (код ошибки: #{error_code})" if rejected?
      return true

    rescue JSON::ParserError => error
      @error = "API returned invalid JSON. #{error.message}"

    rescue HTTP::Error => error
      @error = error.message

    rescue => error
      @error = error.message
    end

    # Your current balance, remaining after sending that latest SMS.
    #
    # @return [nil, Float] Always nil before you send SMS. If it still returns `nil` after successful sending, it may mean the API has changed.
    #
    def balance
      @response_data["balance"]&.to_f if sms_sent?
    end


    # Коды ошибок: https://smspilot.ru/apikey.php#err
    # Error description is in <tt>#error</tt>
    # @see #error
    # @return nil or Integer
    #
    def error_code
      @response_data.dig("error", "code")&.to_i if rejected?
    end


    # Коды ошибок: https://smspilot.ru/apikey.php#err
    # Error description is in <tt>#error</tt>
    # @see #error
    #
    def error_description
      @response_data.dig("error", "description_ru") if rejected?
    end


    # HTTP запрос удался, но API отказался отправлять SMS
    def rejected?
      return false if sms_sent?
      @response_data["error"].is_a? Hash
    end


    # API verdict on whether you have been blocked.
    #
    # Error code | Description
    # :---|:------------------
    # 105 | из-за низкого баланса
    # 106 | за спам/ошибки
    # 107 | за недостоверные учетные данные / недоступна эл. почта / проблемы с телефоном
    # 122 | спорная ситуация
    #
    # @see #error
    #
    def sender_blocked?
      [105, 106, 107, 122].include? error_code
    end


    # The cost of the SMS that has just been sent
    #
    # @return [nil, Integer]
    #
    def sms_cost
      @response_data["cost"] if sms_sent?
    end


    # Has the SMS transmission been a success.
    #
    # @return [Boolean]
    #
    def sms_sent?
      @response_data["send"] != nil
    end


    # SMS delivery status, as returned by the API.
    #
    # @see https://smspilot.ru/apikey.php#status List of available statuses at API documentation website
    #
    # @return [nil, Integer]
    #
    def sms_status
      @response_data.dig("send", 0, "status")&.to_i if sms_sent?
    end


    private

    def build_url(phone, text)
      URI.parse(API_ENDPOINT).tap do |url|
        url.query = URI.encode_www_form({ apikey: @api_key, format: :json, send: text, to: phone })
      end.to_s
    end

    def normalize_phone(phone)
      phone.gsub(/[^0-9]/, '').sub(/^8/, '7').gsub('+7', '8')
    end

  end
end
