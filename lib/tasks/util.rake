require 'json'
require 'open-uri'
require 'redis'
require 'sidekiq'
require 'zlib'

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
    TransactionPurgeWorker.perform_async
  end

  namespace :lcnaf do
    DEFAULT_FILENAME = 'names.madsrdf.jsonld.gz'.freeze
    DEFAULT_SOURCE = "https://id.loc.gov/download/authorities/#{DEFAULT_FILENAME}".freeze
    DEFAULT_DESTINATION = File.join(ENV.fetch('LCNAF_BASE', File.join(ENV['HOME'], 'trln-lcnaf')))
    REDIS = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))

    desc 'Rebuild name authority Redis store'
    task rebuild: :environment do
      Rake::Task['util:lcnaf:download'].invoke
      Rake::Task['util:lcnaf:add_to_redis'].invoke
      Rake::Task['util:lcnaf:cleanup_files'].invoke
      Rake::Task['util:lcnaf:notify'].invoke
    end

    desc 'Download LC Name Authority File (names.madsrdf.jsonld.gz)'
    task download: :environment do
      FileUtils.mkdir(DEFAULT_DESTINATION) unless File.directory?(DEFAULT_DESTINATION)
      download_file = File.join(DEFAULT_DESTINATION, "#{DEFAULT_FILENAME}")
      if file_too_old?(filename: download_file)
        system('curl', '-L', '-o', download_file, DEFAULT_SOURCE)
        URI.open("#{DEFAULT_SOURCE}") do |file|
          File.open("#{DEFAULT_FILENAME}", 'wb') do |output_file|
            output_file.write(file.read)
          end
        end
      else
        puts "download file exists and is less than 7 days old. Using that."
      end
    end

    desc 'Add to Redis variant names from LC Name Authority File (lcnaf.madsrdf.ndjson)'
    task add_to_redis: :environment do
      puts "Adding LCNAF variant names to Redis."
      puts "Progress shown by printing one entry per 2,500."
      Zlib::GzipReader.open("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}") do |gz_file|
        gz_file.each_line.with_index do |line, index|
        rec = JSON.parse(line)
          rdf = rec.fetch('@graph', [])
          names = name_entries(rdf) if rdf
          names.each do |name|
            if name
              id = name.fetch('@id', '')
                        .sub('http://id.loc.gov/authorities/names/', 'lcnaf:')
            end
            ids = variant_ids(name) if name
            labels = variant_labels(rdf, ids)

            unless labels.nil? || labels.empty?
              REDIS.set(id, labels)
              puts "#{id}:#{labels}" if index % 2500 == 0
            end
          end
        end
      end
      puts "Completed adding LCNAF variant names to Redis"
    end

    desc 'Cleanup LC Name Authority files (deletes names.madsrdf.jsonld.gz)'
    task cleanup_files: :environment do
      if File.exist? "#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}"
        puts "Deleting #{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}"
        File.delete("#{DEFAULT_DESTINATION}/#{DEFAULT_FILENAME}")
        puts "Deleted LCNAF file."
      end
    end

    desc 'Notify TRLN Admin via email.'
    task notify: :environment do
      AuthorityMailer.new.notify_lcnaf
    end

    desc 'Flush LC Name Authority entries from Redis.'
    task flush_redis: :environment do
      REDIS.scan_each(match: 'lcnaf:*').each do |key|
        REDIS.del(key)
      end
    end

    private

    def file_too_old?(filename:, override: ENV.fetch("FORCE_DOWNLOAD", "false") == "true")
      raise StandardError, "need a filename to test" unless filename

      unless override
        require 'date'
        fsize = File.size?(filename)
        return fsize.nil? || fsize < ( 10 * 1024 * 1024 ) || (Date.today - File.mtime(filename).to_date).to_i > 7
      end
      true
    end

    def name_entries(rdf)
      rdf.select { |v|
        v.fetch('@type', []).include?('madsrdf:Authority') &&
          (v.fetch('@type', []).include?('madsrdf:PersonalName') ||
          v.fetch('@type', []).include?('madsrdf:CorporateName'))
      }
    end

    def variant_ids(name)
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
