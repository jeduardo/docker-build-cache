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
  --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg/mod \
  go build -trimpath -o /out/reverse-cow ./

# Packaging stage
FROM gcr.io/distroless/static-debian13:nonroot

# A conventional working directory for mounts
WORKDIR /work

COPY --from=build /out/reverse-cow /reverse-cow

USER nonroot:nonroot
ENTRYPOINT ["/reverse-cow"]

