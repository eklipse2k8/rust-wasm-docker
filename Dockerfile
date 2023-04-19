# STAGE 1: binaryen

FROM debian:bullseye-slim as build-binaryen

RUN apt-get update \
    && apt-get install -y ca-certificates openssl build-essential cmake pkg-config curl tar ninja-build

WORKDIR /build

RUN curl -s --http2 -L -O https://github.com/WebAssembly/binaryen/archive/refs/tags/version_112.tar.gz \
    && tar -zxf version_112.tar.gz

WORKDIR /build/binaryen-version_112

RUN cmake -DBUILD_TESTS=OFF -G Ninja . \
    && ninja

# STAGE 2: wasm-pack

FROM rust:1-slim-bullseye as build-rust

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"

RUN set -eux; \
    apt-get update \
    && apt-get install -y locales curl gnupg ca-certificates openssl libssl-dev curl git pkg-config \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && dpkg-reconfigure --frontend noninteractive locales \
    && update-locale "LC_ALL=en_US.UTF-8" \
    && rustup target add wasm32-unknown-unknown \
    && curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh \
    && cargo install -f wasm-bindgen-cli \
    && cargo install -f cargo-cache \
    && cargo install -f sqlx-cli \
    && cargo cache -e \
    && apt-get remove -y --auto-remove curl git gnupg \
    && rm -rf /var/lib/apt/lists/*;

COPY --from=build-binaryen /build/binaryen-version_112/bin/* /usr/local/bin/
COPY --from=build-binaryen /build/binaryen-version_112/lib/* /usr/local/lib/
