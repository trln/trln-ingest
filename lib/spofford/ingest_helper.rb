require 'tempfile'
require 'zip'

module Spofford
  module IngestHelper
    def self.accept_json(body, owner, options = {})
      default_collection = options['collection'] || 'general'
      operation = options['operation'] || 'add'
      parser = Spofford::JSONFilter.new
      output_file = options['output_file'] || Tempfile.new(["#{operation}_#{owner}", ".json"])
      Rails.logger.warn "Hey I have output file, and it's #{output_file}"
      parser.parse(body) { |rec|
        unless rec.nil?
          rec['owner'] ||= owner
          rec['collection'] ||= default_collection
          output_file.write(rec.to_json)
        end
      }
      output_file.close
      Rails.logger.debug("Ingested file : #{ File.basename(output_file)} #{output_file.length}")
      File.expand_path(output_file)
    end

    ## extracts JSON files from zipped body and passes them to a block
    # @param body [IO]
    def self.accept_zip(body, owner, options = {})
      begin
        tempzip = Tempfile.new(["ingest-#{owner}", '.zip'])
        IO.binwrite(tempzip, body)
        Rails.logger.info  "This is the tempfile #{ tempzip }"
        Dir.mktmpdir do |dir|
          files = []
          Zip::File.open(tempzip) do |zipfile|
            zipfile.each do |entry|
              entry_file = File.join(dir, entry.name)
              entry.extract(entry_file)
              files << entry_file
            end
          yield files
        end


        end
      ensure
        #tempzip.close and tempzip.unlink unless tempzip.nil?
      end
    end
  end
end