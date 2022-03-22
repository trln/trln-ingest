#!/bin/sh

# ensures configuration is uploaded; assumes configuration is mounted
# at /trlnbib-config
/opt/solr/server/scripts/cloud-scripts/zkcli.sh -zkhost ${ZK_HOST:-zootopia:2181} -cmd upconfig -confname trlnbib -confdir /trlnbib-config

