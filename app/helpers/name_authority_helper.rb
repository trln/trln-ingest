require 'redis'

module NameAuthorityHelper

  def do_lookup(v=false)
	lookup_id = params.fetch(:lookup, v)
	return [lookup_id, []] unless lookup_id
	
	lookup_id = canonicalize(lookup_id)
	result = redis.get(lookup_id)
	if result.nil?
		return [lookup_id, []]
	end
	[ lookup_id, JSON.parse(result)]
  end

  def canonicalize(v)
	v = v.strip
	return v.gsub(/[^a-zA-Z0-9:]/, '') if v.start_with?('lcnaf:')
	
	return "lcnaf:#{$1}" if v =~ /^https?:\/\/id\.loc\.gov\/authorities\/names\/([a-zA-Z0-9]+)/

	return "lcnaf:#{v.gsub(/\W/, '')}"
  end
	
  def redis
	@redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))
  end
end
