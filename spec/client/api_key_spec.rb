# frozen_string_literal: true

RSpec.describe SmsPilot::Client, "#api_key" do

  let(:api_key) { "11223344556677889900" }
  let(:object) { described_class.new(api_key: api_key) }

  subject { object.api_key }

  it { is_expected.to eq api_key }

end
