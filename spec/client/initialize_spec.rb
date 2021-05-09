# frozen_string_literal: true

RSpec.describe SmsPilot::Client, ".new" do

  context "with an empty API key" do
    it do
      expect { described_class.new(api_key: "") }.to raise_exception SmsPilot::InvalidAPIkeyError
    end
  end

  context "with a nil API key" do
    it do
      expect { described_class.new(api_key: "") }.to raise_exception SmsPilot::InvalidAPIkeyError
    end
  end

  context "with a non-empty String API key" do
    context "without locale" do
      it do
        expect { described_class.new(api_key: "1111222233334444") }.not_to raise_exception
      end
    end

    context "with a valid locale" do
      it do
        expect { described_class.new(api_key: "1111222233334444", locale: :en) }.not_to raise_exception
        expect { described_class.new(api_key: "1111222233334444", locale: :ru) }.not_to raise_exception
      end
    end

    context "with an invalid locale" do
      it do
        expect { described_class.new(api_key: "1111222233334444", locale: :es) }.to raise_exception SmsPilot::InvalidLocaleError
      end
    end
  end

end
