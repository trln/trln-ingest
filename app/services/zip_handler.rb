# rubocop:disable MethodLength
def unpack(input_file)
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

def unpack_transaction(txn)
  packed = File.join(txn.stash_directory, 'archive.zip')
  File.exist?(packed) ? unpack(packed) : []
end

def compress_transaction(txn, compact = false)
  packed = File.join(txn.stash_directory, 'archive.zip')
  if File.size?(packed)
    false
  else
    Zip::File.open(packed, Zip::File::CREATE) do |zipfile|
      file_pat = File.join(txn.stash_directory, '*.json')
      archive_files = Dir.glob(file_pat).each do |json_file|
        entry_file = File.name(json_file)
        zipfile.add(entry_file.name, json_file)
      end
      archive_files.each { |f| File.delete(f) } if compact
    end
    true
  end
end
