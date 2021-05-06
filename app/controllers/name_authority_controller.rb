class NameAuthorityController < ApplicationController
	include NameAuthorityHelper
	def index
		@lookup_value, @lookups = do_lookup
	end
end
