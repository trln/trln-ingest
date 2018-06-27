require 'spofford'

Rails.application.configure do
  # Where to store transaction files.
  config.stash_directory = ENV['APP_STASH_DIRECTORY'] || "#{ENV['HOME']}/spofford-data"

  unless File.directory?(config.stash_directory)
    $stderr.write("Transaction storage directory #{config.stash_directory} does not exist!\n")
  end
end
