#!/bin/bash
set -e

OPENCODE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
AUTH_FILE="$OPENCODE_DATA_DIR/auth.json"

if [ "$1" = "auth" ] && [ "$2" = "login" ]; then
    mkdir -p "$OPENCODE_DATA_DIR"
    exec opencode auth login
fi

if [ "$1" = "opencode-telegram" ]; then
    shift
    exec opencode-telegram "$@"
fi

if [ ! -d "$OPENCODE_CONFIG_DIR" ] || [ -z "$(ls -A "$OPENCODE_CONFIG_DIR" 2>/dev/null)" ]; then
    echo "ERROR: No OpenCode config found at $OPENCODE_CONFIG_DIR"
    echo ""
    echo "This container expects host volumes to be mounted."
    echo "See README.md for setup instructions."
    exit 1
fi

if [ ! -f "$AUTH_FILE" ]; then
    echo "WARNING: No auth credentials found at $AUTH_FILE"
    echo ""
    echo "Authenticate with GitHub Copilot first:"
    echo "  docker compose run openagent auth login"
    echo ""
fi

exec "$@"
