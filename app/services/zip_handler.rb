module Spofford
  # Utilities for working with zip files.
  # rubocop:disable MethodLength
  class ZipHandler
    # unpacks a zip  to the directory where it exists
    def self.unpack(input_file)
      files = []
      if File.exist?(input_file)
        tx_dir = File.dirname(input_file)
        Zip::File.open(input_file) do |zipfile|
          zipfile.each do |entry|
            output_file = File.join(tx_dir, entry.name)
            entry.extract(output_file)
            files << output_file
          end
        end
      end
      files
    end
    # rubocop

    # Unpacks a transaction
    def self.unpack_transaction(txn)
      packed = File.join(txn.stash_directory, 'archive.zip')
      File.exist?(packed) ? unpack(packed) : []
    end

    # Create a zip file from a transaction's stored files.
    # @param [Transaction] txn a transaction with files.
    # @param [Boolean] force whether to force creation of the zip even
    #    if it already exists.
    def self.compress_transaction(txn, force = false)
      dest = txn.find_symlink_path + '.zip'
      return nil if File.size?(dest) && !force
      Zip::File.open(dest, Zip::File::CREATE) do |zipfile|
        Dir.glob(File.join(txn.stash_directory, '*')).each do |f|
          entry_file = File.basename(f)
          zipfile.add(File.join(txn.id.to_s, entry_file), f)
        end
      end
      dest
    end
  end
  # rubocop:enable MethodLength
end
