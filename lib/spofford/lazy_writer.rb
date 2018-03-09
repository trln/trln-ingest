require 'json'

module Spofford
  # A writer that doesn't create a file until something is written to it.
  class LazyWriter
    attr_reader :io

    def self.open(filename)
      LazyWriter.new(filename)
    end

    def initialize(filename)
      @filename = filename
      return unless block_given?
      begin
        yield self
      ensure
        close
      end
    end

    def write(data)
      @io ||= File.open(@filename, 'w')
      @io.write(data)
      self
    end

    def close
      @io.close unless @io.nil?
    end

    alias_method '<<', :write
  end # LazyWriter
end # module
