module RuleSyntax
  class Metadata
    def initialize(raw)
      @metadata_array =
          case raw
            when Hash
              raw.inject([]) do |metadata, (type, data)|
                metadata += data.keys.map{ |datum| {type: type.downcase.to_sym, data: datum} }
                metadata
              end
            when Array
              raw
            else
              []
          end
    end

    def to_a
      @metadata_array
    end

    def to_s
      @metadata_str ||= @metadata_array.map{ |elem| "#{elem[:type]} #{elem[:data]}" }.join(', ')
    end
  end
end

