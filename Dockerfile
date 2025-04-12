# Use the Ubuntu base image that solves the GLIBC issue
FROM ubuntu:24.04

# Set non-interactive frontend for apt commands
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for the root user
ENV RUSTUP_HOME=/root/.rustup \
    CARGO_HOME=/root/.cargo \
    # Add Cargo bin and default Solana install location for root to PATH
    PATH=/root/.cargo/bin:/root/.local/share/solana/install/active_release/bin:$PATH \
    # Skip Solana path modification during install script
    SOLANA_INSTALL_INIT_SKIP_PATH_MODIFICATION=1

# Set a working directory
WORKDIR /app

# Install essential packages, curl, and potential Solana dependencies
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

# Install Rust and Cargo (as root)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

# Install Solana CLI (as root)
# This works with GLIBC in ubuntu:24.04
RUN curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash

# Install Bitz CLI (as root)
# cargo should be in PATH now
RUN cargo install bitz

# Ensure the default solana config directory exists for the root user
RUN mkdir -p /root/.config/solana

# Copy the entrypoint script into the container (will be owned by root)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# <<< --- ADD THIS LINE to fix line endings --- >>>
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Add this temporarily to verify existence and permissions during build
RUN ls -l /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["mine"]