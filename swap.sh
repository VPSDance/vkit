#!/usr/bin/env bash
# bash <(curl -Lso- https://sh.vps.dance/swap.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE="\033[34m"; PURPLE="\033[35m"; BOLD="\033[1m"; NC='\033[0m';
success() { printf "${GREEN}%s${NC} ${@:2}\n" "$1"; }
info() { printf "${BLUE}%s${NC} ${@:2}\n" "$1"; }
danger() { printf "${RED}[x] %s${NC}\n" "$@"; }
warn() { printf "${YELLOW}%s${NC}\n" "$@"; }
# Keep stdio on tty for interactive reads when piped
read_tty() { read -p "$1" "$2" </dev/tty; }

swap_file="/vd_swap"
line_mark="# vd_swap"

CURR_USER="$(whoami)"
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER swap_file line_mark RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC 2>/dev/null)"
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

swap_info() {
  info "当前swap:"
  # free -h
  swapon --show
}

create_swap() {
  local swap_size="$1"
  info "swap大小为: ${swap_size}G, 正在创建swap..."
  delete_swap
  # dd if=/dev/zero of=$swap_file bs=1G count=$swap_size
  fallocate -l "${swap_size}G" $swap_file
  chmod 600 $swap_file; mkswap $swap_file; swapon $swap_file;
  echo "$swap_file swap swap defaults 0 0" >> /etc/fstab
  echo "vm.swappiness=10 $line_mark" >> /etc/sysctl.conf
  sysctl -p > /dev/null;
  info "swap创建成功!"
  swap_info
}

delete_swap() {
  if [[ ! -f "$swap_file" ]]; then return; fi
  swapoff $swap_file # 已经关闭, 会报错
  rm -f $swap_file
  sed -i "\#${swap_file}#d" /etc/fstab
  sed -i "/${line_mark}/d" /etc/sysctl.conf
}

restore_swap() {
  delete_swap
  sysctl -p > /dev/null;
  info "swap设置还原成功!"
  swap_info
}

menu() {
  info "swap分区 (虚拟内存):"
  local AR=(
    [0]="查看swap"
    [1]="添加swap"
    [2]="还原swap"
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read_tty "输入数字以选择: " num
    [[ -n "${AR[num]}" ]] || {
      danger "invalid"
      continue
    }
    break
  done
  main="${AR[num]}"
  if [[ "$num" == "0" ]]; then
    clear
    with_sudo swap_info
    printf "%-37s\n" "-" | sed 's/\s/-/g'
    menu
  elif [[ "$num" == "1" ]]; then
    clear
    local swap_size
    while :; do
      read_tty "请输入swap大小 (单位为G): " swap_size
      [[ $swap_size =~ ^[0-9]*\.?[0-9]+$ ]] || {
        echo "invalid number"
        continue
      }
      break
    done
    swap_size=${swap_size:-1}
    with_sudo create_swap "$swap_size"
  elif [[ "$num" == "2" ]]; then
    with_sudo restore_swap
  fi
}

menu
