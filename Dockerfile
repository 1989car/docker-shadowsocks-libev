#
#     Dockerfile      for shadowsocks-libev
#

FROM  alpine

LABEL maintainer      =   "Che Haojia <chehaojia@gmail.com>"

ARG VERSION=3.2.5
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$VERSION/shadowsocks-libev-$VERSION.tar.gz

ENV   SERVER_ADDR     0.0.0.0
ENV   SERVER_PORT     8388
ENV   SS_PASSWORD     1234567890  
ENV   SS_METHOD       chacha20-ietf-poly1305
ENV   SS_TIMEOUT      300
ENV   DNS_ADDR_1      8.8.8.8
ENV   DNS_ADDR_2      8.8.4.4
ENV   ARGS            -v

RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                tar \
                                c-ares-dev && \
    mkdir -p /tmp/ss && \
    cd /tmp/ss && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/,"\nso:", $2); print"so:"$2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    cd / && rm -rf /tmp/*

EXPOSE $SERVER_PORT

CMD ss-server --fast-open \
              -a nobody \
              -s $SERVER_ADDR \
              -p $SERVER_PORT \
              -k ${SS_PASSWORD:-$(hostname)} \
              -m $SS_METHOD \
              -t $TIMEOUT \
              -d $DNS_ADDR_1 \
              -d $DNS_ADDR_2 \
              --no-delay \
              -u \
              $ARGS


