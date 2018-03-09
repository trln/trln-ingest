require 'tempfile'
require 'zip'
require 'fileutils'

module Spofford
  # methods to help with ingesting JSON and zip packages.
  module IngestHelper
    # Default transformer for ingested Argot records.  Sets default values
    # for record attributes that are not set in the ingest package.
    # @param owner [String] default `owner` attribute for the records.
    # @options options [Hash<Symbol, Object>] extra options for processing
    # records.
    # @option options [String] :collection default `collection` attribute value
    # @return [#call<Hash>] a process for transforming records.  
    def default_json_process(owner, options = {})
      default_collection = options[:collection] || 'general'
      lambda do |rec|
        rec['owner'] ||= owner
        rec['institution'] ||= [rec['owner']]
        rec['collection'] ||= default_collection
        rec
      end
    end

    # Processes an 'add' JSON file containing Argot records,
    # adjusting content as necessary.  You may optionally supply a block to
    # this method that transforms records in the event #default_json_process
    # does not fit your needs.
    # @param body [#read] stream of the Argot JSON
    # @param owner [String] identifier for the owner of the records, if the 
    #        record does not already specify one.
    # @param options [Hash<Symbol, Object>] options for the processor
    # @option options [File] :output_file an (open) File object to write
    #         filtered data to.  The full path to this file, which will be
    #         closed by the filter, will be the return value if this option
    #         is provided.
    # @option options [String] see #default_json_process
    # @yield [Hash<String, Object>] an Argot record to be transformed.
    # @yieldreturn [Hash<String, Object>] the transformed Argot record.
    def accept_json(body, owner, options = {}, &block)
      block ||= default_json_process(owner, options)
      parser = Argot::Reader.new
      output_file = options[:output_file] || Tempfile.new(["add_#{owner}", '.json'])
      Rails.logger.warn "Processing Argot file (size: #{body.size})" if body.respond_to?(:size)
      parser.process(body) do |rec|
        if rec.nil? || rec.empty?
          Rails.logger.warn('nil record')
        else
          result = block.call(rec)
          output_file.write(result.to_json)
        end
      end
      output_file.close
      Rails.logger.debug("Ingested file : #{File.basename(output_file)} #{File.size(output_file.path)}")
      File.expand_path(output_file)
    end

    ## extracts JSON files from zipped body, pre-processing any
    # `add.json` files.
    # @param body [IO] an IO that reads the zip archive.
    # @yield [Array<String>] filenames extracted from the archive.
    #        Files are stored in a temporary directory, so they must
    #        be fully processed in the block
    def accept_zip(body, owner, _options = {})
      body.binmode
      tempzip = stream_to_tempfile(body, owner, '.zip')
      Rails.logger.warn("Temp zip has #{File.size(tempzip)}")
      #tempzip.flush
      files = []
      begin
        Dir.mktmpdir do |dir|
          Zip::File.open(tempzip) do |zipfile|
            zipfile.each do |entry|
              entry_file = File.join(dir, entry.name)
              if entry.name =~ /^add.*\.json/i
                entry.get_input_stream do |f|
                  output = File.open(entry_file, 'w')
                  files << accept_json(f, owner, output_file: output)
                end
              else
                entry.extract(entry_file)
                files << entry_file
              end
            end
          end
          yield files if block_given?
        end
      ensure
        tempzip.close && tempzip.unlink unless tempzip.nil?
      end
    end

    # utility method, copies the input stream to a tempfile so we can
    # more safely open it with Zip::File
    def stream_to_tempfile(stream, owner, extension = '.zip')
      temp = Tempfile.new(["ingest-#{owner}", extension])
      Rails.logger.warn("Stream #{stream.size}: #{stream.tell} -- tempfile: #{temp}")
      written = IO.copy_stream(stream, temp)
      Rails.logger.warn("Temp file has size #{File.size(temp)}; wrote #{written}")
      temp
    end
  end
end
