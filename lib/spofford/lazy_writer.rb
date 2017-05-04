require 'json'

module Spofford
    class LazyWriter
        attr_reader :io

        def initialize(filename)
            @filename = filename
        end

        def write(data)
            @io = File.open(@filename, 'w') unless @io
            @io.write(data)
        end

        def close
            @io.close unless @io.nil?
        end
    end # LazyWriter
end # module