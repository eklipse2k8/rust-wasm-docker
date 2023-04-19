# rust-wasm-docker

This ia a Docker image for building Rust WebAssembly (wasm) binaries.

It has both the native toolchain and the wasm32-unknown-unknown toolchain installed.

## Usage

```bash
docker buildx build --push --platform linux/arm64/v8,linux/amd64 --tag eklipse2k8/rust-wasm:bullseye-slim .
```
