module Spofford
  class AuthorityEnricher
    include Argot::Methods

    REDIS = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'))

    # NOTE: At present this just handles names fields with an id.
    #       I could imagine a future implementation where other
    #       fields are handled and the records are enriched based
    #       on settings in an (argot-ruby?) configuration file.
    #       For now keeping it simple.
    def process(input)
      begin
        authority_values = input.fetch('names', []).map do |name|
          variant_names(name['id']) if name.fetch('id', nil)
        end.flatten.compact

        if authority_values.present?
          input['variant_names'] = authority_values
        end
      rescue StandardError => e
        logger.error("Encountered an error encriching data: #{e}")
      end

      input
    end

    alias call process

    private

    def logger
      @logger ||= Rails.logger
    end

    def variant_names(name_uri)
      variant_names = variant_names_lookup(name_uri)

      variant_names_vern = (variant_names || []).map do |variant_name|
        next unless variant_name

        lang = ScriptClassifier.new(variant_name).classify
        if lang
          { 'value' => variant_name, 'lang' => lang }
        else
          { 'value' => variant_name }
        end
      end

      variant_names_vern unless variant_names_vern.empty?
    end

    def variant_names_lookup(name_uri)
      variant_name = REDIS.get(
        name_uri.sub('http://id.loc.gov/authorities/names/', 'lcnaf:')
      )

      JSON.parse(variant_name) if variant_name
    end
  end
end
