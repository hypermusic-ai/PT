# ==================
# Stage 1
# ==================
FROM ubuntu:latest AS build

# Create a working directory inside the container
WORKDIR /app

# Install tools
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    build-essential\
    clang libudev-dev llvm libclang-dev \
    protobuf-compiler\
    cmake \
    ninja-build\
    curl \
    libssl-dev \
    pkg-config \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustc --version

# Solana
RUN sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
ENV PATH="/root/.local/share/solana/install/active_release/bin:${PATH}"
RUN solana --version
ENV SOLANA_SDK="/root/.local/share/solana/install/active_release"

# Copy your source files into the container
COPY CMakeLists.txt .
COPY src/ ./src/

# Build the binary
RUN mkdir -p build && mkdir -p build/bin
RUN cmake -DCMAKE_BUILD_TYPE=Release -GNinja -S . -B ./build/ -DSOLANA_SDK=${SOLANA_SDK} && \
    cd build && ninja -j8 && cd ..



# ==================
# Stage 2
# ==================
FROM debian:bullseye-slim AS package

# Set working directory
WORKDIR /app

# Install  tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the build stage
COPY --from=build /app/program.wasm .

# Set the entrypoint for the container
ENTRYPOINT ["cat", "/app/program.wasm"]