FROM python:3.8-alpine
MAINTAINER Matt Zuba <matt.zuba@goodwillaz.org>

# Some stuff we'll always need
RUN apk add --quiet --no-cache --no-progress --virtual build-deps build-base libffi-dev openssl-dev && \
    apk add --quiet --no-cache --no-progress git && \
    pip install --quiet awsebcli && \
    apk del --quiet build-deps

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
