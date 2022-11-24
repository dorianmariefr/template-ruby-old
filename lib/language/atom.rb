class Language
  class Atom
    class Rule < Atom
      def initialize(name:)
        @name = name
      end

      def parse(parser)
        parser.find_rule!(@name).parse(parser)
      end

      def to_s
        "rule(#{@name.inspect})"
      end
    end

    class Any < Atom
      def parse(parser)
        parser.consume(1)
      end

      def to_s
        "any"
      end
    end

    class Repeat < Atom
      def initialize(parent: nil, min: 0, max: nil, block: nil)
        @parent = parent
        @min = min
        @max = max
        @block = block
      end

      def parse(parser)
        return unless @parent

        if @max.nil?
          @min.times { match(parser) }

          begin
            loop { match(parser) }
          rescue Parser::Interuption
          end
        else
          begin
            (@min...@max).each { match(parser) }
          rescue Parser::Interuption
          end
        end
      end

      def to_s
        min = @min.zero? ? "" : @min.to_s
        max = @max.nil? ? "" : ", #{@max}"
        parenthesis = min.empty? && max.empty? ? "" : "(#{min}#{max})"

        @parent ? "(#{@parent}).repeat#{parenthesis}" : "repeat#{parenthesis}"
      end

      private

      def match(parser)
        clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )

        @parent.parse(clone)

        parser.cursor = clone.cursor
        parser.buffer = clone.buffer

        if @block
          parse.output << Output.new(@block.call(clone.output))
        else
          parser.output << clone.output
        end
      end
    end

    class Str < Atom
      def initialize(string:)
        @string = string
      end

      def parse(parser)
        if parser.next?(@string)
          parser.consume(@string.size)
        else
          raise Parser::Str::NotFound.new(parser, @string)
        end
      end

      def to_s
        "str(#{@string.inspect})"
      end
    end

    class Absent < Atom
      def initialize(parent: nil)
        @parent = parent
      end

      def parse(parser)
        clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )
        @parent.parse(clone) if @parent
      rescue Parser::Interuption
      else
        raise Parser::Interuption.new(parser, self)
      end

      def to_s
        @parent ? "(#{@parent}).absent" : "absent"
      end
    end

    class Ignore < Atom
      def initialize(parent: nil)
        @parent = parent
      end

      def parse(parser)
        clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )
        @parent.parse(clone) if @parent
        parser.cursor = clone.cursor
      end

      def to_s
        @parent ? "#{@parent}.ignore" : "ignore"
      end
    end

    class Maybe < Atom
      def initialize(parent:, block: nil)
        @parent = parent
        @block = block
      end

      def parse(parser)
        @parent.parse(parser)
      rescue Parser::Interuption
      ensure
        parser.output = Output.new(@block.call(parser.output)) if @block
      end

      def to_s
        block = " {}" if @block
        @parent ? "#{@parent}.maybe#{block}" : "maybe#{block}"
      end
    end

    class Aka < Atom
      def initialize(name:, parent:, block: nil)
        @name = name
        @parent = parent
        @block = block
      end

      def parse(parser)
        clone =
          Parser.new(root: self, input: parser.input, cursor: parser.cursor)

        @parent.parse(clone)

        if clone.output?
          if @block
            parser.output =
              Output.new(@name => Output.new(@block.call(clone.output)))
          else
            parser.output = Output.new(@name => clone.output)
          end
        else
          if @block
            parser.output[@name] = Output.new(
              @block.call(Output.new(clone.buffer))
            )
          else
            parser.output[@name] = Output.new(clone.buffer)
          end
          parser.buffer = ""
        end

        parser.cursor = clone.cursor
      end

      def to_s
        @parent ? "#{@parent}.aka(#{@name.inspect})" : "aka(#{@name.inspect})"
      end
    end

    class Or < Atom
      def initialize(left:, right:, block: nil)
        @left = left
        @right = right
        @block = block
      end

      def parse(parser)
        left_clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )

        right_clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )

        begin
          @left.parse(left_clone)
          parser.cursor = left_clone.cursor
          parser.buffer = left_clone.buffer
          if @block
            parser.output.merge(Output.new(@block.call(left_clone.output)))
          else
            parser.output.merge(left_clone.output)
          end
        rescue Parser::Interuption
          @right.parse(right_clone)
          parser.cursor = right_clone.cursor
          parser.buffer = right_clone.buffer
          if @block
            parser.output.merge(Output.new(@block.call(right_clone.output)))
          else
            parser.output.merge(right_clone.output)
          end
        end
      end

      def to_s
        "((#{@left}) | (#{@right}))"
      end
    end

    class And < Atom
      def initialize(left:, right:, block: nil)
        @left = left
        @right = right
        @block = block
      end

      def parse(parser)
        @left.parse(parser)
        right_clone =
          Parser.new(
            root: self,
            input: parser.input,
            cursor: parser.cursor,
            buffer: parser.buffer
          )
        binding.irb unless @right.methods.include?(:parse)
        @right.parse(right_clone)
        parser.cursor = right_clone.cursor
        parser.buffer = right_clone.buffer

        if @block
          parser.output.merge(Output.new(@block.call(right_clone.output)))
        else
          parser.output.merge(right_clone.output)
        end
      end

      def to_s
        "#{@left} >> #{@right}".to_s
      end
    end

    def any
      Any.new
    end

    def str(string)
      Str.new(string: string)
    end

    def absent
      Absent.new(parent: self)
    end

    def ignore
      Ignore.new(parent: self)
    end

    def maybe
      Maybe.new(parent: self)
    end

    def repeat(min = 0, max = nil)
      Repeat.new(parent: self, min: min, max: max)
    end

    def aka(name)
      Aka.new(parent: self, name: name)
    end

    def |(other)
      Or.new(left: self, right: other)
    end

    def >>(other)
      And.new(left: self, right: other)
    end

    def <<(other)
      And.new(left: self, right: other)
    end

    def rule(name)
      Rule.new(name: name)
    end

    def parse(parser)
      raise NotImplementedError.new("#{self.class}#parse")
    end

    def to_s
      ""
    end

    def inspect
      to_s
    end
  end
end
