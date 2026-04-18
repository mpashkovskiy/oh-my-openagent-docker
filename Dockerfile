# =============================================================================
# oh-my-openagent with GitHub Copilot Models
# =============================================================================
# Multi-stage build: install with Bun, then copy to minimal runtime image.
#
# Usage:
#   docker build -t oh-my-openagent .
#   docker run -it \
#     -v $(pwd):/workspace \
#     -v ~/.config/opencode:/root/.config/opencode \
#     -v ~/.local/share/opencode:/root/.local/share/opencode \
#     oh-my-openagent
#
# GitHub Copilot auth (first run):
#   docker run -it \
#     -v ~/.config/opencode:/root/.config/opencode \
#     -v ~/.local/share/opencode:/root/.local/share/opencode \
#     oh-my-openagent auth login
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1 - Install oh-my-openagent via Bun
# ---------------------------------------------------------------------------
FROM node:22-slim AS installer

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl bash git ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g bun

RUN curl -fsSL https://opencode.ai/install | bash

# Install oh-my-openagent with only GitHub Copilot enabled
RUN bunx oh-my-opencode install --no-tui \
    --claude=no \
    --openai=no \
    --gemini=no \
    --copilot=yes

# ---------------------------------------------------------------------------
# Stage 2 - Minimal runtime image
# ---------------------------------------------------------------------------
FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    ca-certificates \
    curl \
    gh \
    docker.io \
    clang-tools \
    golang \
    gopls \
    python3-pip \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --component rust-analyzer \
    && npm install -g typescript-language-server typescript vscode-langservers-extracted @grinev/opencode-telegram-bot \
    && pip install --break-system-packages pyright

ENV PATH="/root/.cargo/bin:${PATH}"

COPY --from=installer /root/.config/opencode /root/.config/opencode
COPY --from=installer /root/.opencode /root/.opencode
COPY --from=installer /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=installer /usr/local/bin /usr/local/bin

COPY oh-my-openagent.json /root/.config/opencode/oh-my-openagent.json

ENV PATH="/root/.opencode/bin:${PATH}"
ENV OPENCODE_CONFIG_DIR="/root/.config/opencode"
ENV XDG_DATA_HOME="/root/.local/share"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["opencode"]
