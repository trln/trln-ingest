# frozen_string_literal: true

require 'test_helper'

class NameAuthorityHelperTest < ActionView::TestCase
  test 'canonicalizes simple values' do
    assert_equal 'lcnaf:foo', canonicalize('foo')
  end

  test 'leaves lcnaf: entries alone' do
    assert_equal 'lcnaf:no1238', canonicalize('lcnaf:no1238')
  end

  test 'removes invalid characters' do
    assert_equal 'lcnaf:no1444', canonicalize('no?14:\44')
  end

  test 'canonicalizes id.loc.gov URIs' do
    assert_equal('lcnaf:no2018099999', canonicalize('http://id.loc.gov/authorities/names/no2018099999'))
  end

  test 'canonicalizes id.loc.gov web page URLs' do
    assert_equal('lcnaf:no2018099999', canonicalize('https://id.loc.gov/authorities/names/no2018099999.html'))
  end
end
