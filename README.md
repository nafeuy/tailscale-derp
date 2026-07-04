# Tailscale Derper 镜像

每日自动检查 [Tailscale](https://github.com/tailscale/tailscale) 官方最新版本，静态编译 `derper` 并构建多架构 Docker 镜像。

## 版本状态

- 最新同步版本：`v1.98.8`
- 上次更新时间（UTC）：`2026-07-04 14:34 UTC`
- 上次检查时间（UTC）：`2026-07-04 14:34 UTC`

## 镜像地址

| 仓库 | 地址 |
|---|---|
| GitHub Container Registry | `ghcr.io/nafeuy/tailscale-derp` |
| Docker Hub | `nafeuy/tailscale-derp` |

支持 `linux/amd64` 和 `linux/arm64` 架构。

## 使用方式

镜像**没有预定义命令**，运行时自由指定参数。

查看帮助：

```bash
docker run --rm nafeuy/tailscale-derp:latest ./derper --help
```

`docker run` 启动命令：

```bash
docker run -d \
  --name tailscale-derp \
  --restart unless-stopped \
  -p 29518:29518 \
  -p 3478:3478/udp \
  -v /var/run/tailscale:/var/run/tailscale:ro \
  nafeuy/tailscale-derp:latest \
  ./derper \
  -hostname example.com \
  -a :29518 \
  -certmode manual \
  -certdir /root/derp_certs \
  -verify-clients
```

`compose.yaml` 写法：

```yaml
services:
  tailscale-derp:
    image: nafeuy/tailscale-derp:latest
    container_name: tailscale-derp
    restart: unless-stopped
    ports:
      - "29518:29518"                              # HTTP(S)监听端口
      - "3478:3478/udp"                            # STUN端口
    volumes:
      - /var/run/tailscale:/var/run/tailscale:ro   # -verify-clients参数需要
    command:
      - ./derper
      - -hostname
      - example.com
      - -a
      - ":29518"
      - -certmode
      - manual
      - -certdir
      - /root/derp_certs
      - -verify-clients                            # 仅允许自己的客户端接入 DERP，需要宿主机已运行 Tailscale
```

使用 `docker compose up -d` 运行。

在 `-certmode` 为 `manual`，并且 `-hostname` 为 IP 地址时， derper 会自己生成自签名证书。

在 [Tailscale Access controls](https://login.tailscale.com/admin/acls/file) 添加自定义 DERP 时，加入 `InsecureForTests` ，即可忽略证书校验。

```json
"derpMap": {
		"OmitDefaultRegions": false,
		"Regions": {
			"900": {
				"RegionID":   900,
				"RegionCode": "北京1",
				"RegionName": "北京1",
				"Nodes": [
					{
						"Name":             "900",
						"RegionID":         900,
						"HostName":         "8.8.8.8",
						"IPv4":             "8.8.8.8",
						"InsecureForTests": true,    // 忽略证书校验
						"DERPPort":         29518,
                        // 启动 derper 时使用 -stun-port 参数可以自定义STUN端口
                        // "STUNPort":         3478
					}
				]
			}
		}
	}
```

## 构建原理

- 每天 UTC 凌晨 4 点检查 Tailscale 官方最新 release tag
- 有新版本时，使用 `CGO_ENABLED=0` 静态编译 derper 二进制
- 打包到 Alpine 基础镜像，不预设 ENTRYPOINT 或 CMD
