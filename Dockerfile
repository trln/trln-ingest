from ruby:2.7.6 as base

RUN apt-get update && apt-get upgrade && apt-get install -y git nodejs

FROM base AS builder

RUN mkdir /build

COPY Gemfile Gemfile.lock /build
WORKDIR /build

RUN bundle config set path /gems

RUN bundle install -j $(nproc)

FROM base 

LABEL org.trln.discovery=trln-ingest

COPY --from=builder /gems /gems

RUN bundle config set path /gems

COPY entrypoint /usr/local/bin

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/entrypoint"]

CMD ["start"]
