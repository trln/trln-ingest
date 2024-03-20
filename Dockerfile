# Dockerfile
# Build instructions for dul-argon-skin
#
# This serves as a "build" playbook of sorts
FROM image-mirror-prod-registry.cloud.duke.edu/library/ruby:3.1

# Become the root user
USER 0

# Add any system packages here.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
     git \
     wait-for-it \
     vim \
     shared-mime-info \
     rsync \
	&& rm -rf /var/lib/apt/lists/*


WORKDIR app
COPY Gemfile* ./
# RUN gem install bundler
RUN gem install bundler -v 2.4.22
RUN bundle install

COPY . .

RUN chmod -R a+rw /app
RUN chown -R 1001:1001 /app

COPY entrypoint /usr/local/bin/entrypoint

RUN chmod a+x /usr/local/bin/entrypoint

EXPOSE 9292
EXPOSE 3000
EXPOSE 3001

USER 1001

# CMD ["start"]
#ENTRYPOINT ["entrypoint"]
#CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]
