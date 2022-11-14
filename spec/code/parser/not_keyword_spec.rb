require "spec_helper"

RSpec.describe ::Code::Parser do
  subject { ::Code::Parser.parse(input) }

  ["not a", "not not a"].each do |input|
    context input do
      let!(:input) { input }

      it { subject }
    end
  end

  ["not /* cool */ a", "not not /* cool */ a"].each do |input|
    context input do
      let!(:input) { input }

      it { expect(subject.to_json).to include("cool") }
    end
  end
end
