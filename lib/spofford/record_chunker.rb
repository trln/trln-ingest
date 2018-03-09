module Spofford
  # IO-like object that sends output to a series of files
  # in defined chunk sizes.
  class Chunker
    DEFAULTS = { chunk_size: 5000 }.freeze

    attr_reader :files, :count, :chunk_size, :dir

    # Create a new chunker
    # @param options [Hash]
    # @option options [String] chunk_size the number of records to write to each file
    # @options options [String] transaction_id an (optional) transaction ID to be used in the creation of a temporary directory
    # @options options [Dir] an optional directory to store the output files.  If not provided, a temporary directory will be created.
    def initialize(options={})
      @files = []
      @count = 0
      options = Marshal.load(Marshal.dump(DEFAULTS)).update(options)
      @chunk_size = options[:chunk_size]
      @current_file = nil
      @is_tempdir = false
      @dir = options[:dir]
      unless @dir
        @is_tempdir = true
        txn_id = options[:transaction_id] || 'unknown-tx'
        @dir = Dir.mktmpdir("solr-#{txn_id}-")
      end

      if block_given?
        yield self
        finish_currentfile
      end
    end

    def next_file
      fn = "solr-out-#{@files.length+1}.json"
      full_path = File.join(@dir, fn)
      @files << full_path
      begin
        @current_file = File.open(full_path, 'w')
      rescue Exception => e
        puts e
      end
   end 

    def finish_currentfile
      if not @current_file.nil?
        @current_file.flush
        @current_file.close            
        @current_file = nil
      end
    end

    def write(rec)
      next_file if @current_file.nil?
      @current_file.write(rec)
      finish_currentfile if (@count += 1) % @chunk_size == 0
    end

    def cleanup
      @files.each do |f|
        File.unlink(f) if File.exist?(f)
      end
      Dir.rmdir(@dir) if @is_tempdir
    end

    alias_method :close, :finish_currentfile
  end
end
