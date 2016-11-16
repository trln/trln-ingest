class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  def self.skip_params_parsing(*paths)
    ActionDispatch::Http::Parameters.skipped_paths += Array.wrap(paths).flatten
  end
end
