#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://sh.vps.dance/autoNexttrace.sh)
# bash <(curl -Lso- https://cdn.jsdelivr.net/gh/VPSDance/vkit@main/autoNexttrace.sh)

footer() {
  BLUE="\033[34m"; NC='\033[0m'
  printf "%b\n" " Supported by: ${BLUE}https://vps.dance${NC}"
  printf "%-37s\n" "-" | sed 's/\s/-/g'
}

# install nexttrace
if [ ! -f "/usr/bin/nexttrace" ]; then
  bash <(curl -Lso- https://sh.vps.dance/tools.sh) nexttrace -p
fi

next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear
next

ipv4="$(curl -m 5 -fsL4 http://ipv4.ip.sb)"
ipv6="$(curl -m 5 -fsL6 http://ipv6.ip.sb)"

# https://ispip.clang.cn/
# gd.189.cn, gd.10086.cn
ip_list=(14.215.116.1 202.96.209.133 117.28.254.129 221.5.88.88 119.6.6.6 120.204.197.126 183.221.253.100 211.139.145.129 202.112.14.151)
ip_addr=(广东电信 上海电信 厦门电信 广东联通 成都联通 上海移动 成都移动 广东移动 成都教育网)

if [ -z "$ipv4" ]; then
ip_list=(240e:1f:1::1 240e:5a::6666 240e:56:4000::218 2408:8663::2 2408:8000:aaaa:: 2409:8062:2000:1::1 2409:8028:2000::1111 2001:da8:6005:b::3)
ip_addr=(广东电信 江苏电信 成都电信 重庆联通 江苏联通 四川移动 浙江移动 成都教育网)
fi

# ip_len=${#ip_list[@]}

cancel() { exit 1; }
trap cancel SIGINT SIGTERM

for i in "${!ip_addr[@]}"; do
	echo ${ip_addr[$i]}
	nexttrace -T -q 1 ${ip_list[$i]} \
    | sed '/^.*Geo Data.*$/d'
	next
done
footer
