# generate image:
# docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag jarjoura/rust-wasm:buster-slim .

# STAGE 1: binaryen

FROM debian:buster-slim as build-binaryen

RUN apt-get update \
    && apt-get install -y ca-certificates openssl build-essential cmake pkg-config curl tar ninja-build

WORKDIR /build

RUN curl -s --http2 -L -O https://github.com/WebAssembly/binaryen/archive/refs/tags/version_111.tar.gz \
    && tar -zxf version_111.tar.gz 

WORKDIR /build/binaryen-version_111

RUN cmake -DBUILD_TESTS=OFF -G Ninja . \
    && ninja

# STAGE 2: wasm-pack

FROM rust:1-slim-buster as build-rust

RUN apt-get update \
    && apt-get install -y ca-certificates openssl libssl-dev curl pkg-config \
    && rustup target add wasm32-unknown-unknown \
    && curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh \
    && cargo install wasm-bindgen-cli

COPY --from=build-binaryen /build/binaryen-version_111/bin/* /usr/local/bin/
COPY --from=build-binaryen /build/binaryen-version_111/lib/* /usr/local/lib/

