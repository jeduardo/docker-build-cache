# syntax=docker/dockerfile:1.7

# Builder stage
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETARCH
ARG TARGETOS

WORKDIR /workspace

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

WORKDIR /src

RUN --mount=target=. \
  --mount=type=cache,id=reverse-cow-gobuildcache-${TARGETOS}-${TARGETARCH},target=/root/.cache/go-build \
  --mount=type=cache,id=reverse-cow-gomodcache-${TARGETOS}-${TARGETARCH},target=/go/pkg/mod \
  go build -trimpath -o /out/reverse-cow ./

# Packaging stage
FROM gcr.io/distroless/static-debian13:nonroot

WORKDIR /work
COPY --from=build /out/reverse-cow /reverse-cow

USER nonroot:nonroot
ENTRYPOINT ["/reverse-cow"]
