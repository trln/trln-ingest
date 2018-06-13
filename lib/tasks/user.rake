namespace :user do
  def vagrant?
    @vagrant ||= system("grep -p '^vagrant:' /etc/passwd")
  end
  desc 'List users'
  task list: :environment do
    User.all.each do |u|
      puts "#{u.email}, approved: #{u.approved?}, admin: #{u.admin?}, last sign in: #{u.last_sign_in_at}"
    end
  end

  desc 'Approve user'
  task :approve, [:email] => [:environment] do |t, args|
    User.where(email: args[:email]).update!(approved: true)
  end

  desc 'Create admin user (vagrant only)'
  task :admin, [:email, :password, :institution] => [:environment] do |t, args|
    unless vagrant?
      warn "We do not seem to be running under vagrant.  I suggest you do this"
      warn "via the console.  See #{__FILE__}#admin for the syntax."
      exit 1
    end
    email = args.fetch(:email, 'admin@localhost')
    password = args.fetch(:password, 'spofford is installed')
    institution = args.fetch(:institution, 'trln')
    if User.where(:admin).empty?
      User.create!(
        email: email, 
        password: password, 
        primary_institution: institution,
        approved: true, 
        admin: true
      )
    else
      warn "Admin user already created.  use :list task to find them"
      exit 1
    end
  end
end
