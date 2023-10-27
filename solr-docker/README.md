# Docker/Podman setup for Solr

This directory contains customizations to run Solr in a container via `docker
compose` or `podman-compose` for purposes of local development.

It assumes that the TRLN Discovery Solr configset has already been installed into the `config` subdirectory. See the `init.sh` file in the parent directory for
more information.

## Rationale

The official Solr containers from the Apache Solr project provide a number of
features to get up and running quickly, but they're mostly geared around
creating _cores_ rather than _collections_; the Rails application assumes it's
working in a Solr Cloud deployment, because that's what's available in
production.

Using collections rather than cores means we have to do quite a bit more setup,
over and above ensuring that the configset is available, and most of what
happens in the Dockerfile is oriented around that setup.

Additionaly, the Rails application will create the `trlnbib` collection when
running in `development` mode if it does not already exist.
