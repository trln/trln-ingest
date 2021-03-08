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
    REDIS = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))

    desc 'Rebuild name authority Redis store'
    task rebuild: :environment do
      Rake::Task['util:lcnaf:download'].invoke
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


    desc 'Add to Redis variant names from LC Name Authority File (lcnaf.madsrdf.ndjson)'
    task add_to_redis: :environment do
      puts "Adding LCNAF variant names to Redis."
      puts "Progress shown by printing one entry per 2,500."

      Zip::File.open("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip") do |zip|
        zip.select { |entry| entry.name == DEFAULT_FILENAME }.each do |e|
          Argot::Reader.new(e.get_input_stream).each_with_index do |rec, index|
            rdf = rec.fetch('@graph', [])
            names = name_entries(rdf) if rdf
            names.each do |name|
              id = name.fetch('@id', '')
                       .sub('http://id.loc.gov/authorities/names/', 'lcnaf:') if name
              ids = has_variant_ids(name) if name
              labels = variant_labels(rdf, ids)

              unless (labels.nil? || labels.empty?)
                REDIS.set(id, labels)
                puts "#{id}:#{labels}" if index % 2500 == 0
              end
            end
          end
        end
      end
      puts "Completed adding LCNAF variant names to Redis"
    end

    desc 'Cleanup LC Name Authority files (deletes lcnaf.madsrdf.ndjson.zip)'
    task cleanup_files: :environment do
      puts "Deleting #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip"
      if File.exists? "#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip"
        File.delete("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}.zip")
      end
      puts "Deleted LCNAF file."
    end

    desc 'Flush LC Name Authority entries from Redis.'
    task flush_redis: :environment do
      REDIS.scan_each(match: 'lcnaf:*').each do |key|
        REDIS.del(key)
      end
    end

    private

    def name_entries(rdf)
      rdf.select { |v| v.fetch('@type', []).include?('madsrdf:Authority') &&
                         (v.fetch('@type', []).include?('madsrdf:PersonalName') ||
                         v.fetch('@type', []).include?('madsrdf:CorporateName'))}
    end

    def has_variant_ids(name)
      return if name.nil? || name.empty?

      variants = name&.fetch('madsrdf:hasVariant', [])
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

