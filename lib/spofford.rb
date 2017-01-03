require 'spofford/filter'
require 'spofford/deepstruct'
require 'spofford/ingest_helper'
require 'spofford/record_chunker'

module Spofford
  Institution = Struct.new('Owner', :key, :prefix, :name) do
  end

  module Owner
    DUKE = Institution.new(:duke, 'DUKE', 'Duke University Libraries')
    NCCU = Institution.new(:nccu, 'NCCU', 'North Carolina Central University')
    NCSU = Institution.new(:ncsu, 'NCSU', 'North Carolina State University')
    UNC  = Institution.new(:unc, 'UNC', 'University of North Carolina at Chapel Hill')

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