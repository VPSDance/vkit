#!/usr/bin/env bash
# bash <(curl -Lso- https://sh.vps.dance/ip46.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE="\033[34m"; PURPLE="\033[35m"; BOLD="\033[1m"; NC='\033[0m';

success() { printf "${GREEN}%s${NC} ${@:2}\n" "$1"; }
info() { printf "${BLUE}%s${NC} ${@:2}\n" "$1"; }
danger() { printf "${RED}[x] %s${NC}\n" "$@"; }
warn() { printf "${YELLOW}%s${NC}\n" "$@"; }
# Keep stdio on tty for interactive reads when piped
read_tty() { read -p "$1" "$2" </dev/tty; }

SYSCTLCONF=/etc/sysctl.conf
GAICONF=/etc/gai.conf
MARK="# vpsDance"

CURR_USER="$(whoami)"
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER SYSCTLCONF GAICONF MARK RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC 2>/dev/null)"
    local declare_funcs="$(declare -f)"
    cmd="$declare_vars; $declare_funcs; $1 "'"${@:2}"'
  else
    cmd="$1 "'"${@:2}"'
  fi

  if [[ $EUID -ne 0 ]]; then
    sudo bash -c "$cmd" -- "$@" < /dev/tty
  else
    bash -c "$cmd" -- "$@"
  fi
}

reload_sysctl() { sysctl -q -p && sysctl -q --system; }
restore_success() { success '已还原为默认配置'; }
restart_network() {
  info "正在重启网络服务..."
  # NetworkManager
  if systemctl is-active --quiet NetworkManager; then systemctl restart NetworkManager
  # NetworkManager
  # elif command -v nmcli >/dev/null 2>&1; then nmcli networking off && nmcli networking on
  # CentOS/RedHat
  elif systemctl is-active --quiet network; then systemctl restart network
  # Debian/Ubuntu
  elif systemctl is-active --quiet networking; then systemctl restart networking
  else warn "无法重启网络服务, 请手动重启"
  fi
}

# = prefer IPv4/IPv6
restore_ip46() {
  if [[ -f $GAICONF ]]; then
    sed -i "/$MARK/d" $GAICONF
  fi
  if [[ "$1" = 'info' ]]; then restore_success;check_ip46; fi
}
prefer_ipv4() {
  restore_ip46
  echo "precedence ::ffff:0:0/96  100 $MARK" >>$GAICONF
  check_ip46
}
prefer_ipv6() {
  restore_ip46
  echo "label 2002::/16   2 $MARK" >>$GAICONF
  check_ip46
}
check_ip46() {
  success "检测访问网络优先级 (显示IPv4, 则为IPv4优先; 显示IPv6, 则为IPv6优先):"
  curl ip.sb:2095
  warn "PS: IPv6优先, 并不能保证所有请求都走IPv6, 某些客户端可能需要额外设定"
  echo "比如: xray/v2ray设定UseIPv6, ss设定ipv6_first, trojan设定prefer_ipv4, hy2设定 direct.mode"
}

# = enable/disable IPv6
restore_ipv6() {
  sed -i "/$MARK/d" $SYSCTLCONF
  if [[ "$1" = 'info' ]]; then reload_sysctl;restart_network;restore_success;check_ipv6; fi
}
enable_ipv6() {
  local interfaces=("all" "default")
  restore_ipv6
  for interface in "${interfaces[@]}"; do
    echo "net.ipv6.conf.${interface}.disable_ipv6=0 $MARK" >>$SYSCTLCONF
  done;
  reload_sysctl
  restart_network
  check_ipv6
}
disable_ipv6() {
  local interfaces=("all" "default")
  restore_ipv6
  for interface in "${interfaces[@]}"; do
    echo "net.ipv6.conf.${interface}.disable_ipv6=1 $MARK" >>$SYSCTLCONF
  done;
  reload_sysctl
  check_ipv6
}
check_ipv6() {
  success "检测IPv6 启用/禁用:"
  result=$(curl -6 -s ip.sb:2095)
  if [ -n "$result" ]; then
    echo "IPv6 is enabled. $result"
  else
    echo "IPv6 is disabled."
  fi
}

menu() {
  clear;
  info "请选择菜单: "
  local ACTS=(
    [1]='优先使用IPv4访问网络'
    [2]='优先使用IPv6访问网络'
    [3]='还原 网络优先(IPv4/IPv6) 为默认配置'
    [4]='启用 IPv6'
    [5]='禁用 IPv6'
    [6]='还原 IPv6(启用/禁用) 为默认配置'
  )
  for i in "${!ACTS[@]}"; do
    success "$i." "${ACTS[i]}"
  done
  while :; do
    read_tty "输入数字以选择: " num
    [[ -n "${ACTS[num]}" ]] || { danger "invalid number"; continue; }
    break
  done
  main
}
main() {
  if [[ "$num" == "1" ]]; then with_sudo prefer_ipv4
  elif [[ "$num" == "2" ]]; then with_sudo prefer_ipv6
  elif [[ "$num" == "3" ]]; then with_sudo restore_ip46 'info'
  elif [[ "$num" == "4" ]]; then with_sudo enable_ipv6
  elif [[ "$num" == "5" ]]; then with_sudo disable_ipv6
  elif [[ "$num" == "6" ]]; then with_sudo restore_ipv6 'info'
  else exit
  fi
}

menu
