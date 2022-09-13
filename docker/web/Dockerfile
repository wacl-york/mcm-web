###############################################################################
FROM nginx:1-alpine AS web-library
RUN apk --no-cache add unzip
RUN mkdir /web

ENV WEB_LIBRARY_ROOT=https://uk-ac-york-its-faculty-dev-web-library.s3.amazonaws.com
ENV WEB_LIBRARY_VERSION=4.4.2

ARG WEB_LIBRARY_ROOT

ADD "${WEB_LIBRARY_ROOT}/main.zip" /
RUN unzip -o /main.zip -d /web/main

ARG WEB_LIBRARY_VERSION

ADD "${WEB_LIBRARY_ROOT}/${WEB_LIBRARY_VERSION}.zip" /
RUN unzip -o /${WEB_LIBRARY_VERSION}.zip -d /web/${WEB_LIBRARY_VERSION}

###############################################################################
FROM nginx:1-alpine AS web

WORKDIR /code

COPY vhost.conf /etc/nginx/conf.d/default.conf

COPY --from=web-library /web /code/web-library
