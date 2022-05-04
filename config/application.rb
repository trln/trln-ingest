require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Mime::Type.register 'application/octet-stream', :binary



module TrlnIngest
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    ## remnants of an attempt to disable automated parsing of JSON payloads; kept for posterity about the method should
    # we need it
    # config.middleware.insert_before(ActionDispatch::Executor, NoParse, :urls => ['/ingest/UNC', '/ingest', '/ingest/NCSU' ])


    config.load_defaults "6.0"
    # Load environment variable from file
    # http://railsapps.github.io/rails-environment-variables.html
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      if File.exist?(env_file)
        YAML.load_file(env_file).each { |key, value| ENV[key.to_s] = value }
      end
    end
    config.time_zone = 'Eastern Time (US & Canada)'
  end
end
