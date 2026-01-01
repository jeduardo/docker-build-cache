# Builder stage
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETARCH
ARG TARGETOS
ARG CACHE_SCOPE=default

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}
ENV GOMODCACHE=/go/pkg/mod
ENV GOCACHE=/root/.cache/go-build

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,id=go-mod-${CACHE_SCOPE},target=/go/pkg/mod,sharing=locked \
  --mount=type=cache,id=go-build-${CACHE_SCOPE},target=/root/.cache/go-build,sharing=locked \
  go mod download

COPY . .
RUN --mount=type=cache,id=go-mod-${CACHE_SCOPE},target=/go/pkg/mod,sharing=locked \
  --mount=type=cache,id=go-build-${CACHE_SCOPE},target=/root/.cache/go-build,sharing=locked \
  go build -trimpath -o /out/reverse-cow ./

# Packaging stage
FROM gcr.io/distroless/static-debian13:nonroot

# A conventional working directory for mounts
WORKDIR /work

COPY --from=build /out/reverse-cow /reverse-cow

USER nonroot:nonroot
ENTRYPOINT ["/reverse-cow"]
