# syntax=docker/dockerfile:1

FROM golang:1.22-bookworm AS builder
WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY main.go captcha.go ./
RUN CGO_ENABLED=0 GOOS=linux go build \
    -mod=mod \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/zai-bridge \
    main.go
RUN CGO_ENABLED=0 GOOS=linux go build \
    -mod=mod \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/token-collector \
    captcha.go

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        chromium \
        fonts-liberation \
        sqlite3 \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --home-dir /app --create-home app \
    && mkdir -p /data /ms-playwright \
    && chown -R app:app /app /data /ms-playwright

WORKDIR /app
COPY --from=builder /out/zai-bridge /usr/local/bin/zai-bridge
COPY --from=builder /out/token-collector /usr/local/bin/token-collector
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/bin/chromium /usr/bin/chromium-browser

USER app

ENV HOST=0.0.0.0 \
    PORT=3001 \
    LOG_LEVEL=info \
    CAPTCHA_TOKENS=250 \
    CAPTCHA_BATCHES=1

VOLUME ["/data"]
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=3 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/status" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]