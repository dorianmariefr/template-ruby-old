require "spec_helper"

RSpec.describe "function" do
  it "converts nil" do
    expect(Code::Ruby.from_code(Code.evaluate("a", ruby: { a: nil }))).to eq(nil)
  end

  it "works with downcase" do
    expect(Code.evaluate("downcase", "{ downcase: 1 }")).to eq(1)
  end

  it "works with nested objects" do
    expect(
      Code.evaluate(
        "items.first.title",
        ruby: { items: [{ title: "Hello" }] }
      )
    ).to eq("Hello")
  end

  it "works with arrays" do
    expect(
      Code.evaluate(
        "items.map { |item| item.title }",
        ruby: { items: [{ title: "Hello" }] }
      )
    ).to eq(["Hello"])
  end
end
