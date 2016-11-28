#!/bin/sh

# should only need to run this once!
cd ~vagrant/synced
gem install bundle
gem install yajl
bundle install
# installs the 'development' directory into postgres
rake db:migrate
