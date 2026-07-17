# Tailscale Derper 镜像

每日自动检查 [Tailscale](https://github.com/tailscale/tailscale) 官方最新版本，静态编译 `derper` 并构建多架构 Docker 镜像。

## 版本状态

- 最新同步版本：`v1.98.8`
- 上次更新时间（UTC）：`2026-07-04 14:34 UTC`
- 上次检查时间（UTC）：`2026-07-17 06:22 UTC`

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

创建 `compose.yaml` ：

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
      - ./derp_certs:/root/derp_certs
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

```bash
root@flokulto:~# docker logs -f tailscale-derp
2026/07/04 16:36:15 no config path specified; using /var/lib/derper/derper.key
2026/07/04 16:36:15 STUN server listening on [::]:3478
2026/07/04 16:36:15 No mesh key configured
2026/07/04 16:36:15 derper: serving on :29518 with TLS
2026/07/04 16:36:15 Using self-signed certificate for IP address "x.x.x.x". Configure it in DERPMap using: (https://tailscale.com/s/custom-derp)
  {"Name":"custom","RegionID":900,"HostName":"x.x.x.x","CertName":"sha256-raw:c9b489fe37900c1dd5ab0696869cd50e8823617e9d812b0adc2591032267ae50"}
```

在 [Tailscale Access controls](https://login.tailscale.com/admin/acls/file) 添加自定义 DERP 时，加入 `"InsecureForTests": true` ，即可忽略证书校验。

又或者，可以根据 derper 的提示，把 `CertName` 字段加入配置文件。

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
						"DERPPort":         29518,
                        "CertName":         "sha256-raw:c9b489fe37900c1dd5ab0696869cd50e8823617e9d812b0adc2591032267ae50"
                        // 忽略证书校验
                        // "InsecureForTests": true,
                        // 启动 derper 时使用 -stun-port 参数可以自定义STUN端口
                        // "STUNPort":         3478
					}
				]
			}
		}
	},
```

## 构建原理

- 每天 UTC 凌晨 4 点检查 Tailscale 官方最新 release tag
- 有新版本时，使用 `CGO_ENABLED=0` 静态编译 derper 二进制
- 打包到 Alpine 基础镜像，不预设 ENTRYPOINT 或 CMD
