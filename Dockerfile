FROM ruby:2.5

WORKDIR /app

COPY Gemfile Gemfile.lock *.gemspec ./
COPY lib/pharos/version.rb ./lib/pharos/
RUN bundle install

COPY . .

WORKDIR /tmp
ENTRYPOINT ["/app/bin/pharos-cluster"]
