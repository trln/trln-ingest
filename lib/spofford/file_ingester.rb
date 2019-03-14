module Spofford
  # Allows ingest of a file from the command line
  class FileIngester
    include Spofford::IngestHelper
    def ingest(filename, owner, user_id)
      user = User.find(user_id)
      File.open(filename) do |zip|
        accept_zip(zip, owner) do |files|
          @transaction = Transaction.new(owner: owner, user: user, files: files)
          @transaction.stash!
          @transaction.save!
        end
        TransactionWorker.perform_async(@transaction.id)
        puts 'Started ingest worker'
      end
    end
  end
end
