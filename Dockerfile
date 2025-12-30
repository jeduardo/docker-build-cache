# syntax=docker/dockerfile:1.7

# Builder stage
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETARCH
ARG TARGETOS

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

WORKDIR /src

# 1) Copy only module files first (stable cache key)
COPY go.mod go.sum ./

# 2) Download deps (cached by go.mod/go.sum + cache mounts)
RUN --mount=type=cache,id=reverse-cow-gomodcache-${TARGETOS}-${TARGETARCH},target=/go/pkg/mod \
  --mount=type=cache,id=reverse-cow-gobuildcache-${TARGETOS}-${TARGETARCH},target=/root/.cache/go-build \
  go mod download

# 3) Copy the rest of the source
COPY . .

# 4) Build (reuses the same caches)
RUN --mount=type=cache,id=reverse-cow-gomodcache-${TARGETOS}-${TARGETARCH},target=/go/pkg/mod \
  --mount=type=cache,id=reverse-cow-gobuildcache-${TARGETOS}-${TARGETARCH},target=/root/.cache/go-build \
  go build -trimpath -o /out/reverse-cow ./

# Packaging stage
FROM gcr.io/distroless/static-debian13:nonroot

WORKDIR /work
COPY --from=build /out/reverse-cow /reverse-cow

USER nonroot:nonroot
ENTRYPOINT ["/reverse-cow"]
