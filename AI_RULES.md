# AI Rules

## Tech stack

- Go 1.22 powers the HTTP bridge and all production API endpoints.
- The production server uses Go's standard `net/http` package and `http.ServeMux`.
- JSON encoding and decoding use the standard `encoding/json` package.
- SQLite is the only datastore and is accessed through `database/sql`.
- `modernc.org/sqlite` is the required pure-Go SQLite driver; production builds must keep CGO disabled.
- Server-sent events (SSE) provide OpenAI- and Anthropic-compatible streaming responses.
- `captcha.go` is a separate token-collection utility using Playwright for Go, Bubble Tea, and Lip Gloss.
- `image-gen/image-gen.js` is a standalone Node.js CLI using only Node built-in modules.
- Docker uses a multi-stage Alpine build and persists runtime data under `/data`.

## Library and implementation rules

- Prefer the Go standard library for HTTP, JSON, cryptography, compression, logging, flags, and concurrency; add a third-party package only when the standard library cannot reasonably meet the requirement.
- Use `modernc.org/sqlite` with `database/sql` for all SQLite access; do not introduce CGO-based SQLite drivers.
- Keep production HTTP routes and middleware in `main.go` unless a focused extraction materially improves maintainability.
- Use Playwright only in `captcha.go` for browser-based token collection; the production server must remain browser-free.
- Use Bubble Tea and Lip Gloss only for the token collector's terminal UI; do not add them to the server runtime path.
- Keep `image-gen/image-gen.js` dependency-free and use Node built-ins such as `https`, `fs`, `path`, and `readline`; do not add npm packages unless explicitly required.
- Preserve both OpenAI and Anthropic response contracts, including SSE framing, auth headers, and error envelope formats.
- Read configuration and secrets from environment variables; never add new credentials or tokens directly to source code.
- Keep Docker production builds static (`CGO_ENABLED=0`), run as a non-root user, expose `$PORT`, and store mutable SQLite data in `/data`.
- Validate external request input at HTTP boundaries and never log bearer tokens, API keys, session cookies, or full authorization headers.
