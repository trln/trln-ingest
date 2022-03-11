#!/bin/sh

# Startup script for both the rails application and sidekiq;
# INTENDED TO SIMPLIFY RUNNING UNDER VAGRANT, DO NOT USE
# IN PRODUCTION

# Provisioning in a production environment should generally
# use a tool such as Capistrano along with a configuration management
# system that correctly sets up the environment.

export RUBY_OPTS=''

while getopts ":c"  opt; do
	case ${opt} in
		c )
			echo "deleting old log files"
			rm -f log/*
			;;
		\? )
			echo "Unknown option -$OPTARG"
			;;
	esac
done

export SOLR_DIR=solr-dir/solr-7.7.1

if [ -d "$SOLR_DIR" ]; then
  echo "Ensuring Solr is running"
  SOLR_BIN="$SOLR_DIR/bin/solr"
  if [ -e "$SOLR_BIN" ]; then
    echo "Hey I found solr binary at $SOLR_BIN"
solr-dir/solr-7.7.1/bin/solr status
    RESULT=`$SOLR_BIN status`
    STATUS=$?
    if [ "$STATUS" != "0" ]; then
      $SOLR_BIN start -c
    else
      echo "Solr appears to be running already, good."
    fi
  fi
fi

# Primary difference in the default setup between production and development
# is amount of logging and whether the application will recompile assets and
# reload ruby classes.  The same database and solr hosts are used, unless
# you've overriden `database.yml` and `solr.yml` in the `config` directory.

# Run as production by default; under Vagrant,
# this can be reset to 'development' in the
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

if [ "$RAILS_ENV" == 'production' ]; then
  bundle exec rake assets:precompile
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

if [ -z "$DB_USER" ]; then
  echo "DB_USER is unset, this is no good"
  exit 1
fi

export DB_NAME DB_USER SECRET_KEY_BASE

if [ "$BIND_ALL_ADDRESSES" == "yes" ]; then 
    bundle exec rails s -b 0.0.0.0 -d
else
   # in any other environment, don't do that.
   bundle exec rails s -d
fi
