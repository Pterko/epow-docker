# Use a stable Ubuntu base image
FROM ubuntu:22.04

# Set non-interactive frontend for apt commands
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash miner
USER miner
WORKDIR /home/miner

# Install Rust and Cargo
ENV RUSTUP_HOME=/home/miner/.rustup \
    CARGO_HOME=/home/miner/.cargo \
    PATH=/home/miner/.cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

# Install Solana CLI
# Skip path modification as we set PATH env var manually
ENV SOLANA_INSTALL_INIT_SKIP_PATH_MODIFICATION=1 \
    PATH=/home/miner/.local/share/solana/install/active_release/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash

# Install Bitz CLI
RUN cargo install bitz

# Ensure the default solana config directory exists
RUN mkdir -p /home/miner/.config/solana

# Copy the entrypoint script into the container
COPY --chown=miner:miner entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["mine"]