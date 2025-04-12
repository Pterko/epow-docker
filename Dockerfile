# Use a stable Ubuntu base image
FROM ubuntu:22.04

# Set non-interactive frontend for apt commands
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables (used by root and miner)
# Skip Solana path modification during install script
ENV SOLANA_INSTALL_INIT_SKIP_PATH_MODIFICATION=1
# Define Rust/Cargo paths (will be owned by miner later)
ENV RUSTUP_HOME=/home/miner/.rustup \
    CARGO_HOME=/home/miner/.cargo \
    # Add Cargo bin and default Solana install location for miner to PATH
    PATH=/home/miner/.cargo/bin:/home/miner/.local/share/solana/install/active_release/bin:$PATH

# Install essential packages, curl, and potential Solana dependencies
# Run as root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    libudev-dev \
    bzip2 \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Solana CLI (as root)
# The script installs relative to $HOME, which is /root here.
# We adjust the PATH env var above assuming the miner user will use it later.
# If miner needs to directly call solana installed by root, the path might differ,
# but typically tools added to PATH work correctly regardless of who installed them.
RUN curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash miner

# Switch to the non-root user
USER miner
WORKDIR /home/miner

# Install Rust and Cargo (as miner)
# PATH is already set via ENV, so cargo command should be found after install
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

# Install Bitz CLI (as miner)
# cargo should be in PATH now
RUN cargo install bitz

# Ensure the default solana config directory exists for the miner user
RUN mkdir -p /home/miner/.config/solana

# Copy the entrypoint script into the container (owned by miner)
# Place this after USER miner so it has correct ownership implicitly
COPY --chown=miner:miner entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["mine"]