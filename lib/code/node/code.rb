class Code
  class Node
    class Code < Node
      def initialize(statements)
        statements = [] if statements.blank?

        @statements =
          statements.map { |statement| ::Code::Node::Statement.new(statement) }
      end

      def evaluate(context)
        @statements.map { |statement| statement.evaluate(context) }.last
      end
    end
  end
end
