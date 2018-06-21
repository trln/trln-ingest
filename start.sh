#!/bin/sh

export RUBY_OPTS=''

# Run as production by default; under Vagrant,
# this will be reset to 'development' in the
# .vagrant_rails_env
export RAILS_ENV=production

function is_vagrant() {
    # the best generic test we can come up with for running under vagrant
    grep -q '^vagrant:' /etc/passwd
    [ "$?" == "0" ]
}

BIND_ALL_ADDRESSES='no'

if is_vagrant; then
    VAGRANT_ENV="./.vagrant_rails_env"
    echo "Running under vagrant."
    printf "\tload environment from $VAGRANT_ENV\n"
    printf "\tbind rails port to 0.0.0.0 (bad in production)\n"
    source "${VAGRANT_ENV}"
    BIND_ALL_ADDRESSES='yes'
fi

if [ -z "$SECRET_KEY_BASE" ]; then
    echo "SECRET_KEY_BASE is not set.  Will not continue"
    exit 1
fi

# todo -- autostart solr
# see rake tasks in the solrtask namespace
# and read the documentation for the trln/solrtask gem
SIDEKIQ_PID=$(pgrep -f sidekiq)

if [ -z "${SIDEKIQ_PID}" ]; then
  printf "\tStarting sidekiq\n"
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

if [ "$BIND_ALL_ADDRESSES" == "yes" ]; then 
    bundle exec rails s -b 0.0.0.0 -d
else
   # in any other environment, don't do that.
   bundle exec rails s -d
fi
