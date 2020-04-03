namespace :trln do
  desc 'Delete deleted records stored in Postgres. Run once a month in production.'
  task delete_deleted: :environment do
  	deleted_records = Document.where(['updated_at <= ? and deleted = ?', 30.days.ago, true])
  	puts "#{Time.now}: #{deleted_records.count} records will be deleted."
    deleted_records.delete_all
    puts 'Done!'
  end
end