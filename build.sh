#!/bin/bash
set -e

IMAGE="ghcr.io/forlaravel/vscode"
PHP_VERSION="${1:-8.4}"
VERSION_TAG="1.0"

# Determine load or push mode
MODE="--load"
if [[ "$2" == "--push" ]]; then
  MODE="--push"
fi

echo "Building ${IMAGE} for PHP ${PHP_VERSION}..."

docker buildx build \
  --build-arg INPUT_PHP="${PHP_VERSION}" \
  --tag "${IMAGE}:${VERSION_TAG}-php${PHP_VERSION}" \
  --tag "${IMAGE}:latest-php${PHP_VERSION}" \
  ${MODE} \
  .

echo "Done. Tags:"
echo "  ${IMAGE}:${VERSION_TAG}-php${PHP_VERSION}"
echo "  ${IMAGE}:latest-php${PHP_VERSION}"
