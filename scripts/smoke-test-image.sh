#!/bin/sh
set -eu

image="${1:?usage: $0 IMAGE [PLATFORM]}"
platform="${2:-linux/amd64}"
volume="agent-init-claude-smoke-$(date +%s)-$$"

cleanup() {
  docker volume rm "$volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker volume create "$volume" >/dev/null

docker run --rm --platform "$platform" -v "$volume:/agyn-bin" "$image"

docker run --rm --platform "$platform" -v "$volume:/agyn-bin" debian:bookworm-slim sh -c '
  set -eu
  test -x /agyn-bin/agynd
  test -x /agyn-bin/cli/agyn
  test -x /agyn-bin/claude
  test -r /agyn-bin/config.json
  grep -q "\"sdk\": \"claude\"" /agyn-bin/config.json
  grep -q "\"bin\": \"/agyn-bin/claude\"" /agyn-bin/config.json
  PATH=/agyn-bin/cli:/agyn-bin:$PATH
  export PATH LD_LIBRARY_PATH=/agyn-bin/lib
  command -v claude
  claude --version
'
