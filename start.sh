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

# environment vars may be established by a calling script, e.g. when running as a service
# use local defintions unless that's happened.

if [ -z "$APP_POSTGRES_HOST" ]; then
    export APP_POSTGRES_HOST='localhost'
fi

if [ -z "$APP_POSTGRES_PASSWORD" ]; then
    # .password file is created during vagrant installation
    # if that doesn't exist, then ... what else is there to do?
    export APP_POSTGRES_PASSWORD=$(printf "%q" $(cat .password))
fi

# since you're forwarding port 3000 in vagrant, you need to
# bind to 0.0.0.0, but only then

# this will exit successfully if there is a 'vagrant' user, which is
# the best generic test we can come up with for running under vagrant
grep -q '^vagrant:' /etc/passwd

if [[ "$?" == "0" ]]; then
    echo "Looks like we're running on a vagrant host"
    echo "Binding to all interfaces for port forwarding. "
    echo "If you are running in production or on a dedicated host, THIS IS NOT GOOD"
    bundle exec rails s -b 0.0.0.0 -d
else
   # in any other environment, don't do that.
   bundle exec rails s -d
fi
