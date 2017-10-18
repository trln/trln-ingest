require 'spofford/filter'
require 'spofford/deepstruct'
require 'spofford/ingest_helper'
require 'spofford/record_chunker'

module Spofford
  autoload :Mappings, 'spofford/code_mappings'
  autoload :MappingsGitFetcher, 'spofford/code_mappings'
  autoload :LazyWriter, 'spofford/lazy_writer'
  autoload :SolrValidator, 'spofford/solr_validator'

  Institution = Struct.new('Owner', :key, :prefix, :name) do
  end

  module Owner
    DUKE = Institution.new(:duke, 'DUKE', 'Duke University Libraries')
    NCCU = Institution.new(:nccu, 'NCCU', 'North Carolina Central University')
    NCSU = Institution.new(:ncsu, 'NCSU', 'North Carolina State University Libraries')
    UNC  = Institution.new(:unc, 'UNC', 'University of North Carolina at Chapel Hill Libraries')

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
      else
        nil
      end
    end
  end
end
