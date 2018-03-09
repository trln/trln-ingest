require 'test_helper'
require 'spofford'

# rubocop you so crazy
class IngestHelperTest < ActiveSupport::TestCase
  include Spofford::IngestHelper

  def test_accept_json
    input = file_fixture('add-basic.json')
    filename = accept_json(input.open, 'test')
    assert_not filename.nil?, "we got a filename back"
    assert File.size?(filename), "created a file with some data"
    simple_asserts(read_json(filename))
  end

  def test_accept_zip
    input = file_fixture('ingest-single.zip')
    accept_zip(input.open, 'test') do |files|
      assert files.length == 1
      simple_asserts(read_json(files.first))
    end
  end

  def test_copy_stream
    input = file_fixture('ingest-single.zip')
    temp = stream_to_tempfile(input.open, 'test')
    assert File.size(temp) == input.size, 'zip stream copy has wrong size'
  end

  def simple_asserts(data)
    assert data['owner'] == 'test', 'owner should be "test"'
    assert data['collection'] == 'general', 'collection should be "general"'
  end
end
