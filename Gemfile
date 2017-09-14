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
  
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma'

# or use passenger
#gem 'passenger', '~> 5.0.30'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# TypeScript (requires node)
gem 'typescript-rails'

# Use CoffeeScript for .coffee assets and views
#gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', '~> 0.12.3', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'rsolr'

# allows fast processing of concatenated JSON

gem 'yajl-ruby', require: 'yajl'

# allow transactions to be sent in as .zip files
gem 'rubyzip'

# generate shorter tags for transactions
gem 'hashids'

# Gem that provides background processing features

gem 'sidekiq'

# Postgres 9.5+ native "upsert" support
# there are other approaches, some of which involve creating CSV files
# https://github.com/jesjos/active_record_upsert is base
# NB does not support JDBC driver yet
# :git => 'https://github.com/phoffer/active_record_upsert.git' a fork for the moment which allows us to use something other than id column as conflict column
gem 'active_record_upsert', platform: :mri

gem 'pg'

# :github specifier defaults to using git:// protocol, which generates
# warnings. See comment at top of file.

gem 'argot', '>= 0.3.9', :github => 'trln/argot-ruby'

gem 'solrtasks', :github => 'trln/solrtasks'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

gem 'mini_portile2'

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
