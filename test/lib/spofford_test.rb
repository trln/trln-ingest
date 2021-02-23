require 'test_helper'
require 'spofford'
require 'mock_redis'

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
    accept_zip(input.open, 'test', test_zip: true) do |files|
      assert files.length == 1
      simple_asserts(read_json(files.first))
    end
  end

  def test_stream_to_tempfile
    input = file_fixture('ingest-single.zip')
    temp = stream_to_tempfile(input.open, 'test')
    assert File.size(temp) == input.size, 'zip stream copy has wrong size'
  end

  def simple_asserts(data)
    assert data['owner'] == 'test', 'owner should be "test"'
  end
end

class AuthorityEnricherTest < ActiveSupport::TestCase
  setup do
    Spofford::AuthorityEnricher.stub_const(:REDIS, MockRedis.new) do
      Spofford::AuthorityEnricher::REDIS.set('foo', ['foo1'])
      Spofford::AuthorityEnricher::REDIS.set('bar', ['bar1'])
      enricher = Spofford::AuthorityEnricher.new
      input = { 'names' => [{ 'id' => 'foo' }, { 'id' => 'bar' }]}
      @output = enricher.process(input)
      Spofford::AuthorityEnricher::REDIS.del('foo', 'bar')
    end
  end

  test 'variant_names are added' do
    assert @output['variant_names'] == [{ 'value' => 'foo1' }, { 'value' => 'bar1' }]
  end

  test 'names are passed through' do
    assert @output['names'] == [{ 'id' => 'foo' }, { 'id' => 'bar' }]
  end
end

class ScriptClassifierTest < ActiveSupport::TestCase
  test 'Roman characters are not classified' do
    assert Spofford::ScriptClassifier.new('English').classify == nil
  end

  test 'Arabic characters are classified' do
    assert Spofford::ScriptClassifier.new('حسن').classify == 'ara'
  end

  test 'Cyrillic characters are classified' do
    assert Spofford::ScriptClassifier.new('история').classify == 'rus'
  end

  test 'CJK characters are classified' do
    assert Spofford::ScriptClassifier.new('東京').classify == 'cjk'
  end
end

