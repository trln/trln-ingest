require 'spofford'
require 'fileutils'
require 'logger'

Rails.application.configure do
  # Where to store transaction files.  If it isn't set, 
  # use a temp dir in the user's home directory
  config.stash_directory = ENV.fetch('TRANSACTION_STORAGE_BASE', File.join(ENV['HOME'], 'trln-ingest-transactions'))
  if Rails.env.test?
    config.stash_directory = Dir.mktmpdir('trln-ingest-test')
  end

  unless File.directory?(config.stash_directory)
    Rails.logger.warn("Transaction storage directory #{config.stash_directory} does not exist, will be created")
    FileUtils.mkdir(config.stash_directory)
  end
end
