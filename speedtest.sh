#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://sh.vps.dance/speedtest.sh)

SH_PORT="${SH_PORT:-}"; SH="https://sh.vps.dance${SH_PORT:+:${SH_PORT}}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[34m'; CYAN='\033[0;36m'; PURPLE='\033[35m'; BOLD='\033[1m'; NC='\033[0m';
success() { printf "${GREEN}%b${NC} ${@:2}\n" "$1"; }
info() { printf "${CYAN}%b${NC} ${@:2}\n" "$1"; }
danger() { printf "\n${RED}[x] %b${NC}\n" "$@"; }
warn() { printf "${YELLOW}%b${NC}\n" "$@"; }

# Keep stdio on tty for interactive reads when piped
read_tty() { read -p "$1" "$2" </dev/tty; }

OS=$(uname -s) # Linux, FreeBSD, Darwin, MINGW64_NT-10.0-19045
ARCH=$(uname -m) # x86_64, arm64/aarch64, i386
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
CURR_USER="$(whoami)"
ipv4="$(curl -m 5 -fsL4 http://ipv4.ip.sb:2095)"
loc=$(curl -m5 -sL "https://www.qualcomm.cn:2096/cdn-cgi/trace" | awk -F'=' '/loc/{ print $2 }') # CN,HK,JP,DE,US
prefix=$( [ -z "$ipv4" ] && echo "$SH" || echo "https://ghfast.top" )
debug=0;

install_requirements() {
  command -v curl &>/dev/null || {
    echo -e "install curl"
    case "${DISTRO}" in
      Debian*|Ubuntu*)
        with_sudo apt install -y curl;;
      CentOS*|RedHat*)
        with_sudo yum install -y curl;;
    esac
  }
  # command -v column &>/dev/null || {
  #   echo -e "install column"
  #   case "${DISTRO}" in
  #     Debian*|Ubuntu*)
  #       with_sudo apt install -y bsdmainutils;;
  #     CentOS*|RedHat*)
  #       with_sudo yum install -y util-linux;;
  #   esac
  # }
}
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo -e "${RED}Error: sudo command not found${NC}" >&2
    return 1
  fi
  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    # if function, need to pass all variables and function definitions
    local declare_vars="$(declare -p RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC success info danger warn CURR_USER OS ARCH DISTRO ipv4 loc prefix 2>/dev/null)"
    local declare_funcs="$(declare -f)"
    cmd="$declare_vars; $declare_funcs; $1 "'"${@:2}"'
  else
    # if normal command
    cmd="$1 "'"${@:2}"'
  fi

  if [[ $EUID -ne 0 ]]; then
    sudo bash -c "$cmd" -- "$@" < /dev/tty
  else
    bash -c "$cmd" -- "$@"
  fi
}
# get latest version
# $1: GitHub repo path
get_latest_version() {
  local repo_path="$1"
  curl -sI "${prefix}/github.com/${repo_path}/releases/latest" | grep -i "location:" | sed -n 's/.*tag\/\(v[0-9.]\+\).*/\1/p'
}
# download GitHub release file
# $1: GitHub repo path
# $2: filename
# $3: save path
# $4: version(optional, default use latest version)
download_file() {
  local repo_path="$1"
  local filename="$2"
  local save_path="$3"
  local version="${4:-$(get_latest_version "$repo_path")}"
  local download_url="${prefix}/github.com/${repo_path}/releases/download/${version}/${filename}"
  # https://github.com/veoco/bim-core/releases/latest/download/bimc.exe

  info "download ${filename}..."
  local target_dir=$(dirname "$save_path")
  with_sudo mkdir -p $target_dir
  if with_sudo curl -L "$download_url" -o "$save_path"; then
    with_sudo chmod +x $save_path
    success "download success"
    return 0
  else
    danger "download ${download_url} failed"
    exit 1
    return 1
  fi
}
check_installed(){
  local bin_path="$1"
  if [[ -x "$bin_path" ]]; then
    return 0
  else
    return 1
  fi
}
bin_path(){
  local name="$1"
  case "${OS}" in
    MINGW*|MSYS*|CYGWIN*)
      echo "/usr/bin/${name}.exe"
      ;;
    *)
      echo "/usr/bin/${name}"
      ;;
  esac
}
install_bimc(){
  # info "install bimc"
  local bin_path=$(bin_path "bimc")
  if check_installed "$bin_path"; then
    return 0
  fi
  local repo="veoco/bim-core"
  local latest_version=$(get_latest_version "$repo")
  local filename
  case "${OS}" in
    Linux*)
      case "${ARCH}" in
        x86_64*)
          filename="bimc-x86_64-unknown-linux-musl"
          ;;
        aarch64*|arm64*)
          filename="bimc-aarch64-unknown-linux-musl"
          ;;
      esac
      ;;
    Darwin*)
      filename="bimc-macos"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      filename="bimc.exe"
      ;;
  esac
  if [ -z "${filename}" ]; then
    danger "not support architecture: ${ARCH}"
    exit 1
  fi
  if ! download_file "$repo" "${filename}" "${bin_path}" "${latest_version}"; then
    exit 1
  fi
}

