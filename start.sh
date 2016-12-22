#!/bin/sh

if [ "%1" == "-c" ]; then
	rm log/devel*.log
    rm log/pass*.log
fi

# todo -- autostart solr

# bundle exec solrtask install
# bundle exec solrtask start
# cd solr-dir/solr-6.3.0
# bin/solr -c trln-dev -n basic_configs
# # now you have a collection with a data-driven schema
# it will 'infer' that two fields are really integer fields.
# easiest way to fix is:
# ingest some documents, have it fail, then go to the Solr console
# make sure the 'isbn' and 'syndetics_isbns fields are multivalued strings
# now you are ready to reindex
# issue a delete by query  *:* and a commit
# now you are ready to ingest
# nned to automate schema creation process, obviously =)

if [ -z "$(pgrep -f sidekiq)" ]; then
	# start sidekiq as a daemon
	bundle exec sidekiq -d -L log/sidekiq.log 2> log/sidekiq.err
fi

bundle exec passenger start


