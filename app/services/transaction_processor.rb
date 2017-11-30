require 'fileutils'
require 'json'
require 'argot'
require 'spofford'

# Service that processes Transaction objects, including validation, error
# file creation, and writing updated Documents to the database
# rubocop:disable MethodLength,AbcSize
class TransactionProcessor
  attr_writer :logger

  attr_accessor :txn, :status, :start_time, :end_time

  def initialize(source_txn)
    @txn = source_txn
  end

  def logger
    @logger ||= Rails.logger
  end

  def run
    logger.debug "Start job for #{@txn}"
    @txn.update(status: 'Ingesting')
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
    txn.update(status: 'Stored')
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

  # rubocop:disable LineLength, CyclomaticComplexity, PerceivedComplexity
  def process_document(rec)
    success = false
    begin
      result = @validator.valid?(rec)
      local_id = rec['local_id']
      if local_id.nil?
        result << Argot::RuleResult.new('local_id must be present', ['local_id is missing'], [])
      else
        local_id = local_id.is_a?(Hash) ? local_id['value'] : local_id.to_s
      end
      if result.errors?
        @error_writer.write(result.to_json)
        return false
      end

      d = Document.new(id: rec['id'] || rec['unique_id'])
      d.local_id = local_id
      d.owner = rec['owner'] || rec['source']
      d.content = rec
      d.txn = txn
      if d.valid?
        d.upsert
        return true
      end
      @error_writer.write(d.errors.to_json)
    rescue StandardError => ex
      logger.error "Unable to process #{rec['id']} (#{@count + @errors} record in file)"
      logger.error(ex.backtrace.join("\n"))
    end
    success
  end
end
