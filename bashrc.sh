#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://sh.vps.dance/bashrc.sh)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE="\033[34m"; PURPLE="\033[35m"; BOLD="\033[1m"; NC='\033[0m';

success() { printf "${GREEN}%s${NC} ${@:2}\n" "$1"; }
info() { printf "${BLUE}%s${NC} ${@:2}\n" "$1"; }
danger() { printf "${RED}[x] %s${NC}\n" "$@"; }
warn() { printf "${YELLOW}%s${NC}\n" "$@"; }

CURR_USER="$(whoami)"
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER RED GREEN YELLOW BLUE PURPLE BOLD NC 2>/dev/null)"
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
# allusers=$( cat /etc/passwd | grep -vE "(/bin/false|/sbin/nologin|/bin/sync|guest-)" | cut -d: -f1 )
# allusers=$(awk -F':' '$2 ~ "\\$" {print $1}' /etc/shadow)

apply_bashrc() {
  for file in /root/.bashrc /home/*/.bashrc; do
    # echo $file;
    if [[ ! -f "$file" ]]; then continue; fi
    # insert lines
    printf "%s\n" "# => vps.dance" >>$file
    printf "%s\n" "$(curl -Lso- https://sh.vps.dance/raw/VPSDance/vkit/main/files/bashrc)" >>$file
    printf "%s\n" "# <= vps.dance" >>$file
  done
}

restore_bashrc() {
  for file in /root/.bashrc /home/*/.bashrc; do
    # echo $file;
    if [[ ! -f "$file" ]]; then continue; fi
    # delete lines between two patterns
    sed -i '/^# => vps.dance/,/^# <= vps.dance/d' $file
  done
}

reload_bashrc() {
  # source ~/.bashrc
  # fix: source bashrc not working
  exec bash
}

menu() {
  # clear
  info "shell 终端优化, 请选择: "
  local AR=(
    [1]='应用'
    [2]='还原'
  )
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "输入数字以选择: " num
    [[ -n "${AR[num]}" ]] || {
      danger "invalid number"
      continue
    }
    break
  done
  if [[ "$num" == "1" ]]; then
    with_sudo restore_bashrc
    with_sudo apply_bashrc
    reload_bashrc
  elif [[ "$num" == "2" ]]; then
    with_sudo restore_bashrc
    reload_bashrc
  fi
}

menu
