#!/bin/sh
set -eu

image="${1:?usage: $0 IMAGE [PLATFORM]}"
platform="${2:-linux/amd64}"
volume="agyn-runtime-claude-smoke-$(date +%s)-$$"

cleanup() {
  docker volume rm "$volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker volume create "$volume" >/dev/null

docker run --rm --platform "$platform" -v "$volume:/agyn" "$image"

docker run --rm --platform "$platform" -v "$volume:/agyn" debian:bookworm-slim sh -c '
  set -eu
  # agynd and the agyn CLI come from their own init images into this same
  # volume; this image is responsible for the agent CLI alone.
  test -x /agyn/bin/claude
  test -r /agyn/config.json
  grep -q "\"sdk\": \"claude\"" /agyn/config.json
  # Relative to the volume: the image states what it carries, not where the
  # platform mounted it.
  grep -q "\"bin\": \"bin/claude\"" /agyn/config.json
  PATH=/agyn/bin:$PATH
  export PATH LD_LIBRARY_PATH=/agyn/bin/lib
  command -v claude
  claude --version
'
