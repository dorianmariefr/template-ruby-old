class Code
  class Object
    class Integer < ::Code::Object::Number
      attr_reader :raw

      def initialize(whole, exponent: nil)
        @raw = whole.to_i
        @raw = @raw * 10**exponent.raw if exponent &&
          exponent.is_a?(::Code::Object::Number)
      end

      def fetch(key, *args, **kargs)
        if key == :/
          division(args.first)
        elsif [:**, :*, :%, :+, :-].include?(key)
          integer_or_decimal_operation(key, args.first)
        elsif [:<<, :>>, :&, :|, :^].include?(key)
          integer_operation(key, args.first)
        elsif [:>, :>=, :<, :<=].include?(key)
          integer_or_decimal_comparaison(key, args.first)
        elsif [:<=>, :==, :===, :!=].include?(key)
          comparaison(key, args.first)
        else
          ::Code::Object::Nothing.new
        end
      end

      def ==(other)
        raw == other.raw
      end
      alias_method :eql?, :==

      def hash
        [self.class, raw].hash
      end

      def to_s
        raw.to_s
      end

      def inspect
        to_s
      end

      private

      def division(other)
        if other.is_a?(::Code::Object::Number)
          ::Code::Object::Decimal.new(BigDecimal(raw) / other.raw)
        else
          ::Code::Object::Nothing
        end
      end

      def integer_or_decimal_operation(operator, other)
        if other.is_a?(::Code::Object::Integer)
          ::Code::Object::Integer.new(raw.public_send(operator, other.raw))
        elsif other.is_a?(::Code::Object::Decimal)
          ::Code::Object::Decimal.new(raw.public_send(operator, other.raw))
        else
          ::Code::Object::Nothing.new
        end
      end

      def integer_operation(operator, other)
        if other.is_a?(::Code::Object::Integer)
          ::Code::Object::Integer.new(raw.public_send(operator, other.raw))
        else
          ::Code::Object::Nothing.new
        end
      end

      def integer_or_decimal_comparaison(operator, other)
        if other.is_a?(::Code::Object::Integer)
          ::Code::Object::Boolean.new(raw.public_send(operator, other.raw))
        elsif other.is_a?(::Code::Object::Decimal)
          ::Code::Object::Boolean.new(raw.public_send(operator, other.raw))
        else
          ::Code::Object::Nothing.new
        end
      end

      def comparaison(key, other)
        if other
          ::Code::Object::Boolean.new(raw.public_send(key, args.first&.raw))
        else
          ::Code::Object::Boolean.new(false)
        end
      end
    end
  end
end
