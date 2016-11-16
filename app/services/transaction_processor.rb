require 'fileutils'
require 'json'
require 'argot'


class TransactionProcessor
  attr_accessor :txn, :status, :start_time, :end_time, :logger

  def initialize(source_txn)
    @txn = source_txn
  end

  def run
    Rails.logger.debug "Start job for #{@txn}"
    txn.update(:status => "Processing")

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

    reader = Argot::Reader.new
    count = 0
    logger.debug "Transaction files stored in #{txn.stash_directory}"
    Dir.glob("#{txn.stash_directory}/add*.json").each do |update_file|
      logger.info "Processing #{update_file}"
      File.open(update_file) do |io|
        Document.transaction do |document_transaction|
          reader.process(io) do |rec|
            ## "find or update; note 'upsert' is provided by the active_record_upsert gem which only works with the pg driver"
            Document.upsert(id: rec['unique_id']||rec['id'], local_id:rec['local_id'], owner: rec['owner']||rec['source'], collection: rec['collection']||'general', content: rec, txn: txn)
            count+=1
          end
        end
      end
    end
    txn.update(:status => "Complete", :completed => true)
    logger.info "Saved #{count} records for transaction #{@txn}"
  end
end