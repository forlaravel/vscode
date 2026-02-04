# ── Multi-stage: grab Node.js and Composer ───────────────────────────────────
FROM node:22-bookworm-slim AS node
FROM composer:latest        AS composer

# ── Main image: PHP CLI on Debian Bookworm (glibc) ───────────────────────────
ARG INPUT_PHP="8.4"
FROM php:${INPUT_PHP}-cli-bookworm

# ── System packages ─────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    nano \
    git \
    jq \
    curl \
    wget \
    unzip \
    nginx \
    openssh-client \
    mariadb-client \
    procps \
    iproute2 \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libsodium-dev \
    libreadline-dev \
    libedit-dev \
    libonig-dev \
    libuuid1 \
    uuid-dev \
    && rm -rf /var/lib/apt/lists/*

# ── PHP extensions ──────────────────────────────────────────────────────────
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    intl \
    mbstring \
    opcache \
    pdo_mysql \
    sodium \
    xml \
    zip \
    pcntl \
    sockets

# ── PECL extensions ─────────────────────────────────────────────────────────
RUN pecl install apcu uuid redis xdebug \
    && docker-php-ext-enable apcu uuid redis xdebug

# ── Node.js 22 (from multi-stage) ──────────────────────────────────────────
COPY --from=node /usr/local/bin/node     /usr/local/bin/node
COPY --from=node /usr/local/bin/npm      /usr/local/bin/npm
COPY --from=node /usr/local/bin/npx      /usr/local/bin/npx
COPY --from=node /usr/local/bin/corepack /usr/local/bin/corepack
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# ── Composer (from multi-stage) ─────────────────────────────────────────────
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# ── code-server (dpkg on Debian — no musl workaround needed) ────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ── Self-signed SSL certificate for nginx ─────────────────────────────────────
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/selfsigned.key \
    -out /etc/nginx/ssl/selfsigned.crt \
    -subj "/C=NL/ST=Dev/L=Dev/O=Dev/CN=localhost"

# ── User: laravel UID 1000 with passwordless sudo ──────────────────────────
RUN useradd -m -s /bin/bash -u 1000 laravel \
    && echo "laravel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/laravel \
    && chmod 0444 /etc/sudoers.d/laravel

# ── Entrypoint ──────────────────────────────────────────────────────────────
COPY ./config/code-run /usr/local/bin/code-run
RUN chmod +x /usr/local/bin/code-run

# ── Helper tools ────────────────────────────────────────────────────────────
COPY ./tools/connect /usr/local/bin/connect
COPY ./tools/ports   /usr/local/bin/ports
COPY ./tools/app     /usr/local/bin/app
COPY ./tools/cl      /usr/local/bin/cl
RUN chmod +x /usr/local/bin/connect /usr/local/bin/ports /usr/local/bin/app /usr/local/bin/cl

# ── Xdebug defaults ────────────────────────────────────────────────────────
ENV PHP_XDEBUG_MODE="off"
ENV PHP_XDEBUG_START_WITH_REQUEST="yes"
ENV PHP_XDEBUG_CLIENT_HOST="localhost"
ENV PHP_XDEBUG_CLIENT_PORT="9003"

# ── code-server defaults ───────────────────────────────────────────────────
ENV VSCODE_HOST=0.0.0.0
ENV VSCODE_PORT=8585
ENV VSCODE_AUTH_MODE=
ENV VSCODE_PASSWORD=
ENV VSCODE_HASHED_PASSWORD=
ENV VSCODE_DISABLE_TELEMETRY=true
ENV VSCODE_SERVER_DATA_DIR=/home/laravel/.local/share/code-server
ENV VSCODE_EXTENSIONS_DIR=/home/laravel/.local/share/code-server/extensions
ENV VSCODE_CONFIG_FILE=/home/laravel/.config/code-server/config.yaml
ENV VSCODE_SOCKET_PATH=
ENV VSCODE_PROXY_DOMAIN=
ENV VSCODE_DEFAULT_FOLDER=/app
ENV VSCODE_PROXY_URI=

EXPOSE 8000 8443 9003

# ── Switch to laravel user ──────────────────────────────────────────────────
USER laravel
ENV HOME=/home/laravel
WORKDIR /home/laravel

# ── Bash aliases ────────────────────────────────────────────────────────────
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/laravel/.bashrc && \
    echo "alias pa='php artisan'" >> /home/laravel/.bashrc && \
    echo "alias ll='ls -la --block-size=M'" >> /home/laravel/.bashrc && \
    echo "alias ..='cd ..'" >> /home/laravel/.bashrc && \
    echo "alias ...='cd ../..'" >> /home/laravel/.bashrc

# ── Claude CLI ──────────────────────────────────────────────────────────────
RUN curl -fsSL https://claude.ai/install.sh | bash

# ── Entrypoint: code-server with auto-restart ──────────────────────────────
ENTRYPOINT []
CMD ["/usr/local/bin/code-run"]
