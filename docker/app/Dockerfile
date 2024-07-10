# Install tools used when installing / building gems
# Use a debian ruby image rather than the base lambda one as that expects
# a lambda entry point
FROM ruby:3.2-slim
RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev git cmake libboost-all-dev catch2 libfreetype-dev

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

ENV ROOT /opt/rdkitsqlite
RUN git clone 'https://github.com/uoy-research/rdkit-sqlite' $ROOT

ENV RDKIT_ROOT $ROOT/rdkit
RUN git clone https://github.com/rdkit/rdkit.git $RDKIT_ROOT
RUN mkdir -p $RDKIT_ROOT/build
WORKDIR $RDKIT_ROOT/build
RUN cmake -DRDK_BUILD_CFFI_LIB=ON -DRDK_BUILD_INCHI_SUPPORT=ON -DRDK_BUILD_PYTHON_WRAPPERS=OFF ..
RUN make -j 2 cffi_test
RUN Code/MinimalLib/cffi_test
RUN make install

#WORKDIR $ROOT
#RUN make

EXPOSE 5000
CMD ["bundle", "exec", "rackup", "config.ru", "-p", "5000", "-s", "puma", "-o", "0.0.0.0", "-E", "production"]
