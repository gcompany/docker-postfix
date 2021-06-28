FROM alpine:3.9.6
# LABEL maintainer="Bojan Cekrlic - https://github.com/bokysan/docker-postfix/"

# Install supervisor, postfix
# Install postfix first to get the first account (101)
# Install opendkim second to get the second account (102)
RUN apk add --no-cache curl cmake clang make gcc g++ libc-dev pkgconfig curl-dev  && \
  curl -L  https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz --output /tmp/cyrus-sasl-2.1.27.tar.gz && \
  tar xvf /tmp/cyrus-sasl-2.1.27.tar.gz  -C /tmp/ && \
  cd /tmp/cyrus-sasl-2.1.27 && \
  ./configure && make && make install && \
  ln -s /usr/local/lib/sasl2 /usr/lib/sasl2 && \
  apk add --no-cache postfix postfix-lmdb && \
  apk add --no-cache opendkim && \
  apk add --no-cache --upgrade ca-certificates tzdata supervisor rsyslog musl musl-utils bash opendkim-utils libcurl jsoncpp lmdb && \
  (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true); \
  cp -r /etc/postfix /etc/postfix.template

# Copy SASL-XOAUTH2 plugin
# COPY       --from=build /sasl-xoauth2/build/src/libsasl-xoauth2.so /usr/lib/sasl2/

# Set up configuration
COPY       /configs/supervisord.conf     /etc/supervisord.conf
COPY       /configs/rsyslog*.conf        /etc/
COPY       /configs/opendkim.conf        /etc/opendkim/opendkim.conf
COPY       /configs/smtp_header_checks   /etc/postfix/smtp_header_checks
COPY       /scripts/*.sh                 /

RUN        chmod +x /run.sh /opendkim.sh

# Set up volumes
VOLUME     [ "/var/spool/postfix", "/etc/postfix", "/etc/opendkim/keys" ]

# Run supervisord
USER       root
WORKDIR    /tmp

ADD additional-config.sh /docker-init.db/

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD printf "EHLO healthcheck\n" | nc 127.0.0.1 587 | grep -qE "^220.*ESMTP Postfix"

EXPOSE     587
CMD        [ "/bin/sh", "-c", "/run.sh" ]
