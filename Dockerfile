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

LABEL org.opencontainers.image.source https://github.com/eklipse2k8/rust-wasm-docker

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
ENV LC_CTYPE="en_US.UTF-8"

RUN set -eux; \
    apt-get update \
    && apt-get install -y locales curl gnupg ca-certificates openssl libssl-dev curl git pkg-config \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && curl -sL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /usr/share/keyrings/nodesource.gpg >/dev/null \
    && curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_19.x bullseye main' > /etc/apt/sources.list.d/nodesource.list \
    && echo 'deb-src [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_19.x bullseye main' >> /etc/apt/sources.list.d/nodesource.list \
    && echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && locale-gen \
    && dpkg-reconfigure --frontend noninteractive locales \
    && update-locale "LC_ALL=en_US.UTF-8" \
    && apt-get install -y nodejs yarn \
    && rustup target add wasm32-unknown-unknown \
    && curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh \
    && cargo install -f wasm-bindgen-cli \
    && cargo install --force -F sys-openssl --no-default-features --git="https://github.com/rustwasm/wasm-pack#48177dc0" \
    && cargo install -f cargo-cache \
    && cargo install -f sqlx-cli \
    && cargo cache -e \
    && apt-get remove -y --auto-remove curl git gnupg \
    && rm -rf /var/lib/apt/lists/*;

COPY --from=build-binaryen /build/binaryen-version_112/bin/* /usr/local/bin/
COPY --from=build-binaryen /build/binaryen-version_112/lib/* /usr/local/lib/
