# STAGE 1: binaryen

FROM debian:bookworm-slim as build-binaryen

RUN set -eux; \
    apt-get update \
    && apt-get update \
    && apt-get install -y locales ca-certificates openssl build-essential cmake pkg-config curl tar ninja-build \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && dpkg-reconfigure --frontend noninteractive locales \
    && update-locale "LC_ALL=en_US.UTF-8"

WORKDIR /build

ENV BINARYEN_VERSION=117
ENV BINARYEN_ARCHIVE="version_${BINARYEN_VERSION}.tar.gz"

RUN curl -s --http2 -L -O "https://github.com/WebAssembly/binaryen/archive/refs/tags/${BINARYEN_ARCHIVE}" \
    && tar -zxf "${BINARYEN_ARCHIVE}"

WORKDIR /build/binaryen-version_${BINARYEN_VERSION}

RUN cmake -DBUILD_TESTS=OFF -G Ninja . \
    && ninja

# STAGE 2: wasm-pack

FROM rust:1-slim-bookworm as build-rust

ENV BINARYEN_VERSION=117

LABEL org.opencontainers.image.source https://github.com/eklipse2k8/rust-wasm-docker

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"

RUN set -eux; \
    apt-get update \
    && apt-get install -y locales curl gnupg ca-certificates openssl libssl-dev curl build-essential cmake ninja-build git pkg-config \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && curl -sL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /usr/share/keyrings/nodesource.gpg >/dev/null \
    && curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x bookworm main' > /etc/apt/sources.list.d/nodesource.list \
    && echo 'deb-src [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x bookworm main' >> /etc/apt/sources.list.d/nodesource.list \
    && echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && locale-gen \
    && dpkg-reconfigure --frontend noninteractive locales \
    && update-locale "LC_ALL=en_US.UTF-8" \
    && apt-get install -y nodejs yarn \
    && rustup target add wasm32-unknown-unknown \
    && curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh \
    && cargo install -f wasm-bindgen-cli \
    && cargo install -f wasm-pack \
    && cargo install -f cargo-cache \
    && cargo install -f sqlx-cli \
    && cargo cache -e \
    && apt-get remove -y --auto-remove curl git gnupg \
    && rm -rf /var/lib/apt/lists/*;

COPY --from=build-binaryen /build/binaryen-version_${BINARYEN_VERSION}/bin/* /usr/local/bin/
COPY --from=build-binaryen /build/binaryen-version_${BINARYEN_VERSION}/lib/* /usr/local/lib/
