class Code
  class Object
    include Comparable

    def call(**args)
      operator = args.fetch(:operator, nil)
      arguments = args.fetch(:arguments, [])
      value = arguments.first&.value

      if operator == "=="
        sig(arguments) { ::Code::Object }
        equal(value)
      elsif operator == "==="
        sig(arguments) { ::Code::Object }
        strict_equal(value)
      elsif operator == "!="
        sig(arguments) { ::Code::Object }
        different(value)
      elsif operator == "<=>"
        sig(arguments) { ::Code::Object }
        compare(value)
      elsif operator == "&&" || operator == "and"
        sig(arguments) { ::Code::Object }
        and_operator(value)
      elsif operator == "||" || operator == "or"
        sig(arguments) { ::Code::Object }
        or_operator(value)
      elsif operator == "!" || operator == "not"
        sig(arguments)
        exclamation_point
      elsif operator == "+"
        sig(arguments)
        self
      elsif operator == ".."
        sig(arguments) { ::Code::Object }
        inclusive_range(value)
      elsif operator == "..."
        sig(arguments) { ::Code::Object }
        exclusive_range(value)
      elsif operator == "to_string"
        sig(arguments)
        to_string
      else
        raise(
          Code::Error::Undefined.new("#{operator} not defined on #{inspect}")
        )
      end
    end

    def truthy?
      true
    end

    def falsy?
      !truthy?
    end

    def <=>(other)
      if respond_to?(:raw)
        other.respond_to?(:raw) ? raw <=> other.raw : raw <=> other
      else
        other <=> self
      end
    end

    def ==(other)
      if respond_to?(:raw)
        other.respond_to?(:raw) ? raw == other.raw : raw == other
      else
        other == self
      end
    end
    alias_method :eql?, :==

    def hash
      if respond_to?(:raw)
        [self.class, raw].hash
      else
        raise NotImplementedError.new(self.class.name)
      end
    end

    def to_s
      raise NotImplementedError.new(self.class.name)
    end

    private

    def multi_fetch(hash, *keys)
      keys.map { |key| [key, hash.fetch(key)] }.to_h
    end

    def deep_dup(object)
      if object.is_a?(Array)
        object.map { |element| deep_dup(element) }
      elsif object.is_a?(Hash)
        object.map { |key, value| [deep_dup(key), deep_dup(value)] }.to_h
      elsif object.is_a?(::Code::Object::List)
        ::Code::Object::List.new(object.raw.map { |element| deep_dup(element) })
      elsif object.is_a?(::Code::Object::Dictionnary)
        ::Code::Object::Dictionnary.new(
          object.raw.map { |key, value| [deep_dup(key), deep_dup(value)] }.to_h
        )
      else
        object.dup
      end
    end

    def sig(actual_arguments, &block)
      if block
        expected_arguments = block.call
        expected_arguments = [
          expected_arguments
        ] unless expected_arguments.is_a?(Array)
      else
        expected_arguments = []
      end

      if actual_arguments.size != expected_arguments.size
        raise(
          ::Code::Error::ArgumentError.new(
            "Expected #{expected_arguments.size} arguments, " \
              "got #{actual_arguments.size} arguments"
          )
        )
      end

      expected_arguments.each.with_index do |expected_argument, index|
        actual_argument = actual_arguments[index].value

        if expected_argument.is_a?(Array)
          if expected_argument.none? { |expected_arg|
               actual_argument.is_a?(expected_arg)
             }
            raise(
              ::Code::Error::TypeError.new(
                "Expected #{expected_argument}, got #{actual_argument.class}"
              )
            )
          end
        else
          if !actual_argument.is_a?(expected_argument)
            raise(
              ::Code::Error::TypeError.new(
                "Expected #{expected_argument}, got #{actual_argument.class}"
              )
            )
          end
        end
      end
    end

    def equal(other)
      ::Code::Object::Boolean.new(self == other)
    end

    def strict_equal(other)
      ::Code::Object::Boolean.new(self === other)
    end

    def different(other)
      ::Code::Object::Boolean.new(self != other)
    end

    def compare(other)
      ::Code::Object::Integer.new(self <=> other)
    end

    def and_operator(other)
      truthy? ? other : self
    end

    def or_operator(other)
      truthy? ? self : other
    end

    def to_string
      ::Code::Object::String.new(to_s)
    end

    def inclusive_range(value)
      ::Code::Object::Range.new(self, value, exclude_end: false)
    end

    def exclusive_range(value)
      ::Code::Object::Range.new(self, value, exclude_end: true)
    end

    def exclamation_point
      if truthy?
        ::Code::Object::Boolean.new(false)
      else
        ::Code::Object::Boolean.new(true)
      end
    end
  end
end
