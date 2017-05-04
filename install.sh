#!/bin/sh

# should only need to run this once!

cd /vagrant

# gems needed for initial bundling

gem install bundle
gem install yajl
bundle install
echo "Installing Solr and startinng it ..."
bundle exec solrtask -v 6.5.0 install
echo "Solr install done."
echo "Starting solr"
bundle exec solrtask start
echo "Installing Syndetics ICE schema ..."

# creates a basic_configs schema
bundle exec solrtask create-collection icetocs
bundle exec solrtask harmonize-schema icetocs config/ice-schema.yaml

echo "Setting up the Postgres database ..."
# installs the 'development' directory into postgres
rake db:migrate
