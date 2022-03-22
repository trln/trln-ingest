FROM ruby:2.7-alpine AS builder

RUN apk update && apk upgrade && apk add --no-cache build-base sqlite-dev libpq-dev libxml2-dev libxslt-dev yajl git 

COPY ./ /app/

WORKDIR /app

RUN bundle config set path /gems && bundle install -j $(nproc)

FROM ruby:2.7-alpine

RUN apk add nodejs git bash libpq yajl sqlite sqlite-dev

WORKDIR /app

COPY --from=builder /gems /gems
RUN bundle config set path /gems

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 3000
CMD ["server"]

