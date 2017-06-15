#!/bin/sh

# should only need to run this once!
gem install bundler
#gem install yajl
bundle install
sudo install -o root -g root -m 0755 ../aws-files/{spofford,redis} /etc/init.d
sudo chkconfig add spofford
sudo chkconfig add redis
# installs the 'development' directory into postgres
rake db:migrate
