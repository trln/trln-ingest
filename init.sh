#!/bin/bash

set -eu

# Ensures that a suitable TRLN Discovery Solr configuration 
# is downloaded and available for use with Docker/Podman Compose.

# By default pulls the `master` branch, but this can be changed
# by passing in the name of another branch when running this script.

# After a copy has been checked out, a different branch can be used
# via `cd solr-docker/config && git pull origin [newbranch] && git checkout [newbranch]` and re-starting all the containers.

CONFIG_BRANCH=${1:-master}

echoerr() {
    echo "$@" 1>&2;
}

wd=$(pwd)

if [ ! -d solr-docker/config/solr/trlnbib ]; then
    cd solr-docker/config
    echo "checking out solr configuration"
    git init
    git remote add origin https://github.com/trln/trln-config
    git config core.sparseCheckout true
    echo "solr/trlnbib/" >> .git/info/sparse-checkout
    git pull --depth=1 origin "$CONFIG_BRANCH"
    git checkout ${CONFIG_BRANCH}
    cd $wd
else
    echo "solr configuration is already available"
fi

container_runner='podman'
if [ $(type -P "${container_runner}") ]; then
    # no-op becuase it's hard to negate the test
    :
else
    container_runner='docker'
fi

${container_runner} secret list | grep trln-ingest-db-pw  > /dev/null

if [ $? != 0 ]; then
    echo "Didn't find database secret; creating ..."
    ruby -r securerandom -e 'puts SecureRandom.alphanumeric(48)' | ${container_runner} secret create trln-ingest-db-pw -
else
    echo "database secret is set up"
fi 