print_line() { local length=${1:-50}; printf "%-${length}s\n" "-" | sed 's/\s/-/g'; }
print_header() {
  clear
  print_line
  printf "%s\n" "[vkit] 测速脚本 (基于 veoco/bim-core)"
  printf "%b\n" "${GREEN}VPS/IPLC测评:${NC} ${YELLOW}https://vps.dance/${NC}"
  printf "%b\n" "${GREEN}Telegram频道:${NC} ${YELLOW}https://t.me/vpsdance${NC}"
  print_line
}

MENU_TITLE=""
read_choice() {
  local -n menu=$1
  show_menu $1 "$2" >&2
  local choice
  while :; do
    #  [0-${#menu[@]}]
    read_tty "请输入选项: " choice
    [[ $choice -ge 0 && $choice -le ${#menu[@]} ]] || { continue; }
    break
  done
  printf "%s\x1f%s" "$choice" "${menu[$choice]}"
}
show_menu() {
  print_header
  local -n menu=$1
  [ -n "$MENU_TITLE" ] && {
    echo -e "${CYAN}${MENU_TITLE}${NC}"
  }
  for i in "${!menu[@]}"; do
    [[ "$i" == "0" ]] && continue
    success "$i." "${menu[i]}"
  done
  [ -n "${menu[0]}" ] && echo -e "${GREEN}0.${NC} ${menu[0]}"
}
main_menu() {
  local MAIN_MENU=(
    [1]="大陆三网+教育网 IPv4 测速"
    # [2]="大陆三网+教育网 IPv6 测速"
    [3]="全球 IPv4 测速"
    [4]="全球 IPv6 测速"
    # [0]="退出"
  )
  local result=$(read_choice MAIN_MENU "主菜单")
  IFS=$'\x1f' read -r choice text <<< "$result"
  MENU_TITLE="$text"
  case $choice in
    1) cn_menu '4';;
    2) cn_menu '6';;
    3) global_menu '4';;
    4) global_menu '6';;
    0) exit 0 ;;
  esac
}
cn_menu() {
  local type="$1"
  local CN_MENU=(
    [1]="全部节点"
    [2]="电信节点"
    [3]="联通节点"
    [4]="移动节点"
    [5]="教育网节点"
    [0]="返回上一级"
  )
  local result=$(read_choice CN_MENU)
  IFS=$'\x1f' read -r choice text <<< "$result"
  MENU_TITLE="$text"
  local area="cn"
  case $choice in
    1) speed_test $type $area all ;;
    2) speed_test $type $area ct ;;
    3) speed_test $type $area cu ;;
    4) speed_test $type $area cm ;;
    5) speed_test $type $area edu ;;
    0) main_menu ;;
  esac
}
global_menu() {
  local type="$1"
  local GLOBAL_MENU=(
    [1]="全部节点"
    [2]="亚洲节点"
    [4]="美洲节点"
    [5]="欧洲节点"
    # [10]="CDN节点"
    [0]="返回上一级"
  )
  local result=$(read_choice GLOBAL_MENU)
  IFS=$'\x1f' read -r choice text <<< "$result"
  MENU_TITLE="$text"
  local area="global"
  case $choice in
    1) speed_test $type $area all ;;
    3) speed_test $type $area asia ;;
    4) speed_test $type $area america ;;
    5) speed_test $type $area europe ;;
    # 10) speed_test $type $area cdn ;;
    0) main_menu ;;
  esac
}

