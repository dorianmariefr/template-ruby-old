require "spec_helper"

RSpec.describe Code::Parser::Name do
  subject { described_class.new.parse(input) }

  %w[
    user
    dorian
    User
    RSpec
    describe?
  ].each do |(input, expected)|
    context input.inspect do
      let(:input) { input }

      it "succeeds" do
        expect(subject).to eq({ name: input })
      end
    end
  end

  [
    "a b",
    "a[b",
    "a{b"
  ].each do |input|
    context input.inspect do
      let(:input) { input }

      it "fails" do
        expect { subject }.to raise_error(Parslet::ParseFailed)
      end
    end
  end
end
