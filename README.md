# oh-my-openagent Docker

Dockerized [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) configured with GitHub Copilot models.

## Prerequisites

- Docker
- A GitHub Copilot subscription (Individual, Business, or Enterprise)

## Quick Start

### 1. Build

```bash
docker build -t oh-my-openagent .
```

### 2. Create host directories

```bash
mkdir -p ~/.config/opencode ~/.local/share/opencode ~/.local/state/opencode
```

### 3. Authenticate with GitHub Copilot

```bash
docker run -it \
  -v ~/.local/share/opencode:/root/.local/share/opencode \
  -v ~/.local/state/opencode:/root/.local/state/opencode \
  oh-my-openagent auth login
```

Select **GitHub Copilot** when prompted and complete the device code flow in your browser. This is a one-time step — credentials persist on your host.

### 4. Run

Navigate to the directory with your project and run:

```bash
docker run -it \
  -v ~/.local/share/opencode:/root/.local/share/opencode \
  -v ~/.local/state/opencode:/root/.local/state/opencode \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v .:/workspace \
  oh-my-openagent opencode
```

Or use following command to use it in the browser (user/password: opencode/Qw2e3r4)

```bash
docker run -d \
  -e OPENCODE_SERVER_PASSWORD=Qw2e3r4 \
  --network host \
  -v ~/.local/share/opencode:/root/.local/share/opencode \
  -v ~/.local/state/opencode:/root/.local/state/opencode \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v .:/workspace \
  oh-my-openagent opencode web --hostname 0.0.0.0
```

### 5. Run with Telegram (optional)

```bash
docker compose --profile telegram up -d
```

Adds the Telegram bot alongside the server and TUI. See [Telegram Access](#telegram-access-opencode-telegram-bot) for setup.

### Stopping

```bash
docker compose down
```

## Telegram Access (opencode-telegram-bot)

The image includes [opencode-telegram-bot](https://github.com/grinev/opencode-telegram-bot) — a Telegram bot that lets you interact with OpenCode from your phone or any device via Telegram.

### Setup

1. Create a bot with [@BotFather](https://t.me/BotFather) on Telegram and copy the token
2. Get your Telegram user ID from [@userinfobot](https://t.me/userinfobot)
3. Run the config wizard (one-time):

```bash
docker compose run opencode-telegram opencode-telegram config
```

The configuration is saved to `~/.config/opencode-telegram-bot/.env` on your host.

### Usage

```bash
docker compose --profile telegram up
```

Both the TUI (`opencode attach`) and the Telegram bot connect to the same `opencode serve` instance, so you can interact from either the terminal or Telegram simultaneously. See the [opencode-telegram-bot README](https://github.com/grinev/opencode-telegram-bot) for the full command reference.

## Volume Mounts

| Host Path | Container Path | Contents |
|---|---|---|
| `~/.config/opencode` | `/root/.config/opencode` | Plugin config, model assignments |
| `~/.local/share/opencode` | `/root/.local/share/opencode` | Auth credentials (`auth.json`), session DB (`opencode.db`), logs |
| `~/.local/state/opencode` | `/root/.local/state/opencode` | Plugin metadata, lock files, model state |
| `~/.config/opencode-telegram-bot` | `/root/.config/opencode-telegram-bot` | Telegram bot config (`.env`) |
| `$(pwd)` or `./workspace` | `/workspace` | Your project directory |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker-in-Docker access |

### Where are my credentials?

OpenCode stores GitHub Copilot OAuth tokens at `~/.local/share/opencode/auth.json` (written with `0600` permissions). This file is created by `opencode auth login` and is required for Copilot models to work.

### Where are my sessions?

Session history is stored in `~/.local/share/opencode/opencode.db` (SQLite). This is persisted via the same volume mount as auth.

## Model Assignments

This image uses **corrected** GitHub Copilot model names (the installer's defaults contained invalid model IDs):

| Agent | Model |
|---|---|
| Sisyphus (orchestrator) | `github-copilot/claude-opus-4.6` |
| Oracle (deep reasoning) | `github-copilot/gpt-4o` |
| Hephaestus | `github-copilot/gpt-4o` |
| Prometheus (planning) | `github-copilot/claude-opus-4.6` |
| Atlas (task management) | `github-copilot/claude-sonnet-4.5` |
| Explore (code search) | `github-copilot/claude-haiku-4.5` |
| Multimodal Looker | `github-copilot/gpt-4o` |

Full model config is in `oh-my-openagent.json` (bundled into the image at `/root/.config/opencode/oh-my-openagent.json`).

## LSP Servers

The image includes language servers for code intelligence (diagnostics, references, rename). They run inside the container via stdio — no ports needed.

| Language | LSP Server |
|---|---|
| TypeScript/JavaScript | `typescript-language-server` |
| Python | `pyright` |
| C/C++ | `clangd` |
| Go | `gopls` |
| Rust | `rust-analyzer` |
| JSON/HTML/CSS | `vscode-langservers-extracted` |

## Environment Variables

Instead of mounting auth files, you can pass a token directly:

```bash
docker run -it \
  -e GITHUB_TOKEN=ghp_xxxx \
  -v $(pwd):/workspace \
  -v ~/.config/opencode:/root/.config/opencode \
  -v ~/.local/share/opencode:/root/.local/share/opencode \
  -v ~/.local/state/opencode:/root/.local/state/opencode \
  -v /var/run/docker.sock:/var/run/docker.sock \
  oh-my-openagent
```

Token precedence: `COPILOT_GITHUB_TOKEN` > `GH_TOKEN` > `GITHUB_TOKEN` > `auth.json`

## Troubleshooting

**"No auth credentials found"** — Run `auth login` first (step 3 above).

**"configured model ... is not valid"** — The bundled `oh-my-openagent.json` uses corrected model names. If you mounted a host config that still has old names, update it or remove it to use the bundled version.

**"OpenCode binary not found" in doctor output** — This is expected during the build stage only. The final image has OpenCode at `/root/.opencode/bin/opencode`.

**Verify your setup:**

```bash
docker run --rm --entrypoint="" oh-my-openagent opencode --version
docker run --rm --entrypoint="" oh-my-openagent bunx oh-my-opencode doctor
```
