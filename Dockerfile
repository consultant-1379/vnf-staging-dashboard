FROM ruby:2.3.7-alpine3.7

# Install ruby and ruby-bundler
RUN apk update && \
    apk upgrade && \
    apk add openssh && \
    apk add --no-cache --virtual .gem-builddeps bash build-base git libffi-dev python2 re2c \
    zlib-dev libxml2-dev libxslt-dev && \
    apk add --no-cache nodejs

ADD . /usr/dashboard
WORKDIR /usr/dashboard

RUN gem install bundler:2.0.2 && \
    bundle install --no-cache --clean --standalone && \
    apk del --no-cache .gem-builddeps

EXPOSE 80
CMD ["smashing", "start"]
