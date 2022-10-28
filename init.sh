#!/bin/bash

set -eu

# Ensures that a suitable TRLN Discovery Solr configuration 
# is downloaded and available for use with Docker/Podman Compose.
# Additionally creates a podman/docker secret for the PostgreSQL database
# password

# By default pulls the `master` branch, but this can be changed
# by passing in the name of another branch when running this script.

# After a copy has been checked out, a different branch can be used
# via `cd solr-docker/config && git pull origin [newbranch] && git checkout [newbranch]` and re-starting all the containers.

CONFIG_BRANCH=${1:-main}

echoerr() {
    echo "$@" 1>&2;
}

wd=$(pwd)

# If solr setup fails due to missing configuration, then
# rm -rf solr-docker/config and re-run this script
if [ ! -d solr-docker/config/ ]; then
    cd solr-docker
    echo "checking out solr configuration"
    git clone https://github.com/trln/trlnbib-solr-config config/
    if [ "main" != "${CONFIG_BRANCH}" ]; then
        cd config && git checkout ${CONFIG_BRANCH}
    fi
    cd $wd
else
    echo "solr configuration is already available"
fi

# figure out whether docker or podman is available on the command line; 
# prefer podman to docker

container_runner='podman'
if [ -z "$(type -P "${container_runner}")" ]; then
    container_runner='docker'
fi

if [ -z "$(type -P "${container_runner}")" ]; then
    echo "Neither of podman/docker found.  Exiting."
    exit 1
fi

# grep will have a non-zero exit if the value isn't found

if  [ ! -s .db-password ]; then
    echo "database password file not found, creating"
    echo 'a1nsw0rth' > .db-password
else
    echo "database passwod is already set up"
fi 
