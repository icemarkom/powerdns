###############################################################################
#
# Common builder image.
#
FROM alpine AS pdns-builder

RUN apk --update upgrade && \
    apk add ca-certificates curl && \
    apk add --virtual .build-depends \
            file g++ make boost-dev libsodium-dev lua-dev \
            net-snmp-dev protobuf-dev libedit-dev re2-dev


###############################################################################
#
# Build the dnsdist.
#
FROM pdns-builder AS dnsdist-builder

ARG dnsdist_name=dnsdist
ARG dnsdist_ver=1.3.3

RUN echo "Building ${dnsdist_name} version ${dnsdist_ver}" && \
    curl -RL -O "https://downloads.powerdns.com/releases/${dnsdist_name}-${dnsdist_ver}.tar.bz2" && \
    tar xvfj "${dnsdist_name}-${dnsdist_ver}.tar.bz2" && \
    rm -f "${dnsdist_name}-${dnsdist_ver}.tar.bz2"

RUN cd "${dnsdist_name}-${dnsdist_ver}" && \
    ./configure \
      --sysconfdir=/etc/pdns \
      --mandir=/usr/share/man \
      --enable-dnscrypt \
      --enable-dns-over-tls \
      --enable-libsodium \
      --enable-re2 \
      --with-net-snmp

RUN cd "${dnsdist_name}-${dnsdist_ver}" && \
    make && \
    make install-strip

RUN apk del --purge .build-depends && \
    rm -rf /var/cache/apk/*


###############################################################################
#
# Final dnsdist image.
#
FROM alpine AS dnsdist

RUN apk --update upgrade && \
    apk add ca-certificates curl less man openssl \
            libedit re2 libsodium lua net-snmp protobuf && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 2500 -S pdns && \
    adduser -u 2500 -S -D -G pdns pdns

COPY --from=dnsdist-builder /usr/local/bin/ /usr/local/bin/
COPY --from=dnsdist-builder /usr/share/man/man1/ /usr/share/man/man1/

ENTRYPOINT ["/usr/local/bin/dnsdist"]
CMD ["--help"]

