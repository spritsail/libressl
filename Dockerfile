FROM frebib/debian-builder as builder

ARG ARCH=x86_64
ARG LIBRE_VER=2.5.4
ARG PREFIX=/output

WORKDIR $PREFIX

# Configure the output filesystem a bit
RUN mkdir -p bin lib && \
    # This is probably only relevant on 64bit systems?
    ln -sv lib lib64

WORKDIR /tmp

# Build and install LibreSSL
RUN mkdir -p libressl/build && cd libressl && \
    curl -L https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRE_VER}.tar.gz \
        | tar xz --strip-components=1 && \
    ./configure --prefix='' && \
    make -j "$(nproc)" && \
    make DESTDIR="$(pwd)/build" install

RUN cp -d libressl/build/lib/*.so* "${PREFIX}/lib" && \
    cp -d libressl/build/bin/openssl "${PREFIX}/bin" && \
    mkdir -p "${PREFIX}/etc/ssl" && \
    cp -d libressl/build/etc/ssl/openssl.cnf "${PREFIX}/etc/ssl" && \
    cd "${PREFIX}/lib" && \
    ln -s libssl.so "${PREFIX}/lib/libssl.so.1.0.0" && \
    ln -s libtls.so "${PREFIX}/lib/libtls.so.1.0.0" && \
    ln -s libcrypto.so "${PREFIX}/lib/libcrypto.so.1.0.0"

# =============

FROM adamant/busybox
COPY --from=builder /output/ /
