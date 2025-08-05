# vkit

Tools and Scripts for Linux VPS

<!--
# cdn: https://cdn.jsdelivr.net/gh/:user/:repo/, https://cdn.jsdelivr.net/gh/cloudend/scripts@main/tools.sh
# cdn: https://ghproxy.com/https://github.com/:user/:repo/, https://ghproxy.com/https://github.com/zhboner/realm/releases/download/v1.4/realm
-->

- vkit(include all scripts)

```sh
bash <(curl -Lso- https://sh.vps.dance/vkit.sh)
```

- add swap space

```sh
bash <(curl -Lso- https://sh.vps.dance/swap.sh)
```

- add SSH public key

```sh
bash <(curl -Lso- https://sh.vps.dance/ssh.sh) key
```

- change SSH port

```sh
bash <(curl -Lso- https://sh.vps.dance/ssh.sh) port
```

- prefer IPv4/IPv6; enable/disable IPv6;

```sh
bash <(curl -Lso- https://sh.vps.dance/ip46.sh)
```

- install ddns-go

```sh
bash <(curl -Lso- https://sh.vps.dance/tools.sh) ddns-go -p
```

- install gost

```sh
bash <(curl -Lso- https://sh.vps.dance/tools.sh) gost -p
```

- install realm

```sh
bash <(curl -Lso- https://sh.vps.dance/tools.sh) realm -p
```

- install miniserve

```sh
bash <(curl -Lso- https://sh.vps.dance/tools.sh) miniserve
```

- install snell

```sh
bash <(curl -Lso- https://sh.vps.dance/tools.sh) snell # v3
bash <(curl -Lso- https://sh.vps.dance/tools.sh) snell5 # v5
```

- autoBestTrace

```sh
bash <(curl -Lso- https://sh.vps.dance/autoBestTrace.sh)
```

- debian sources

```sh
# Switch to Aliyun mirror (recommended for users in China)
bash <(curl -Lso- https://sh.vps.dance/sources.sh) aliyun
# Switch to Debian 12 (bookworm) official sources
bash <(curl -Lso- https://sh.vps.dance/sources.sh) debian12
# Switch to Debian 11 (bullseye) official sources
bash <(curl -Lso- https://sh.vps.dance/sources.sh) debian11
```

- paste text and share

```sh
bash <(curl -Lso- https://sh.vps.dance/paste.sh)
```

## Acknowledgements

Thanks to the following projects:

- [Github](https://github.com)
- [Cloudflare Workers](https://workers.cloudflare.com)
- [ghproxy](https://github.com/hunshcn/gh-proxy)
- [jsdelivr](https://github.com/jsdelivr)
- [ip.sb](https://ip.sb)
- [ubuntu Pastebin](https://pastebin.ubuntu.com)
- [speedtest cli](https://www.speedtest.net/apps/cli)
- [bench.sh, bbr.sh](https://github.com/teddysun/across)
- [i-abc/Speedtest](https://github.com/i-abc/Speedtest)
- [HyperSpeed](https://github.com/veoco/bim-core)
- [YABS](https://github.com/masonr/yet-another-bench-script)
- [xykt/IPQuality](https://github.com/xykt/IPQuality)
- [xykt/NetQuality](https://github.com/xykt/NetQuality)
- [fscarmen/warp](https://gitlab.com/fscarmen/warp)
- [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck)
- [TikTokCheck](https://github.com/lmc999/TikTokCheck)
- [OpenAI-Checker](https://github.com/missuo/OpenAI-Checker)
- [nekoneko shs](https://github.com/nkeonkeo/shs)
- [ecs](https://github.com/spiritLHLS/ecs)
- [ddns-go](https://github.com/jeessy2/ddns-go)
- [realm](https://github.com/zhboner/realm)
- [gost](https://github.com/ginuerzh/gost)
- [NextTrace](https://github.com/nxtrace/Ntrace-core)
- [nali](https://github.com/zu1k/nali)
- [WorstTrace](https://wtrace.app)
- [BestTrace](https://www.ipip.net/product/client.html)
- [SuperBench](https://github.com/oooldking/script)
- [hysteria2](https://github.com/apernet/hysteria)
- [miniserve](https://github.com/svenstaro/miniserve)
  <!-- - [ss-rust](https://github.com/shadowsocks/shadowsocks-rust) -->
  <!-- - [Project X](https://github.com/XTLS/Xray-core) -->
  <!-- - snell -->

<!--
update cache:
- https://purge.jsdelivr.net/gh/VPSDance/scripts@main/vkit.sh
- https://purge.jsdelivr.net/gh/VPSDance/scripts@main/tools.sh
-->
