require 'json'

module DocumentsHelper
  def pretty_json(content)
    JSON.pretty_generate(content)
  end
end
