#!/bin/sh

export RUBY_OPTS=''

if [ "%1" == "-c" ]; then
	rm log/devel*.log
    rm log/pass*.log
fi

# todo -- autostart solr
# see rake tasks in the solrtask namespace
# and read the documentation for the trln/solrtask gem

if [ -z "$(pgrep -f sidekiq)" ]; then
	# start sidekiq as a daemon
	bundle exec sidekiq -d -L log/sidekiq.log 2> log/sidekiq.err
fi

export APP_POSTGRES_HOST='localhost'
# .password file is created during vagrant installation
export APP_POSTGRES_PASSWORD=$(printf "%q" $(cat .password))

# since you're forwarding port 3000 in vagrant, you need to
# bind to 0.0.0.0

bundle exec rails s -b 0.0.0.0 -d
