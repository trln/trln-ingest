#!/bin/sh

if [ -e tmp/pids/server.pid ]; then
	kill $(cat tmp/pids/server.pid)
fi

pkill -f sidekiq