# nodes: name|area|cate|v4|v6|download_url|upload_url
# https://www.speedtest.net/api/js/servers?search=FDC
# china
# 电信,China Telecom,ChinaTelecom
# 移动,China Mobile,ChinaMobile
# 联通,China Unicom,ChinaUnicom
NODES=(
  # cn
  # "电信 四川成都,cn,ct,1,0,http://speedtest1.sc.189.cn:8080"
  "电信 上海 5G,cn,ct,1,0,http://speedtest1.online.sh.cn:8080/speedtest"
  "电信 江苏苏州 5G,cn,ct,1,0,http://4gsuzhou1.speedtest.jsinfo.net:8080/speedtest"
  "电信 江苏镇江 5G,cn,ct,1,0,http://5gzhenjiang.speedtest.jsinfo.net:8080/speedtest"
  "电信 江苏南京 5G,cn,ct,1,0,http://5gnanjing.speedtest.jsinfo.net:8080/speedtest"

  "联通 上海 5G,cn,cu,1,0,http://5g.shunicomtest.com:8080/speedtest"
  "联通 四川成都,cn,cu,1,0,http://cuscspeed.169ol.com:8080/speedtest"

  "移动 福建福州,cn,cm,1,1,http://csfw.fj.chinamobile.com:8080/speedtest" # 4/6
  "移动 浙江杭州 5G,cn,cm,1,0,http://speedtest.139play.com:8080/speedtest"
  "移动 北京,cn,cm,1,0,http://speedtest.bmcc.com.cn:8080/speedtest"

  "教育网 北京 清华大学,cn,edu,1,1,http://iptv.tsinghua.edu.cn/st/garbage.php,http://iptv.tsinghua.edu.cn/st/empty.php" # 4/6
  "教育网 上海 上海交通大学,cn,edu,1,1,http:///wsus.sjtu.edu.cn/speedtest/backend/garbage.php,http://wsus.sjtu.edu.cn/speedtest/backend/empty.php" # 4/6
  "教育网 合肥 中国科技大学,cn,edu,1,0,http://test.ustc.edu.cn/backend/garbage.php,http://test.ustc.edu.cn/backend/empty.php"
  "教育网 合肥 中国科技大学,cn,edu,0,1,https://test6.ustc.edu.cn/backend/garbage.php,https://test6.ustc.edu.cn/backend/empty.php"
  "教育网 沈阳 东北大学,cn,edu,1,0,http://speed.neu.edu.cn/fastgarbage.php,http://speed.neu.edu.cn/empty.php"
  "教育网 沈阳 东北大学,cn,edu,0,1,http://speed.neu6.edu.cn/fastgarbage.php,http://speed.neu6.edu.cn/empty.php"
  # "教育网 南京 南京大学,cn,edu,1,0,http://test.nju.edu.cn/backend/garbage.php,http://test.nju.edu.cn/backend/empty.php"
  # "教育网 南京 南京大学,cn,edu,0,1,http://test6.nju.edu.cn/backend/garbage.php,http://test6.nju.edu.cn/backend/empty.php"

  # global
  "香港 I3D,hk,asia,1,1,http://hk.ap.speedtest.i3d.net:8080/speedtest" # 4/6
  "香港 HGC環電,hk,asia,1,0,http://ookla-speedtest-central.hgconair.hgc.com.hk:8080/speedtest"
  "香港 HKT(Netvigator),hk,asia,1,0,http://hkspeedtest.netvigator.com:8080/speedtest"
  "香港 CMHK Mobile,hk,asia,1,0,https://speedtest.hk.chinamobile.com:8080/speedtest"
  # http://speedtest.hk210.hkg.cn.ctcsci.com:8080/speedtest
  "香港 CTCSCI,hk,asia,1,0,http://speedtest.hk210.hkg.cn.ctcsci.com:8080/speedtest"
  "澳门 China Telecom,mo,asia,1,1,http://speedtest1.chinatelecom.com.mo:8080/speedtest" # 4/6
  "澳门 MTel,mo,asia,1,1,http://speedtest2.mtel.mo:8080/speedtest" # 4/6
  "台湾 台北 Sky Digital,tw,asia,1,1,http://speedtest.imcloud.tw:8080/speedtest" # 4/6
  "台湾 台北 HiNet(Chunghwa Mobile),tw,asia,1,0,http://tp1.chtm.hinet.net:8080/speedtest"
  # "台湾 彰化 HiNet(Chunghwa Mobile),tw,asia,1,0,https://ch1.chtm.hinet.net:8080/speedtest"
  "台湾 桃园 HiNet(Chunghwa Mobile),tw,asia,1,0,http://ty1.chtm.hinet.net:8080"
  "台湾 彰化 FarEasTone,tw,asia,1,1,http://fetyl1.seed.net.tw:8080/speedtest" # 4/6
  "台湾 南投 FarEasTone,tw,asia,1,1,http://fetnt1.seed.net.tw:8080/speedtest" # 4/6
  "台湾 新台北 TFN,tw,asia,1,0,http://sb-speedtest-1.twmbroadband.net:8080/speedtest"
  "台湾 台北 RFCHOST,tw,asia,1,0,http://tpe01.speedtest.rfchost.com:8080/speedtest"
  # "台湾 台南 Taiwan Mobile,tw,asia,1,0,http://spttn2.taiwanmobile.com:8080/speedtest"
  # "台湾 台中 PQS,tw,asia,1,0,http://tcg.speedtest.pni.tw:8080/speedtest"
  
  # "日本 xtom,jp,asia,1,0,http://speedtest-kix.xtom.info:8080/speedtest"
  # "日本 ctcsci,jp,asia,1,0,http://speedtest.jp230.hnd.jp.ctcsci.com:8080/speedtest"
  "日本 Rakuten Mobile,jp,asia,1,1,http://ookla.mbspeed.net:8080" # 4/6
  "日本 IPA CyberLab 400G,jp,asia,1,1,https://speed.udx.icscoe.jp:8080/speedtest" # 4/6
  "日本 FDC,jp,asia,1,0,http://lg-tok.fdcservers.net:8080/speedtest"
  "韩国 MOACK,kr,asia,1,0,http://speedtest.moack.co.kr:8080/speedtest/upload"
  "新加坡 Linode,sg,asia,1,0,http://speedtest.singapore.linode.com:8080/speedtest"
)
# filter nodes
# $1: type 4/6
# $2: area cn/global
# $3: cate all/ct/cu/cm/asia/america/europe
filter_nodes() {
  local type="$1"
  local area="$2"
  local cate="$3"
  for node in "${NODES[@]}"; do
    IFS=',' read -r name node_area node_cate v4 v6 base_url <<< "$node"
    case "$area" in
      cn)
        [[ "$node_area" != "cn" ]] && continue
        ;;
      global)
        [[ "$node_area" == "cn" ]] && continue
        ;;
    esac
    case "$cate" in
      all) ;;
      ct|cu|cm|edu)
        [[ "$node_cate" != "$cate" ]] && continue
        ;;
      asia|america|europe)
        [[ "$node_cate" != "$cate" ]] && continue
        ;;
    esac
    case "$type" in
      4) [[ "$v4" != "1" ]] && continue ;;
      6) [[ "$v6" != "1" ]] && continue ;;
    esac
    echo "$name|$base_url/download|$base_url/upload"
  done
}

