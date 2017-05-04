require 'fileutils'
require 'json'
require 'argot'
require 'spofford'

# Service that processes Transaction objects, including validation, error
# file creation, and writing updated Documents to the database
class TransactionProcessor
  attr_accessor :txn, :status, :start_time, :end_time, :logger

  def initialize(source_txn)
    @txn = source_txn
  end

  def run
    Rails.logger.debug "Start job for #{@txn}"
    txn.update(:status => "Processing")

    Rails.logger.debug("Looking for delete files")
    Dir.glob("#{txn.stash_directory}/delete*.json").each do |delete_file|
      begin
        deletables = JSON.load(delete_file).collect { |doc_id| Document.find(doc_id) }
        Document.transaction do
          deletables.each do |goner|
            goner.txn = txn
            goner.deleted = true
          end
        end
      rescue JSON::ParserError
        Rails.logger.warn "JSON parse problem in  #{delete_file} for Transaction(#{txn.id})"
      end
    end
    Rails.logger.debug "deletes [ done ]"

    reader = Argot::Reader.new
    count = 0
    errors = 0
    logger.debug "Transaction files stored in #{txn.stash_directory}"
    validator = Argot::Validator.from_files
    error_file = File.join(txn.stash_directory, 'errors.json')
    error_writer = Spofford::LazyWriter.new(error_file)
    Dir.glob("#{txn.stash_directory}/add*.json").each do |update_file|
      logger.info "Processing #{update_file}"

      File.open(update_file) do |io|
        Document.transaction do |document_transaction|
          reader.process(io) do |rec|
            begin
              result = validator.is_valid?(rec)
              if result
                ## "find or update; note 'upsert' is provided by the active_record_upsert gem which only works with the pg driver"
                Document.upsert(id: rec['unique_id']||rec['id'], local_id:rec['local_id'], owner: rec['owner']||rec['source'], collection: rec['collection']||'general', content: rec, txn: txn)
                count+=1
              else
                errors += 1
                error_writer.write(result.to_json)
              end
           rescue StandardError => ex
              logger.error("Error processing #{update_file}", ex)
           end

          end
        end
      end
    end
    txn.update(:status => "Complete", :completed => true)
    error_writer.close
    txn.files << error_file if File.exist?(error_file) 
    txn.update(:status => "Complete")
    logger.info "Saved #{count} records for transaction #{@txn}"
  end
end
