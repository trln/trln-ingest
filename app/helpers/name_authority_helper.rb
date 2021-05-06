# frozen_string_literal: true

require 'redis'

# Helpers to assist with name authority ID lookup
module NameAuthorityHelper
  def do_lookup(val = false)
    lookup_id = params.fetch(:lookup, val)
    return [lookup_id, []] unless lookup_id

    lookup_id = canonicalize(lookup_id)
    result = redis.get(lookup_id)
    return [lookup_id, []] if result.nil?

    [lookup_id, JSON.parse(result)]
  end

  def canonicalize(val)
    val = val.strip
    return val.gsub(/[^a-zA-Z0-9:]/, '') if val.start_with?('lcnaf:')

    return "lcnaf:#{Regexp.last_match(1)}" if val =~ %r{^https?://id\.loc\.gov/authorities/names/([a-zA-Z0-9]+)}

    "lcnaf:#{val.gsub(/\W/, '')}"
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))
  end
end
