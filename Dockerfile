# syntax=docker/dockerfile:1

FROM golang:1.22-alpine AS builder
WORKDIR /src

COPY go.mod ./
RUN go mod download modernc.org/sqlite

COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build \
    -mod=mod \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/zai-bridge \
    main.go

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -G app -h /app app \
    && mkdir -p /data \
    && chown -R app:app /app /data

WORKDIR /app
COPY --from=builder /out/zai-bridge /usr/local/bin/zai-bridge

USER app

ENV HOST=0.0.0.0 \
    PORT=3001 \
    LOG_LEVEL=info

VOLUME ["/data"]
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/status" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/zai-bridge"]
CMD ["--db-path", "/data/tokens.sqlite"]
