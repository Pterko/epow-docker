#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Default RPC URL - can be overridden by environment variable
DEFAULT_RPC_URL="https://mainnetbeta-rpc.eclipse.xyz/"
RPC_URL="${RPC_URL:-$DEFAULT_RPC_URL}" # Use env var RPC_URL if set, otherwise use default

# Default CPU cores - can be overridden by environment variable
# If CPU_CORES is not set or empty, Bitz CLI will use its default
CPU_CORES_ARG=""
if [[ -n "$CPU_CORES" && "$CPU_CORES" -gt 0 ]]; then
  CPU_CORES_ARG="--cores $CPU_CORES"
  echo "INFO: Using specified CPU cores: $CPU_CORES"
else
  echo "INFO: Using default CPU cores."
fi

echo "INFO: Setting Solana RPC URL to: $RPC_URL"
# Run Solana config command - redirect output to avoid cluttering logs unless there's an error
if solana config set --url "$RPC_URL" > /dev/null; then
  echo "INFO: Solana RPC URL set successfully."
else
  echo "ERROR: Failed to set Solana RPC URL. Please check the URL and network connectivity."
  # Attempt to display the last few lines of the solana config log if it exists
  tail -n 5 ~/.config/solana/install/config.yml 2>/dev/null || true
  exit 1
fi

# Check if the keypair file exists at the expected mount point
KEYPAIR_PATH="/home/miner/.config/solana/id.json"
if [ ! -f "$KEYPAIR_PATH" ]; then
  echo "ERROR: Keypair file not found at $KEYPAIR_PATH."
  echo "Please ensure you have mounted your id.json file correctly using docker-compose volumes."
  exit 1
fi
echo "INFO: Keypair file found at $KEYPAIR_PATH."

# Execute the command passed to the container
case "$1" in
  mine)
    echo "INFO: Starting Bitz miner..."
    # Use exec to replace the script process with the bitz process
    exec bitz collect $CPU_CORES_ARG
    ;;
  claim)
    echo "INFO: Attempting to claim Bitz..."
    exec bitz claim
    ;;
  balance|account)
    echo "INFO: Checking Bitz account balance..."
    exec bitz account
    ;;
  *)
    # Execute any other bitz command passed directly
    echo "INFO: Executing custom command: bitz $@"
    exec bitz "$@"
    ;;
esac