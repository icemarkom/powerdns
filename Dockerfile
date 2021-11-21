# Common builder image.
FROM alpine:latest AS builder
RUN apk update
RUN apk add ca-certificates
RUN apk add curl build-base openssl-dev


# dnsdist builder image
FROM builder as dnsdist-builder
ARG dnsdist_version
RUN apk update
RUN apk add boost-dev lua-dev protobuf-dev libedit-dev re2-dev h2o-dev libsodium-dev
RUN curl -Ls "https://downloads.powerdns.com/releases/dnsdist-${dnsdist_version}.tar.bz2" | tar xj
WORKDIR "/dnsdist-${dnsdist_version}"
RUN ./configure \
      --host=$(uname -m) \
      --enable-dnscrypt \
      --enable-dns-over-tls \
      --enable-dns-over-https \
      --sysconfdir=/etc/dnsdist \
      --disable-dependency-tracking lua
RUN CXXFLAGS="-j1 V=1" make
RUN make install-strip

# server builder image
FROM builder as server-builder
ARG server_version
RUN apk update
RUN apk add boost-dev lua-dev protobuf-dev libsodium-dev sqlite-dev curl-dev mariadb-dev
RUN curl -Ls "https://downloads.powerdns.com/releases/pdns-${server_version}.tar.bz2" | tar xj
WORKDIR "/pdns-${server_version}"
RUN ./configure \
      --host=$(uname -m) \
      --enable-dns-over-tls \
      --sysconfdir=/etc/powerdns \
      --with-sqlite3 \
      --with-modules="gmysql gsqlite3 lua2" \
      --disable-dependency-tracking
RUN CXXFLAGS="-j1 V=1" make
RUN make install-strip

# recursor builder image
FROM builder as recursor-builder
ARG recursor_version
RUN apk update
RUN apk add boost-dev lua-dev libsodium-dev
RUN curl -Ls "https://downloads.powerdns.com/releases/pdns-recursor-${recursor_version}.tar.bz2" | tar xj
WORKDIR "/pdns-recursor-${recursor_version}"
RUN ./configure \
      --host=$(uname -m) \
      --enable-dns-over-tls \
      --sysconfdir=/etc/powerdns \
      --with-sqlite3 \
      --with-modules="gmysql gsqlite3 lua2" \
      --disable-dependency-tracking
RUN CXXFLAGS="-j1 V=1" make
RUN make install-strip

# Common prod image
FROM alpine:latest as prod
RUN apk update
RUN apk add ca-certificates openssl lua libsodium

# dnsdist image
FROM prod AS dnsdist
RUN apk add libedit re2 protobuf h2o
RUN addgroup -S dnsdist
RUN adduser -S -D -G dnsdist dnsdist
COPY --from=dnsdist-builder /usr/local/bin/ /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/dnsdist"]
CMD ["--help"]

# server image
FROM prod AS server
RUN apk add curl sqlite-libs libstdc++ mariadb-connector-c-dev
RUN addgroup -S pdns
RUN adduser -S -D -G pdns pdns
COPY --from=server-builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=server-builder /usr/local/bin/ /usr/local/bin/
COPY --from=server-builder /usr/local/lib/pdns/ /usr/local/lib/pdns/
ENTRYPOINT "/usr/local/sbin/pdns_server"
CMD ["--help"]

# recursor image
FROM prod AS recursor
#RUN apk add 
RUN addgroup -S pdns-recursor
RUN adduser -S -D -G pdns-recursor pdns-recursor
COPY --from=recursor-builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=recursor-builder /usr/local/bin/ /usr/local/bin/
COPY --from=recursor-builder /usr/local/lib/pdns/ /usr/local/lib/pdns/
ENTRYPOINT "/usr/local/sbin/pdns_recursor"
CMD ["--help"]
