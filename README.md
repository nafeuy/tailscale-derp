# Tailscale Derper 镜像

每日自动检查 [Tailscale](https://github.com/tailscale/tailscale) 官方最新版本，静态编译 `derper` 并构建多架构 Docker 镜像。

## 镜像地址

| 仓库 | 地址 |
|---|---|
| GitHub Container Registry | `ghcr.io/nafeuy/tailscale-derp` |
| Docker Hub | `nafeuy/tailscale-derp` |

支持 `linux/amd64` 和 `linux/arm64` 架构。

## 使用方式

镜像**没有预定义命令**，用户运行时自由指定参数：

```bash
# 查看帮助
docker run --rm nafeuy/tailscale-derp:latest ./derper --help
```

## 构建原理

- 每天 UTC 凌晨 4 点检查 Tailscale 官方最新 release tag
- 有新版本时，使用 `CGO_ENABLED=0` 静态编译 derper 二进制
- 打包到 Alpine 基础镜像，不预设 ENTRYPOINT 或 CMD

## 版本状态

- 最新同步版本：`v0.0.0`
- 上次更新时间（UTC）：`—`
- 上次检查时间（UTC）：`—`
