# syntax=docker/dockerfile:1
FROM alpine:3.21

ARG AGYND_VERSION
ARG CLAUDE_VERSION
ARG TARGETARCH

RUN mkdir -p /tools

RUN apk add --no-cache curl && \
    curl -fsSL "https://github.com/agynio/agynd-cli/releases/download/v${AGYND_VERSION}/agynd-linux-${TARGETARCH}" \
      -o /tools/agynd && \
    chmod +x /tools/agynd

RUN case "${TARGETARCH}" in \
      amd64) PLATFORM="linux-x64-musl" ;; \
      arm64) PLATFORM="linux-arm64-musl" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_VERSION}/${PLATFORM}/claude" \
      -o /tools/claude && \
    chmod +x /tools/claude

COPY config.json /tools/config.json

ENTRYPOINT ["cp", "-a", "/tools/.", "/agyn-bin/"]
