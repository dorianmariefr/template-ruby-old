class Code
  class Node
    class Function < Node
      def initialize(parsed)
        @parameters =
          parsed
            .delete(:parameters)
            .map { |parameter| ::Code::Node::FunctionParameter.new(parameter) }

        @body = ::Code::Node::Code.new(parsed.delete(:body))

        super(parsed)
      end

      def evaluate(**args)
        ::Code::Object::Function.new(parameters: @parameters, body: @body)
      end
    end
  end
end
