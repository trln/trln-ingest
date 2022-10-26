FROM solr:9.0.0

# Install necessary contrib jars
#RUN cp /opt/solr/contrib/analysis-extras/lib/icu*.jar /opt/solr/contrib/analysis-extras/lucene-libs/*icu*.jar /opt/solr/server/solr/lib

# Add external jars
#RUN sudo mkdir /opt/solr-9.0.0/modules/trln
COPY plugins/*.jar /opt/solr/modules/trln/lib/

COPY config/ /trlnbib-config
