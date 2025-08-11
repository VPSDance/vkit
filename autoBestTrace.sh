#!/usr/bin/env bash

# # bash <(curl -Lso- https://sh.vps.dance/autoBestTrace.sh)
# https://github.com/nyjx/autoBestTrace

bin="/usr/bin/besttrace"
BASE_URL="https://sh.vps.dance/raw/VPSDance/vkit/main/files/besttrace/"

# debug flag: default silent; enable via DEBUG=1
DEBUG=${DEBUG:-0}

# If /usr/bin is not writable (e.g., non-root or macOS), fallback to user bin
if [ ! -w "$(dirname "$bin")" ]; then
  bin="$HOME/.local/bin/besttrace"
  mkdir -p "$(dirname "$bin")"
  case ":$PATH:" in
    *":$(dirname "$bin"):"*) ;;
    *) export PATH="$(dirname "$bin"):$PATH";;
  esac
fi

OSNAME=$(uname -s)
OSARCH=$(uname -m)
case "$OSNAME" in
  Darwin)
    case "$OSARCH" in
      arm64)  FILE="besttracemacarm" ;;
      x86_64) FILE="besttracemac" ;;
      *) echo "unsupported macOS arch: $OSARCH"; exit 1 ;;
    esac
  ;;
  Linux)
    case "$OSARCH" in 
      x86_64|amd64) FILE="besttrace" ;;
      i*86)         FILE="besttrace32" ;;
      arm64|aarch64)FILE="besttracearm" ;;
      *) echo "unsupported Linux arch: $OSARCH"; exit 1 ;;
    esac
  ;;
  *)
    echo "unsupported OS: $OSNAME"; exit 1
  ;;
esac

# clean failed file
if [ -f "$bin" ] && ! "$bin" -V >/dev/null 2>&1; then rm -f "$bin"; fi

# version helpers
get_local_version() {
  "$bin" -V 2>/dev/null | sed -nE 's/.*version[[:space:]]+([0-9.]+).*/\1/p' | head -1
}

get_remote_version() {
  curl -fsSL "${BASE_URL}besttrace4linux.txt" | sed -nE 's/^([0-9]+(\.[0-9]+)+).*/\1/p' | head -1
}

version_lt() {
  local -a ver1 ver2
  local i len a b
  # Split by dots into arrays
  IFS='.' read -r -a ver1 <<< "$1"
  IFS='.' read -r -a ver2 <<< "$2"
  # Normalize length
  len=${#ver1[@]}; (( ${#ver2[@]} > len )) && len=${#ver2[@]}
  for ((i=0; i<len; i++)); do
    a=${ver1[i]:-0}
    b=${ver2[i]:-0}
    # Strip non-digits just in case
    a=${a//[^0-9]/}
    b=${b//[^0-9]/}
    ((10#$a < 10#$b)) && return 0
    ((10#$a > 10#$b)) && return 1
  done
  return 1
}

# install/update besttrace
need_download=false
reason=""
remote_v=$(get_remote_version || true)
if [ -x "$bin" ]; then
  local_v=$(get_local_version || true)
else
  local_v=""
fi

if [ ! -x "$bin" ]; then
  need_download=true; reason="not installed"
elif [ -n "$remote_v" ] && [ -n "$local_v" ] && version_lt "$local_v" "$remote_v"; then
  need_download=true; reason="update ${local_v} -> ${remote_v}"
elif [ -z "$local_v" ]; then
  need_download=true; reason="corrupted local"
fi

if $need_download; then
  wget -q -O "$bin" "${BASE_URL}${FILE}"
  chmod +x "$bin"
  [ "$OSNAME" = "Darwin" ] && xattr -d com.apple.quarantine "$bin" 2>/dev/null || true
  new_v=$(get_local_version || true)
fi


## start to use besttrace

next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}

# one-shot debug summary then exit (to avoid consuming tokens during development)
if [ "$DEBUG" = "1" ]; then
  echo "[autoBestTrace] OS=$OSNAME ARCH=$OSARCH FILE=$FILE"
  echo "[autoBestTrace] bin=$bin"
  echo "[autoBestTrace] local=${local_v:-none} remote=${remote_v:-unknown}"
  if $need_download; then
    echo "[autoBestTrace] action=download reason=$reason url=${BASE_URL}${FILE}"
    echo "[autoBestTrace] installed_version=${new_v:-unknown}"
  else
    final_v=$(get_local_version || true)
    echo "[autoBestTrace] action=skip reason=no_update"
    echo "[autoBestTrace] installed_version=${final_v:-${local_v:-unknown}}"
  fi
  exit 0
fi

# minimal token check and feedback
check_token() {
  local out lic
  out="$($bin -L 2>&1 | tr -d '\r' || true)"
  if echo "$out" | grep -qi "Token mis"; then
    echo "$(echo "$out" | head -1)"
    if [ -n "${BESTTRACE_TOKEN:-}" ]; then
      lic="${BESTTRACE_LIC_PATH:-$HOME/besttrace.lic}"
      printf '%s\n' "$BESTTRACE_TOKEN" > "$lic"
    else
      echo "Hint: echo 'YOUR_TOKEN' > ~/besttrace.lic"; exit 1
    fi
  elif echo "$out" | grep -q "^Token:"; then
    echo "$(echo "$out" | head -1)"
  fi
}

# token check before route tests
check_token

# START_RUN

clear
next

ipv4="$(curl -m 5 -fsL4 http://ipv4.ip.sb)"
ipv6="$(curl -m 5 -fsL6 http://ipv6.ip.sb)"

# gd.189.cn, gd.10086.cn
ip_list=(14.215.116.1 202.96.209.133 117.28.254.129 221.5.88.88 119.6.6.6 120.204.197.126 183.221.253.100 211.139.145.129 202.112.14.151)
ip_addr=(广东电信 上海电信 厦门电信 广东联通 成都联通 上海移动 成都移动 广东移动 成都教育网)

if [ -z "$ipv4" ]; then
  echo "ipv6 is not supported"
  exit 1
fi

# ip_len=${#ip_list[@]}

for i in "${!ip_addr[@]}"; do
  echo ${ip_addr[$i]}
  "$bin" -q1 -g cn -T ${ip_list[$i]}
  next
done
