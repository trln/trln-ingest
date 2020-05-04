require 'sidekiq'

namespace :util do
  desc 'Clear sidekiq Redis instance (development only!)'
  task clear_sidekiq: :environment do
    Sidekiq.redis(&:flushall)
    puts 'Sidekiq redis instance cleared'
  end

  desc 'Delete deleted records stored in Postgres. Run once a month in production.'
  task delete_deleted: :environment do
    deleted_records = Document.where(['updated_at <= ? and deleted = ?', 30.days.ago, true])

    save_dir = File.join(ENV[APP_STASH_DIRECTORY] ||'/opt/trln', 'deletes')
    File.mkdir(save_dir) unless File.directory?(save_dir)

    path = save_dir + "/deletes_#{Time.current.to_date.strftime('%F')}.txt"
    content = ""

    deleted_records.each do |document| content << document.id << "," end

    File.open(path, "w+") do |f|
     f.write(content)
    end
    
    deleted_records.delete_all
  end
end
