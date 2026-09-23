FROM rust:1.93-bookworm AS rust
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl build-essential pkg-config libclang-dev \
    libxcb1-dev libxrandr-dev libdbus-1-dev libpipewire-0.3-dev \
    libwayland-dev libegl-dev libgbm-dev xvfb xauth \
    && rm -rf /var/lib/apt/lists/*
COPY --from=rust /usr/local/rustup /usr/local/rustup
COPY --from=rust /usr/local/cargo /usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH
# Minimal containers omit the stock client.conf needed for context creation.
RUN apt-get update && apt-get install -y --no-install-recommends libpipewire-0.3-common \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /check
COPY scripts/install-spa-headers.sh /check/scripts/install-spa-headers.sh
RUN bash scripts/install-spa-headers.sh /opt/spa-headers
ENV PKG_CONFIG_PATH=/opt/spa-headers/lib/pkgconfig
COPY tests/linux-spa/Cargo.toml /check/Cargo.toml
COPY tests/linux-spa/src /check/src
RUN cargo build && \
    test "$(pkg-config --modversion libpipewire-0.3)" = 0.3.48 && \
    ldd target/debug/linux-spa-compatibility && \
    LD_BIND_NOW=1 xvfb-run -a target/debug/linux-spa-compatibility
