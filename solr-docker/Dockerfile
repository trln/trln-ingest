FROM solr:7.7.3

# Install necessary contrib jars
RUN cp /opt/solr/contrib/analysis-extras/lib/icu*.jar /opt/solr/contrib/analysis-extras/lucene-libs/*icu*.jar /opt/solr/server/solr/lib

# Add external jars
COPY *.jar /opt/solr/server/solr/lib

COPY config/solr/trlnbib /trlnbib-config
