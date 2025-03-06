
#!/usr/bin/env bash
# curl https://sh.vps.dance/tuning.sh | bash

# Reference:
# https://www.cnblogs.com/tolimit/p/5065761.html
# https://cloud.google.com/architecture/tcp-optimization-for-network-performance-in-gcp-and-hybrid?hl=zh-cn
# [LFN网络下TCP性能的优化](https://github.com/acacia233/Project-Smalltrick/wiki/)
# https://github.com/ylx2016/Linux-NetSpeed/blob/master/tcp.sh
# bash <(curl -Lso- http://sh.nekoneko.cloud/tools.sh)

pam_limits="/etc/pam.d/common-session"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.conf"
allusers=$( cat /etc/passwd | grep -vE "(/bin/false|/sbin/nologin|/bin/sync|guest-)" | cut -d: -f1 )
# allusers=$(awk -F':' '$2 ~ "\\$" {print $1}' /etc/shadow)

CURR_USER="$(whoami)"
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER pam_limits limits_conf sysctl_conf allusers RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC 2>/dev/null)"
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

reload_sysctl() { sysctl -q -p && sysctl --system; }
check_sysctl() {
  if [ ! -f "$sysctl_conf" ]; then touch "$sysctl_conf"; fi
}

ulimited_tuning() {
  check_sysctl
  # enable 'session required pam_limits.so'
  if ! grep -q 'pam_limits.so' "$pam_limits"; then
    sed -i '/required.* pam_limits.so/d' "$pam_limits"
    echo 'session required pam_limits.so' >> "$pam_limits"
  fi
  # max open files
  if [ -w /proc/sys/fs/file-max ]; then
    sed -i '/fs.file-max/d' "$sysctl_conf"
    echo 'fs.file-max=102400' >> "$sysctl_conf"
  fi
  # watch limit
  if [ -w /proc/sys/fs/inotify/max_user_instances ]; then
    sed -i '/inotify.max_user_instances/d' "$sysctl_conf"
    echo 'fs.inotify.max_user_instances=999' >> "$sysctl_conf"
    sed -i '/inotify.max_user_watches/d' "$sysctl_conf"
    echo 'fs.inotify.max_user_watches=81920' >> "$sysctl_conf"
  fi
  # max user processes
  for usr in $allusers '\*'; do
    usr="${usr/\\/}"
    sed -i "/${usr}.*\(nproc\|nofile\|memlock\)/d" "$limits_conf"
    echo "${usr} soft    nproc    65536" >> "$limits_conf"
    echo "${usr} hard    nproc    65536" >> "$limits_conf"
    echo "${usr} soft    nofile   65535" >> "$limits_conf"
    echo "${usr} hard    nofile   65535" >> "$limits_conf"
    echo "${usr} soft    memlock  unlimited" >> "$limits_conf"
    echo "${usr} hard    memlock  unlimited" >> "$limits_conf"
  done
  if ! grep -q "ulimit" /etc/profile; then
    sed -i '/ulimit -SHn/d' /etc/profile
    echo "ulimit -SHn 65535" >> /etc/profile
  fi
  ulimit -SHn 65535 && ulimit -c unlimited
  # reload_sysctl
}

