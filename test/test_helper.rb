ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'tempfile'
require 'timecop'
require 'pry-byebug'
#require 'mock_redis'
#require 'sidekiq/testing'
require 'minitest/autorun'

ActiveRecord::Migration.maintain_test_schema!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def read_json(filename)
    File.open(filename) { |f| JSON.parse(f.read) }
  end
end
