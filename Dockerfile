ARG LIBRE_VER=2.6.4

FROM spritsail/debian-builder as builder

ARG ARCH=x86_64
ARG LIBRE_VER
ARG PREFIX=/output

WORKDIR $PREFIX

# Configure the output filesystem a bit
RUN mkdir -p usr/bin usr/lib/pkgconfig etc/ssl/certs

WORKDIR /tmp

# Build and install LibreSSL
RUN curl -sSL https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRE_VER}.tar.gz | tar xz && \
    cd libressl-${LIBRE_VER} && \
    ./configure \
        --prefix= \
        --exec-prefix=/usr && \
    make -j "$(nproc)" && \
    make DESTDIR="$(pwd)/build" install

RUN cd libressl-${LIBRE_VER} && \
    cp -d build/usr/lib/*.so* "${PREFIX}/usr/lib" && \
    cp -d build/usr/lib/pkgconfig/* "${PREFIX}/usr/lib/pkgconfig" && \
    cp -d build/usr/bin/openssl "${PREFIX}/usr/bin" && \
    mkdir -p "${PREFIX}/etc/ssl" && \
    cp -d build/etc/ssl/openssl.cnf "${PREFIX}/etc/ssl" && \
    cd "${PREFIX}/usr/lib" && \
    ln -s libssl.so libssl.so.1.0.0 && \
    ln -s libssl.so libssl.so.1.0 && \
    ln -s libtls.so libtls.so.1.0.0 && \
    ln -s libtls.so libtls.so.1.0 && \
    ln -s libcrypto.so libcrypto.so.1.0.0 && \
    ln -s libcrypto.so libcrypto.so.1.0

RUN update-ca-certificates && \
    cp /etc/ssl/certs/ca-certificates.crt "${PREFIX}/etc/ssl/certs"

# =============

FROM spritsail/busybox

ARG LIBRE_VER

LABEL maintainer="Spritsail <busybox@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="Busybox with LibreSSL" \
      org.label-schema.url="https://github.com/spritsail/busybox/tree/libressl" \
      org.label-schema.description="Busybox, GNU libc and LibreSSL built from source" \
      org.label-schema.version=${LIBRE_VER} \
      io.spritsail.version.libressl=${LIBRE_VER}

COPY --from=builder /output/ /
