namespace :postgres do
  desc 'Delete deleted records stored in Postgres. Run once a month in production.'
  task delete_deleted: :environment do
  	count = Document.where(deleted: true).count
  	puts "#{count} records will be deleted."
    Document.where(deleted: true).delete_all
    puts 'Done!'
  end
end