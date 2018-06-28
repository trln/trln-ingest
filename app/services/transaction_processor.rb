require 'fileutils'
require 'json'
require 'argot'
require 'spofford'

# Service that processes Transaction objects, including validation, error
# file creation, and writing updated Documents to the database
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
    @count = @errors = 0
    @validator = Argot::Validator.new
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

  def read_json_deletes(filename)
    logger.info("Processing JSON deletes #{filename}")
    deletables = []
    begin
      File.open(filename) do |f|
        deletables = JSON.load(f).collect(&:itself)
      end
    rescue JSON::ParserError => jpe
      logger.warn "Unable to read delete: #{filename} for Transaction(#{txn.id}) : #{jpe}"
    end
    deletables
  end

  def read_text_deletes(filename)
    logger.info("Processing text deletes #{filename}")
    deletables = File.open(filename) do |f|
      f.each_line.collect(&:strip).reject(&:empty?).reject { |x| x.start_with?('#') }
    end
    deletables
  end

  def process_deletes
    logger.info("[txn:#{@txn.id}] Looking for delete files")
    Dir.glob("#{txn.stash_directory}/delete*").each do |df|
      deletables = if df.end_with?('.json')
                     read_json_deletes(df)
                   else
                     read_test_deletes(df)
                   end

      goners = deletables.map do |doc_id|
        begin
          Document.find(doc_id)
        rescue ActiveRecord::RecordNotFound
          logger.warn "Found ID #{doc_id} to delete, not found"
        end
      end.select(&:itself)
      count = 0
      Document.transaction do
        goners.each do |goner|
          logger.info "Marking #{goner.id} as deleted"
          goner.update(txn: @txn, deleted: true)
          count += 1
        end
      end
      logger.info "Processed #{count} deletes [ #{df} ]"
    end
    logger.info 'Finished processing deletes'
  end

  def process_file(filename)
    File.open(filename) do |io|
      Document.transaction do
        Argot::Reader.new(io).each do |rec|
          if rec['local_id'].is_a?(String)
            rec['local_id'] = {
              'value' => rec['local_id'],
              'other' => []
            }
          end
          valid = @validator.valid?(rec) do |rec, results|
            errdoc = {
              id: rec.fetch('id', '<unknown id>'),
              msg: results.first_error,
              errors: []
            }
            results.errors.each_with_object(errdoc) do |err, ed|
              ed[:errors] << err
            end
            @error_writer.write(errdoc.to_json)
          end
          if valid
            process_document(rec) && @count += 1 || @errors += 1
          else
            @errors += 1
          end
        end
      end
    end
  end

  def process_document(rec)
    success = false
    begin
      d = Document.new(id: rec['id'] || rec['unique_id'])
      d.local_id = rec.fetch('local_id', 'value' => '<unknown>')['value']
      d.owner = rec['owner'] || rec['source']
      d.content = rec
      d.txn = txn
      if d.valid?
        d.upsert
        success = true
      else
        @error_writer.write(d.errors.to_json)
      end
    rescue StandardError => ex
      logger.error "Unable to process #{rec['id']} (#{@count + @errors} record in file)"
      logger.error(ex.backtrace.join("\n"))
    end
    success
  end
end
