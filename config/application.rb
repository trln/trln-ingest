require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Mime::Type.register "application/octet-stream", :binary

module TrlnIngest
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    ## remnants of an attempt to disable automated parsing of JSON payloads; kept for posterity about the method should
    # we need it
    # config.middleware.insert_before(ActionDispatch::Executor, NoParse, :urls => ['/ingest/UNC', '/ingest', '/ingest/NCSU' ])
  end
end
