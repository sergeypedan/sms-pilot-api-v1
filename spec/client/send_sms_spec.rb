# frozen_string_literal: true

RSpec.describe SmsPilot::Client, "#send_sms" do

  let(:api_key) { "11223344556677889900" }
  let(:client) { described_class.new(api_key: api_key) }

  subject { client.send_sms(phone, message, sender_name) }

  let(:message) { "Hello, World!" }
  let(:phone) { "79021234567" }
  let(:sender_name) { "My username" }

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

    context "with non-empty message" do
      it do
        expect { subject }.not_to raise_exception
      end
    end
  end

end
