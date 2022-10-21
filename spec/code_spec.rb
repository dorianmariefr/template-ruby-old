require "spec_helper"

RSpec.describe Code do
  let!(:input) { "" }
  let!(:context) { "" }
  let!(:io) { StringIO.new }
  let!(:timeout) { 0.1 }
  let!(:ruby) { {} }

  subject do
    Code.evaluate(input, context, io: io, timeout: timeout, ruby: ruby).to_s
  end

  [
    ["nothing", ""],
    ["null", ""],
    ["nil", ""],
    %w[true true],
    %w[false false],
    %w[1 1],
    %w[1.2 1.2],
    %w[0b10 2],
    %w[0o10 8],
    %w[0x10 16],
    %w[1e2 100],
    %w[1.2e2.2 190.1871830953336182242521644],
    %w[1e1e1 10000000000],
    %w['hello' hello],
    %w["hello" hello],
    ["[true, 1, nothing]", "[true, 1, nothing]"],
    ['{a: 1, "b": 2}', '{"a" => 1, "b" => 2}'],
    %w[!true false],
    %w[!!true true],
    %w[!!nothing false],
    %w[!!1 true],
    %w[+1 1],
    %w[++++1 1],
    ["++++nothing", ""],
    %w[+{} {}],
    ["2 ** 2", "4"],
    ["2 ** 2 ** 3", "256"],
    %w[-2 -2],
    %w[--2 2],
    ["2 * 3", "6"],
    ["1 / 2", "0.5"],
    ["1 / 2 / 2", "0.25"],
    ["12 % 10", "2"],
    ["8 / -2 ** 3", "-1.0"],
    ["1 + 2 * 3 + 4", "11"],
    ["1e1.1 * 2", "25.1785082358833442084790822"],
    ["1 / 3 * 3", "0.999999999999999999999999999999999999"],
    ['3 * "hello"', "hellohellohello"],
    ['"Go" + "od"', "Good"],
    ["1 << 2", "4"],
    ["4 >> 2", "1"],
    ["2 & 1", "0"],
    ["2 | 1", "3"],
    ["5 ^ 6", "3"],
    ["5 > 6", "false"],
    ["5 > 5", "false"],
    ["5 > 4", "true"],
    ["2 > 1 == 3 > 2", "true"],
    ["true && false", "false"],
    ["true || false", "true"],
    %w[1..3 1..3],
    ['1 > 3 ? "Impossible" : "Sounds about right"', "Sounds about right"],
    ['1 < 3 ? "OK"', "OK"],
    ['1 < "" rescue "oops"', "oops"],
    ['"fine" rescue "oops"', "fine"],
    ["a = 1", "1"],
    ["a = 1 a * 2", "2"],
    ["a = 1 a += 1 a", "2"],
    ["a = 1 a -= 1 a", "0"],
    %w[defined?(a) false],
    ["a = 1 defined?(a)", "true"],
    ["not true", "false"],
    ["not false", "true"],
    ["not not 1", "true"],
    ["1 or 2", "1"],
    ["true or false", "true"],
    ["1 and 2", "2"],
    ["false and 2", "false"],
    ["true and false", "false"],
    ["true and true", "true"],
    ["1 if false", ""],
    ["1 if true", "1"],
    ["1 if true if true", "1"],
    ["1 unless false", "1"],
    ["1 unless true", ""],
    ["a = 0 a += 1 while a < 10 a", "10"],
    ["a = 0 a += 1 until a > 10 a", "11"],
    ["if true 1 end", "1"],
    ["if false 1 end", ""],
    ["if false 1 else 2 end", "2"],
    ["unless false 1 end", "1"],
    ["unless true 1 end", ""],
    ["if false 1 else if true 2 else 3 end", "2"],
    ["if false 1 else if false 2 else 3 end", "3"],
    ["unless false 1 else if false 2 else 3 end", "1"],
    ["if false 1 else unless false 2 else 3 end", "2"],
    ["a = 0\n while a < 10 a += 1 end a", "10"],
    ["a = 0\n until a > 10 a += 1 end a", "11"],
    ["until true end", ""],
    ["until true\nend", ""],
    %w[("Good".."Bad").first Good],
    ['"Dorian " * 2', "Dorian Dorian "],
    ["while false end == nothing", "true"],
    ['"1 + 1 = {1 + 1}"', "1 + 1 = 2"],
    ["'1 + 1 = {1 + 1}'", "1 + 1 = 2"],
    ["{}.to_string + [].to_string", "{}[]"],
    ["'a' + 1", "a1"],
    ["'a' + 1.0", "a1.0"],
    ["1 + 'a'", "1a"],
    ["1.0 + 'a'", "1.0a"],
    ["1 << 1", "2"],
    ["1.0 << 1", "2"],
    ["1 << 1.0", "2"],
    ["1.0 << 1.0", "2"],
    ["eval('1 + 1')", "2"],
  ].each do |(input, expected)|
    context input.inspect do
      let(:input) { input }

      it "succeeds" do
        expect(subject).to eq(expected)
      end
    end
  end

  context "with ruby" do
    context "with a constant" do
      let!(:input) { "a + a" }
      let!(:ruby) { { a: 1 } }

      it "can access a" do
        expect(subject).to eq("2")
      end
    end

    context "with a function without arguments" do
      let!(:input) { "a + a" }
      let!(:ruby) { { a: ->{ "hello" } } }

      it "can call a" do
        expect(subject).to eq("hellohello")
      end
    end

    context "with a function with regular arguments" do
      let!(:input) { "add(1, 2)" }
      let!(:ruby) { { add: ->(a, b){ a + b } } }

      it "can call add" do
        expect(subject).to eq("3")
      end
    end

    context "with a function with keyword arguments" do
      let!(:input) { "add(a: 1, b: 2)" }
      let!(:ruby) { { add: ->(a:, b:){ a + b } } }

      it "can call add" do
        expect(subject).to eq("3")
      end
    end

    context "with a complex function" do
      let!(:input) { "add(1, 1, 1, 1, c: 1, d: 1, e: 1)" }
      let!(:ruby) do
        {
          add: ->(a, b = 1, *args, c:, d: 2, **kargs){
            a + b + args.sum + c + d + kargs.values.sum
          }
        }
      end

      it "can call add" do
        expect(subject).to eq("7")
      end
    end
  end
end
