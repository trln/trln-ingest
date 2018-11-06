require 'argot'
require 'spofford/version'
require 'spofford/deepstruct'

# Top level namespace for Spofford (trln-ingest) specific features.
module Spofford
  autoload :Chunker, 'spofford/record_chunker'
  autoload :IngestHelper, 'spofford/ingest_helper'
  autoload :LazyWriter, 'spofford/lazy_writer'
  autoload :SolrValidator, 'spofford/solr_validator'
  autoload :ArgotViewer, 'spofford/argot_viewer'

  Institution = Struct.new('Owner', :key, :prefix, :name) do
  end

  # Encapsulation of TRLN institutions
  module Owner
    DUKE = Institution.new(
      :duke,
      'DUKE',
      'Duke University Libraries'
    )
    NCCU = Institution.new(
      :nccu,
      'NCCU',
      'North Carolina Central University'
    )
    NCSU = Institution.new(
      :ncsu,
      'NCSU',
      'North Carolina State University Libraries'
    )
    UNC = Institution.new(
      :unc,
      'UNC',
      'University of North Carolina at Chapel Hill Libraries'
    )

    # rubocop:disable MethodLength
    def self.lookup(key)
      lkup = key.to_s.downcase
      case lkup
      when 'duke'
        Owner::DUKE
      when 'unc'
        Owner::UNC
      when 'nccu'
        Owner::NCCU
      when 'ncsu'
        Owner::NCSU
      end
    end
  end
end
