# 阶段 1：从 tailscale 源码静态编译 derper
FROM golang:alpine AS builder
RUN apk add --no-cache git ca-certificates
ARG TARGETOS
ARG TARGETARCH
ARG VERSION
RUN mkdir -p /out && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags "-s -w" -o /out/derper tailscale.com/cmd/derper@${VERSION}

# 阶段 2：最小运行时镜像
FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /out/derper .
