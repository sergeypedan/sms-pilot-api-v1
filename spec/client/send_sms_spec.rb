# frozen_string_literal: true

RSpec.describe SmsPilot::Client, "#send_sms" do

  let(:api_key) { "11223344556677889900" }
  let(:client) { described_class.new(api_key: api_key) }

  subject { client.send_sms(phone, message, sender_name) }

  let(:message) { "Hello, World!" }
  let(:phone) { "+7 (902) 123-45-67" }
  let(:sender_name) { nil }

  context "invalid input" do

    describe "phone" do
      context "with nil phone" do
        let(:phone) { nil }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidPhoneError
        end
      end

      context "with Integer phone" do
        let(:phone) { 111 }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidPhoneError
        end
      end

      context "with empty phone" do
        let(:phone) { "" }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidPhoneError
        end
      end
    end

    describe "message" do
      context "with nil message" do
        let(:message) { nil }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidMessageError
        end
      end

      context "with Integer message" do
        let(:message) { 111 }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidMessageError
        end
      end

      context "with empty message" do
        let(:message) { "" }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidMessageError
        end
      end
    end

    describe "sender_name" do
      context "with Integer sender_name" do
        let(:sender_name) { 111 }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidSenderNameError
        end
      end

      context "with empty sender_name" do
        let(:sender_name) { "" }
        it do
          expect { subject }.to raise_exception SmsPilot::InvalidSenderNameError
        end
      end
    end
  end

  context "valid input" do
    let(:http_verb) { :get }
    let(:charset)  { SmsPilot::Client::REQUEST_CHARSET }
    let(:endpoint) { SmsPilot::Client::API_ENDPOINT }
    let(:format)   { SmsPilot::Client::REQUEST_ACCEPT_FORMAT }
    let(:lang)     { SmsPilot::Client::AVAILABLE_LOCALES[0] }
    let(:encoded_phone) { phone.scan(/\d/).join }
    let(:expected_url_base) { "#{endpoint}?apikey=#{api_key}&charset=#{charset}&format=#{format}" }
    let(:expected_url) { "#{expected_url_base}&lang=#{lang}&send=#{message}&to=#{encoded_phone}" }

    before(:each) {
      stub_request(:get, %r{#{endpoint}})
      subject
    }

    context "with default locale" do
      it do expect(a_request(http_verb, expected_url)).to have_been_made end
    end

    context "with explicit locale" do
      let(:lang) { :en }
      let(:client) { described_class.new(api_key: api_key, locale: lang) }
      it do expect(a_request(http_verb, expected_url)).to have_been_made end
    end

    context "with explicit sender name" do
      let(:sender_name) { "My username" }
      let(:expected_url) { "#{expected_url_base}&lang=#{lang}&send=#{message}&sender=#{sender_name}&to=#{encoded_phone}" }
      it do expect(a_request(http_verb, expected_url)).to have_been_made end
    end

  end

end
