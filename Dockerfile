# 阶段 1：从 tailscale 源码静态编译 derper
FROM golang:alpine AS builder
RUN apk add --no-cache git ca-certificates
ENV GOPROXY=https://proxy.golang.org,https://goproxy.cn,direct
ARG TARGETOS
ARG TARGETARCH
ARG VERSION
# 先用 go install 拉取模块并缓存，再基于缓存源码交叉编译
RUN mkdir -p /out && \
    go install tailscale.com/cmd/derper@${VERSION} && \
    derper_dir=$(find /go/pkg/mod/tailscale.com@*/cmd/derper -type d -print -quit) && \
    echo "Building from ${derper_dir} for ${TARGETOS}/${TARGETARCH}" && \
    cd ${derper_dir} && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -v -ldflags "-s -w" -o /out/derper .

# 阶段 2：最小运行时镜像
FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /out/derper .
