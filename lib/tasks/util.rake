require 'json'
require 'open-uri'
require 'redis'
require 'sidekiq'
require 'zip'

namespace :util do
  desc 'Clear sidekiq Redis instance (development only!)'
  task clear_sidekiq: :environment do
    Sidekiq.redis(&:flushall)
    puts 'Sidekiq redis instance cleared'
  end

  desc 'Delete deleted records stored in Postgres. Run once a month in production.'
  task delete_deleted: :environment do
    deleted_records = Document.where(['updated_at <= ? and deleted = ?', 30.days.ago, true])

    save_dir = File.join(ENV.fetch('APP_STASH_DIRECTORY', '/opt/trln'), 'deletes')

    File.mkdir(save_dir) unless File.directory?(save_dir)

    deletes_file_path = File.join(save_dir, "/deletes_#{Time.current.to_date.strftime('%F')}.txt")

    File.open(deletes_file_path, 'w') do |f| deleted_records.each { |r| f.puts(r.id) } end

    deleted_records.delete_all
  end

  desc 'Delete unneeded transactions. Run once a month in production.'
  task delete_transactions: :environment do
    TransactionPurgeWorker.perform_async()
  end

  namespace :lcnaf do

    DEFAULT_FILENAME = 'lcnaf.madsrdf.ndjson'
    DEFAULT_SOURCE = "https://lds-downloads.s3.amazonaws.com/#{DEFAULT_FILENAME}.zip"
    DEFAULT_DESTINATION = File.join(ENV.fetch('LCNAF_BASE', File.join(ENV['HOME'], 'trln-lcnaf')))
    REDIS = Redis.new(host: ENV.fetch('REDIS_URL', '127.0.0.1'))

    desc 'Rebuild name authority Redis store'
    task rebuild: :environment do
      Rake::Task['util:lcnaf:download'].invoke
      Rake::Task['util:lcnaf:unzip'].invoke
      Rake::Task['util:lcnaf:add_to_redis'].invoke
      Rake::Task['util:lcnaf:cleanup_files'].invoke
    end

    desc 'Download LC Name Authority File (lcnaf.madsrdf.ndjson.zip)'
    task download: :environment do
      FileUtils.mkdir(DEFAULT_DESTINATION) unless File.directory?(DEFAULT_DESTINATION)

      File.open("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip", 'w') do |file|
        puts "Downloading #{DEFAULT_SOURCE} to #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip"
        IO.copy_stream(open(DEFAULT_SOURCE), file)
        puts "Download complete"
      end
    end

    desc 'Unzip LC Name Authority File (lcnaf.madsrdf.ndjson)'
    task unzip: :environment do
      Zip.on_exists_proc = true
      Zip::File.open("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip") do |zipfile|
        zipfile.each do |entry|
          puts "Extracting #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip to #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}"
          entry.extract("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}")
        end
        puts "Unzip complete"
      end
    end

    desc 'Add to Redis variant names from LC Name Authority File (lcnaf.madsrdf.ndjson)'
    task add_to_redis: :environment do
      puts "Adding LCNAF variant names to Redis"

      File.open("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}", 'r').each do |line|
        rdf = JSON.parse(line).fetch('@graph', [])

        names = personal_names(rdf) if rdf
        id = names.first.fetch('@id', '').sub('http://id.loc.gov/authorities/names/', 'lcnaf:') if names.first
        ids = has_variant_ids(names) if names
        labels = variant_labels(rdf, ids)

        unless (labels.nil? || labels.empty?)
          REDIS.set(id, labels)
          puts "#{id}:#{labels}"
        end
      end
      puts "Completed adding LCNAF variant names to Redis"
    end

    desc 'Cleanup LC Name Authority files (deletes lcnaf.madsrdf.ndjson & lcnaf.madsrdf.ndjson.zip)'
    task cleanup_files: :environment do
      puts "Deleting #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME} and #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip"
      File.delete("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}") if File.exists? "#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}"
      File.delete("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip") if File.exists? "#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip"
      puts "Deleted LCNAF files"
    end

    desc 'Flush LC Name Authority entries from Redis.'
    task flush_redis: :environment do
      REDIS.scan_each(match: 'lcnaf:*').each do |key|
        REDIS.del(key)
      end
    end

    private

    def personal_names(rdf)
      rdf.select { |v| v.fetch('@type', []).include?('madsrdf:Authority') &&
                         (v.fetch('@type', []).include?('madsrdf:PersonalName') ||
                         v.fetch('@type', []).include?('madsrdf:CorporateName'))}
    end

    def has_variant_ids(names)
      return if names.nil? || names.empty?

      variants = names&.first&.fetch('madsrdf:hasVariant', [])
      [variants]&.flatten&.map { |v| v['@id'] }
    end


    def variant_labels(rdf, ids)
      return unless ids

      ids = rdf.select { |r| ids.include?(r['@id']) }
      labels = ids.map { |f| f['madsrdf:variantLabel'] }
      labels.map { |q| q.respond_to?(:fetch) ? q.fetch('@value', nil) : q }
    end
  end
end

