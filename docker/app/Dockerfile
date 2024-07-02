# Install tools used when installing / building gems
# Use a debian ruby image rather than the base lambda one as that expects
# a lambda entry point
FROM ruby:3.2-slim
RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev

# Don't complain if bundler is run as root
ENV BUNDLE_SILENCE_ROOT_WARNING=1
# Try BUNDLE_DISABLE_EXEC_LOAD to true
ENV BUNDLE_DISABLE_EXEC_LOAD=true
ENV GEM_PATH /bundle
ENV BUNDLE_PATH /bundle

ENV APP_ROOT /var/www/docker-sinatra
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
ADD Gemfile* $APP_ROOT/
RUN gem install bundler -v 2.4.22
RUN bundle install
ADD . $APP_ROOT

EXPOSE 5000
CMD ["bundle", "exec", "rackup", "config.ru", "-p", "5000", "-s", "puma", "-o", "0.0.0.0", "-E", "production"]
