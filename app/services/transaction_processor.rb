require 'fileutils'
require 'json'
require 'argot'
require 'spofford'

# Service that processes Transaction objects, including validation, error
# file creation, and writing updated Documents to the database
# rubocop:disable MethodLength,AbcSize
class TransactionProcessor
  attr_accessor :txn, :status, :start_time, :end_time, :logger

  def initialize(source_txn)
    @txn = source_txn
  end

  def logger
    @logger ||= Rails.logger
  end

  def run
    logger.debug "Start job for #{@txn}"
    @txn.update(status: 'Processing')
    logger.debug "[txn:#{txn.id}}] files in #{txn.stash_directory}"
    process_deletes
    set_up
    Dir.glob("#{txn.stash_directory}/add*.json").each do |update_file|
      process_file(update_file)
    end
    cleanup
    logger.info "Saved #{@count} records for transaction #{@txn}"
  end

  private

  def set_up
    @reader = Argot::Reader.new
    @count = @errors = 0
    @validator = Argot::Validator.from_files
    @error_file = File.join(txn.stash_directory, 'errors.json')
    @error_writer = Spofford::LazyWriter.new(@error_file)
  end

  def cleanup
    @error_writer.close
    if File.exist?(@error_file) && !txn.files.include?(@error_file)
      txn.files << @error_file
    end
    txn.update(status: 'Complete')
  end

  def process_deletes
    logger.debug("[txn:#{@txn.id}]i Looking for delete files")
    Dir.glob("#{txn.stash_directory}/delete*.json").each do |df|
      begin
        deletables = JSON.parse(df).collect { |doc_id| Document.find(doc_id) }
        Document.transaction do
          deletables.each { |goner| goner.update(txn: @txn, deleted: true) }
        end
      rescue JSON::ParserError
        logger.warn "Unable to read delete: #{df} for Transaction(#{txn.id})"
      end
    end
    logger.debug 'deletes [ done ]'
  end

  def process_file(filename)
    File.open(filename) do |io|
      Document.transaction do
        @reader.process(io) do |rec|
          process_document(rec) && @count += 1 || @error += 1
        end
      end
    end
  end

  # rubocop:disable LineLength
  def process_document(rec)
    success = false
    begin
      result = @validator.is_valid?(rec)
      if rec.fetch('local_id', '').empty?
        result << Argot::RuleResult.new('local_id must be present', ['local_id is missing'], [])
      end
      if !result.has_errors?
        # upsert requires pg driver -- no jruby -- and upsert gem
        Document.upsert(id: rec['unique_id'] || rec['id'],
                        local_id: rec['local_id'],
                        owner: rec['owner'] || rec['source'],
                        collection: rec['collection'] || 'general',
                        content: rec,
                        txn: txn)
        success = true
      else
        @error_writer.write(result.to_json)
      end
    rescue StandardError => ex
      logger.error "Unable to process #{rec['id']} (#{@count + @errors} record in file)"
      logger.error(ex.backtrace.join("\n"))
    end
    success
  end
end
