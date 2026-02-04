<p align="center">
  <h1 align="center">forlaravel/vscode</h1>
  <p align="center">
    A batteries-included VS Code (code-server) Docker image for Laravel development with PHP, Node.js, Composer, and Claude CLI.
  </p>
</p>

<p align="center">
  <a href="https://github.com/forlaravel/vscode/actions/workflows/scheduled-rebuild.yml">
    <img src="https://github.com/forlaravel/vscode/actions/workflows/scheduled-rebuild.yml/badge.svg" alt="Weekly Rebuild">
  </a>
</p>

## Available Tags

| Tag | PHP Version |
|-----|-------------|
| `1.0-php8.4`, `latest-php8.4` | PHP 8.4 |
| `1.0-php8.5`, `latest-php8.5` | PHP 8.5 |

```bash
docker pull ghcr.io/forlaravel/vscode:1.0-php8.4
```

## What's Included

- **code-server** — VS Code in the browser
- **PHP** (configurable version) with extensions: bcmath, gd, intl, mbstring, opcache, pdo_mysql, sodium, xml, zip, pcntl, sockets, apcu, uuid, redis, xdebug
- **Node.js 22** with npm and corepack
- **Composer** (latest)
- **Claude CLI** — AI assistant in the terminal
- **nginx** — reverse proxy with HTTP/HTTPS and port forwarding
- **Self-signed SSL** certificate for local HTTPS
- **MariaDB client**
- **Helper commands**: `app`, `ports`, `connect`, `cl` (Claude)
- **Bash aliases**: `pa` (php artisan), `ll`, `..`, `...`

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 8000 | HTTP | nginx reverse proxy (code-server + port forwarding) |
| 8443 | HTTPS | nginx reverse proxy with self-signed SSL |
| 9003 | TCP | Xdebug client port |

## Configuration

### Xdebug Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_XDEBUG_MODE` | `off` | Xdebug mode (`off`, `debug`, `develop`, `coverage`, `profile`, `trace`) |
| `PHP_XDEBUG_START_WITH_REQUEST` | `yes` | When to start debugging |
| `PHP_XDEBUG_CLIENT_HOST` | `localhost` | IDE host for Xdebug connections |
| `PHP_XDEBUG_CLIENT_PORT` | `9003` | IDE port for Xdebug connections |

### code-server Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VSCODE_HOST` | `0.0.0.0` | Bind address for nginx |
| `VSCODE_PORT` | `8585` | Internal code-server port (behind nginx) |
| `VSCODE_AUTH_MODE` | *(auto-detect)* | Auth mode: `none` or `password`. Auto-detects from password vars |
| `VSCODE_PASSWORD` | *(empty)* | Plain-text password for code-server |
| `VSCODE_HASHED_PASSWORD` | *(empty)* | Hashed password (argon2 format) |
| `VSCODE_DISABLE_TELEMETRY` | `true` | Disable code-server telemetry |
| `VSCODE_SERVER_DATA_DIR` | `/home/laravel/.local/share/code-server` | User data directory |
| `VSCODE_EXTENSIONS_DIR` | `/home/laravel/.local/share/code-server/extensions` | Extensions directory |
| `VSCODE_CONFIG_FILE` | `/home/laravel/.config/code-server/config.yaml` | Config file path |
| `VSCODE_SOCKET_PATH` | *(empty)* | Unix socket path (overrides TCP) |
| `VSCODE_PROXY_DOMAIN` | *(empty)* | Proxy domain for code-server |
| `VSCODE_DEFAULT_FOLDER` | `/app` | Default folder to open in the editor |
| `VSCODE_PROXY_URI` | *(empty)* | Proxy URI |
| `VSCODE_LOG_LEVEL` | *(empty)* | Log level (e.g., `debug`, `info`, `warn`) |
| `VSCODE_VERBOSE` | *(empty)* | Set to `true` for verbose output |

## Quick Start

```yaml
services:
  vscode:
    image: ghcr.io/forlaravel/vscode:1.0-php8.4
    ports:
      - "8000:8000"
      - "8443:8443"
    volumes:
      - ./:/app
    environment:
      VSCODE_PASSWORD: "secret"
      PHP_XDEBUG_MODE: "debug"
      PHP_XDEBUG_CLIENT_HOST: "host.docker.internal"
```

Open [http://localhost:8000](http://localhost:8000) or [https://localhost:8443](https://localhost:8443) to access VS Code.

## Custom Scripts

Mount executable scripts to `/custom-scripts/after-boot/` and they will run automatically when the container starts (before code-server launches).

```yaml
volumes:
  - ./scripts/after-boot:/custom-scripts/after-boot
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `pa` | Alias for `php artisan` |
| `ports` | Interactive port viewer — list listening ports and kill processes |
| `connect HOST PORT` | TCP connectivity checker with timeout |
| `app deploy` | Deploy via SSH/rsync (configure with `.deploy` file) |
| `app connect` | SSH to deployment target via jump host |
| `cl` | Launch Claude CLI with bypass permissions |

## SSL / HTTPS

The image includes a self-signed certificate at `/etc/nginx/ssl/`. Port 8443 serves HTTPS automatically. For custom certificates, mount your own:

```yaml
volumes:
  - ./certs/cert.crt:/etc/nginx/ssl/selfsigned.crt:ro
  - ./certs/cert.key:/etc/nginx/ssl/selfsigned.key:ro
```

## Port Forwarding

nginx supports automatic port forwarding via subdomains. Access `dev-fwd-{port}.localhost:8000` to proxy to `localhost:{port}` inside the container. This is useful for previewing Laravel apps or other services running in the container.

## Local Build

```bash
# Build for PHP 8.4 (default, loads locally)
./build.sh

# Build for PHP 8.5
./build.sh 8.5

# Build and push to GHCR
./build.sh 8.4 --push
```
