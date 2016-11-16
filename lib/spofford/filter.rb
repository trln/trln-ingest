require 'yajl'

module Spofford
	class JSONFilter
		def initialize()
			@parser = Yajl::Parser.new		
    end

    def parse(stream)
      begin
        @parser.parse(stream) {|obj| yield obj}
      rescue Exception => e
        Rails.logger.warn "this all went wrong"
        puts e
      end
    end
  end
end
                            