# sysctl -a | grep mem
tcp_tuning() {
  check_sysctl

  # === 连接队列优化 ===
  # TCP 连接等待 accept 的队列最大长度
  sed -i '/net.core.somaxconn/d' "$sysctl_conf"
  echo 'net.core.somaxconn=131072' >> "$sysctl_conf"
  # 网卡接收队列的最大长度
  if [ -w /proc/sys/net/core/netdev_max_backlog ]; then
    sed -i '/net.core.netdev_max_backlog/d' "$sysctl_conf"
    echo 'net.core.netdev_max_backlog=32768' >> "$sysctl_conf"
  fi
  # TCP 半连接(SYN 队列)的最大长度
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_max_syn_backlog=131072' >> "$sysctl_conf"

  # === 连接状态管理 ===
  # 保持 TIME_WAIT 套接字的最大数量
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_max_tw_buckets=1440000' >> "$sysctl_conf"
  # TCP FIN 等待超时时间(默认60秒)
  sed -i '/net.ipv4.tcp_fin_timeout/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_fin_timeout=20' >> "$sysctl_conf"

  # === 传输与性能优化 ===
  # TCP 窗口缩放支持
  sed -i '/net.ipv4.tcp_window_scaling/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_window_scaling=1' >> "$sysctl_conf"
  # TCP 接收缓冲区自动调整
  sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_moderate_rcvbuf=1' >> "$sysctl_conf"
  # TCP 缓冲区大小(接收和发送)
  # est_bandwidth_mbps=900; est_rtt_ms=75  # 预估网络BDP # 带宽 Mbps, 平均RTT延迟 ms
  # est_bdp_bytes=$((est_bandwidth_mbps * 1000000 / 8 * est_rtt_ms / 1000))
  # BDP=$((est_bdp_bytes * 2))  # 2倍BD
  # echo "基于BDP设置缓冲区: $((BDP / 1024 / 1024))MB, BDP: $BDP"
  BDP='16777216' # 16777216(16M) min:4194304(4M) max: 67108864(64M)
  if [ -w /proc/sys/net/core/rmem_max ]; then
    sed -i '/net.ipv4.tcp_rmem/d' "$sysctl_conf"
    sed -i '/net.ipv4.tcp_wmem/d' "$sysctl_conf"
    echo "net.ipv4.tcp_rmem=8192 262144 $BDP" >> "$sysctl_conf" # 最小 默认 最大
    echo "net.ipv4.tcp_wmem=4096 16384 $BDP" >> "$sysctl_conf"  # 最小 默认 最大
    
    sed -i '/net.core.rmem_max/d' "$sysctl_conf"
    sed -i '/net.core.wmem_max/d' "$sysctl_conf"
    echo "net.core.rmem_max=$BDP" >> "$sysctl_conf"  # 接收缓冲区最大值
    echo "net.core.wmem_max=$BDP" >> "$sysctl_conf"  # 发送缓冲区最大值
    
    sed -i '/net.core.rmem_default/d' "$sysctl_conf"
    echo "net.core.rmem_default=262144" >> "$sysctl_conf"  # 接收缓冲区默认值
    
    sed -i '/net.core.wmem_default/d' "$sysctl_conf"
    echo "net.core.wmem_default=16384" >> "$sysctl_conf"   # 发送缓冲区默认值
  fi
  # TCP Fast Open(加速连接建立)
  sed -i '/net.ipv4.tcp_fastopen/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_fastopen=3' >> "$sysctl_conf" # 3 客户端和服务器端
  # TCP 选择性确认(SACK)
  sed -i '/net.ipv4.tcp_sack/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_sack=1' >> "$sysctl_conf"
  # TCP 慢启动优化(关闭空闲后重启慢启动)
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_slow_start_after_idle=0' >> "$sysctl_conf"


  # === 端口与重传优化 ===
  # 本地端口范围(用于随机分配)
  sed -i '/net.ipv4.ip_local_port_range/d' "$sysctl_conf"
  echo 'net.ipv4.ip_local_port_range=10240 65000' >> "$sysctl_conf"
  # TCP 失败重传次数
  sed -i '/net.ipv4.tcp_retries2/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_retries2=5' >> "$sysctl_conf" # 默认 8->5
  # 发送 SYN 的重试次数(建立连接)
  sed -i '/net.ipv4.tcp_syn_retries/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_syn_retries=3' >> "$sysctl_conf"
  # 发送 SYN+ACK 的重试次数(接受连接)
  sed -i '/net.ipv4.tcp_synack_retries/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_synack_retries=3' >> "$sysctl_conf"
  
  # === 安全优化 ===
  # SYN 洪水攻击保护
  sed -i '/net.ipv4.tcp_syncookies/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_syncookies=1' >> "$sysctl_conf"
  # 防止 TIME_WAIT 刺杀(RFC 1337)
  sed -i '/net.ipv4.tcp_rfc1337/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_rfc1337=1' >> "$sysctl_conf"

  # === TCP 保活设置 ===
  # 保活探测开始前的空闲时间(默认7200秒)
  sed -i '/net.ipv4.tcp_keepalive_time/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_keepalive_time=60' >> "$sysctl_conf"
  # 保活探测次数(默认9次)
  sed -i '/net.ipv4.tcp_keepalive_probes/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_keepalive_probes=6' >> "$sysctl_conf"
  # 保活探测间隔(默认75秒)
  sed -i '/net.ipv4.tcp_keepalive_intvl/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_keepalive_intvl=10' >> "$sysctl_conf"
}
with_sudo ulimited_tuning
with_sudo tcp_tuning
with_sudo reload_sysctl
