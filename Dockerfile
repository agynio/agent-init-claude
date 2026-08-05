# syntax=docker/dockerfile:1
FROM alpine:3.21

ARG CLAUDE_VERSION
ARG TARGETARCH

# agynd and the agyn CLI are not here: they ship with the platform and arrive
# in the same volume from their own init images, so this pins one agent CLI.
RUN mkdir -p /tools

RUN apk add --no-cache curl patchelf && \
    case "${TARGETARCH}" in \
      amd64) PLATFORM="linux-x64-musl"; MUSL_LOADER="ld-musl-x86_64.so.1"; MUSL_LIBC="libc.musl-x86_64.so.1" ;; \
      arm64) PLATFORM="linux-arm64-musl"; MUSL_LOADER="ld-musl-aarch64.so.1"; MUSL_LIBC="libc.musl-aarch64.so.1" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${CLAUDE_VERSION}/${PLATFORM}/claude" \
      -o /tools/claude && \
    chmod +x /tools/claude && \
    mkdir -p /tools/lib && \
    cp "/lib/${MUSL_LOADER}" "/tools/lib/${MUSL_LOADER}" && \
    ln -s "${MUSL_LOADER}" "/tools/lib/${MUSL_LIBC}" && \
    patchelf --set-interpreter "/agyn/bin/lib/${MUSL_LOADER}" /tools/claude

RUN apk add --no-cache libgcc libstdc++ && \
    mkdir -p /tools/lib && \
    cp /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 /tools/lib/

COPY config.json /tools/config.json

ENTRYPOINT ["cp", "-a", "/tools/.", "/agyn/bin/"]