print_banner() {
  print_header
  info "测试时间: $(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S %:z")"
  print_line
  print_result "测速节点" "下载(Mbps)" "上传(Mbps)" "TCP延迟" "抖动"
}
print_result() {
  COL1=32  # 测速节点
  COL2=18  # 下载速度
  COL3=18  # 上传速度
  COL4=13  # 延迟
  COL5=13  # 抖动
  printf "%-${COL1}s\t%-${COL2}s\t%-${COL3}s\t%-${COL4}s\t%-${COL5}s\n" "$1" "$2" "$3" "$4" "$5"
}
speed_test(){
  local type="$1" # 4/6
  local area="$2" # cn/global
  local cate="$3" # all/ct/cu/cm/asia/america/europe
  # echo -e "${YELLOW}start speed test: ${type} - ${area} - ${cate}${NC}"
  print_banner
  while IFS='|' read -r name download_url upload_url; do
    [ -z "$name" ] && continue
    output=$(bimc $download_url $upload_url $thread)
    IFS=',' read -r upload_speed upload_status download_speed download_status latency jitter <<< "$output"
    [ $debug -eq 1 ] && {
      echo "[$name], $download_url $upload_url"
      # echo "output: $output"
      echo "download_speed='$download_speed'"
      echo "download_status='$download_status'"
      echo "upload_speed='$upload_speed'"
      echo "upload_status='$upload_status'"
      echo "latency='$latency'"
      echo "jitter='$jitter'"
    }

    if [ $upload_status = "正常" ] && [ $download_status = "正常" ]; then
      download_speed=$(echo "$download_speed" | tr -d ' ')
      upload_speed=$(echo "$upload_speed" | tr -d ' ')
      download_status=$(echo "$download_status" | tr -d ' ')
      upload_status=$(echo "$upload_status" | tr -d ' ')
      latency=$(echo "$latency" | tr -d ' ')
      jitter=$(echo "$jitter" | tr -d ' ')
      print_result "$name" "${download_speed}Mbps ${download_status}" "${upload_speed}Mbps ${upload_status}" "${latency}ms" "${jitter}ms"
    else
      failed+=("$result")
    fi 
  done < <(filter_nodes "$type" "$area" "$cate")
}

main() {
  install_requirements
  install_bimc
  main_menu
}

main


# print_result() {
#   COL1=32  # 测速节点
#   COL2=18  # 下载速度
#   COL3=18  # 上传速度
#   COL4=13  # 延迟
#   COL5=13  # 抖动
#   printf "%-${COL1}s\t%-${COL2}s\t%-${COL3}s\t%-${COL4}s\t%-${COL5}s\n" "$1" "$2" "$3" "$4" "$5"
# }
# print_result "测速节点" "下载(Mbps)" "上传(Mbps)" "TCP延迟" "抖动"
# # 打印数据行
# print_result "日本 Rakuten Mobile" "132.9Mbps 正常" "96.7Mbps 正常" "55.8ms" "27.4ms"
# print_result "日本 IPA CyberLab 400G" "9.7Mbps 正常" "97.2Mbps 正常" "63.1ms" "5.4ms"
# print_result "电信 湖南电信" "3689.5 Mbps 正常" "4895.0 Mbps 正常" "1.1ms" "1.6ms"
# print_result "电信 湖南电信 5G" "1.5 Mbps 正常" "2.0 Mbps 正常" "1.1ms" "1.6ms"
