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

  def txn_str
    @txn_str ||= "[#{@txn.id} (#{txn.owner})]"
  end

  def logger
    @logger ||= Rails.logger
  end

  def run
    logger.info "#{txn_str} start job"
    @txn.update(status: 'Ingesting')
    logger.info "#{txn_str} storing files in #{txn.stash_directory}"
    process_deletes
    set_up
    Dir.glob("#{txn.stash_directory}/add*.json").each do |update_file|
      process_file(update_file)
    end
    cleanup
    logger.info "#{txn_str} saved #{@count} records"
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
    logger.info("#{txn_str} processing JSON deletes in #{filename}")
    deletables = []
    begin
      File.open(filename) do |f|
        deletables = JSON.load(f).collect(&:itself)
      end
    rescue JSON::ParserError => jpe
      logger.warn "#{txn_str} Unable to read delete: #{filename}: #{jpe}"
    end
    deletables
  end

  def read_text_deletes(filename)
    logger.info("#{txn_str} processing text deletes from #{filename}")
    deletables = File.open(filename) do |f|
      f.each_line.collect(&:strip).reject(&:empty?).reject { |x| x.start_with?('#') }
    end
    deletables
  end

  def read_deletes(df)
    if df.end_with?('.json')
      read_json_deletes(df)
    else
      read_test_deletes(df)
    end
  end

  def delete_by_ids(chunk)
    count = 0
    Document.transaction do 
      Document.where(id: chunk).each do |goner|
        goner.update(txn: @txn, deleted: true)
        count += 1
      end
    end
    count
  end

  def process_deletes
    logger.debug("#{txn_str} looking for delete files")
    total = 0
    files = Dir.glob("#{txn.stash_directory}/delete*").each do |df|
      deletables = read_deletes(df)
      count = 0
      deletables.each_slice(500) do |chunk|
        count += delete_by_ids(chunk)
      end
      total += count
      logger.info "#{txn_str} finished processing #{count} deletes [ #{df} ]"
    end.length
    logger.info("#{txn_str} processed #{total} deletes in #{files} file(s)")
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
      d.deleted = false
      d.txn = txn
      if d.valid?
        Document.upsert(d.attributes)
        success = true
      else
        @error_writer.write(d.errors.to_json)
      end
    rescue StandardError => ex
      logger.error "#{txn_str} unable to process #{rec['id']} (#{@count + @errors} record in file)"
      logger.error(ex.backtrace.join("\n"))
    end
    success
  end
end
