# remove parameter parsing for JSON.
# this allows us to process large POST requests
# without accidentally deserializing into params in controller
# methods
ActionDispatch::Request.parameter_parsers.delete(Mime[:json].symbol)