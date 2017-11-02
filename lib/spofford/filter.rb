require 'yajl'

module Spofford
  class JSONFilter
    def initialize
      @parser = Yajl::Parser.new
    end

    def parse(stream)
      @parser.parse(stream) { |obj| yield obj }
    rescue StandardError => e
      Rails.logger.warn "this all went wrong"
      puts e
    end
  end
end
