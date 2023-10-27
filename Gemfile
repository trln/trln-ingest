source 'https://rubygems.org'

# if you get warnings about using the 'git' protocol to fetch TRLN gems,
# execute
#
# $ bundle config github.https true
#
# in the repository.
#
git_source(:github) do |r|
  "https://github.com/#{r}.git"
end

gem 'rails', "~> 6.1"

gem 'devise', '~> 4.8'

# adds authentication token features to devise;
# can auth actions with a token instead of interactive
# login
# see https://github.com/gonzalo-bulnes/simple_token_authentication
gem 'simple_token_authentication', '~> 1.0'

# Use Puma as the app server
gem 'puma'

# pagination of results
gem 'kaminari'

# bootstrap styles
#
gem 'bootstrap', '~> 4'

gem 'local_time', '~> 2.0.0'

# or use passenger
# gem 'passenger', '~> 5.0.30'
# Use SCSS for stylesheets
gem 'sassc', '~> 2.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# TypeScript (requires node)
#gem 'typescript-rails'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', '~> 0.12.3', platforms: :ruby

# 0.4.0 seems to have problems building on Centos 7
#gem 'mini_racer' #, '<= 0.3.9',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'rsolr'

# allows fast processing of concatenated JSON

gem 'yajl-ruby', '>= 1.3.1', require: 'yajl'

# allow transactions to be sent in as .zip files
gem 'rubyzip'

# generate shorter tags for transactions
gem 'hashids'

# Gem that provides background processing features

gem 'sidekiq', '~> 5.0'

# Postgres 9.5+ native "upsert" support
# there are other approaches, some of which involve creating CSV files
# https://github.com/jesjos/active_record_upsert is base
# NB does not support JDBC driver yet
# :git => 'https://github.com/phoffer/active_record_upsert.git'
#  a fork for the moment which allows us to use something other than id column
#  as conflict column

gem 'active_record_upsert', platform: :mri

# :github specifier defaults to using git:// protocol, which generates
# warnings. See comment at top of file.

gem 'argot', github: 'trln/argot-ruby', tag: 'v1.0.7'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console
  gem 'byebug', platform: :mri
  gem 'sqlite3'
end

gem 'mini_portile2'

group :development do
  # Access an IRB console on exception pages or by using <%= console %>
  # anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'pry-byebug'
  #gem 'warden'
  gem 'timecop', '~> 0.9.1'
  gem 'mock_redis', '~> 0.27'
  gem 'minitest-stub-const'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

  gem 'tzinfo-data'
