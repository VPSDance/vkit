#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://sh.vps.dance/tools.sh) [snell|snell4|realm|gost|ss|nali|ddns-go|nexttrace|hy2]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD="\033[1m"
NC='\033[0m'

OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64/aarch64, i386, 
# DISTRO=$( [[ -e $(which lsb_release) ]] && (lsb_release -si) || echo 'unknown' ) which/lsb_release command not found
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
name=$( tr '[:upper:]' '[:lower:]' <<<"$1" )
# prerelease=$( [[ "${2}" =~ ^(-p|prerelease)$ ]] && echo true || echo false )
prerelease=true
debug=$( [[ $OS == "Darwin" ]] && echo true || echo false )
ipv4="$(curl -m 5 -fsL4 http://ipv4.ip.sb)"
# ipv6="$(curl -m 5 -fsL6 http://ipv6.ip.sb)"

CURR_USER="$(whoami)"

prompt_yn () {
  while true; do
    read -p "$1 (y/N)" yn
    case "${yn:-${2:-N}}" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes(y) or no(n).";;
    esac
  done
}
init () {
  case "$name" in
    snell | snell4)
      app="$name"
      file="/root/$app.conf"
      # repo="surge-networks/snell"
      case $ARCH in
        aarch64 | armv8)
          match="linux-aarch64"
        ;;
        armv7 | armv6l)
          match="linux-armv7l"
        ;;
        *) #x86_64
         match="linux-amd64"
        ;;
      esac
    ;;
    realm)
      app="realm"
      file="/root/realm.toml"
      repo="zhboner/realm"
      # match=""
      case $ARCH in
        aarch64)
          match="aarch64.*linux-gnu.*.gz"
        ;;
        *) #x86_64
         match="x86_64.*linux-gnu.*.gz"
        ;;
      esac
    ;;
    gost)
      app="gost"
      file="/root/gost.json"
      repo="ginuerzh/gost"
      case $ARCH in
        aarch64)
          match="linux-armv8"
        ;;
        *) #x86_64
         match="linux-amd64"
        ;;
      esac
    ;;
    ss | shadowsocks)
      app="ss"
      file="/root/ss.json"
      repo="shadowsocks/shadowsocks-rust"
      case $ARCH in
        aarch64)
          match="aarch64.*linux-gnu"
        ;;
        *)
         match="x86_64.*linux-gnu"
        ;;
      esac
    ;;
    hy2)
      app="hysteria-server"
      file="/etc/hysteria/config.yaml"
    ;;
    nali)
      app="nali"
      repo="zu1k/nali"
      case $ARCH in
        aarch64)
          match="linux-armv8"
        ;;
        *)
         match="linux-amd64"
        ;;
      esac
    ;;
    # wtrace | worsttrace)
    #   app="wtrace"
    # ;;
    ddns-go)
      app="ddns-go"
      file="/root/ddns-go.yaml"
      repo="jeessy2/ddns-go"
      case $ARCH in
        aarch64)
          match="linux_.*arm64"
        ;;
        *)
         match="linux_.*x86_64"
        ;;
      esac
    ;;
    nexttrace)
      app="nexttrace"
      repo="nxtrace/Ntrace-core"
      case $ARCH in
        aarch64)
          match="linux_arm64"
        ;;
        *)
         match="linux_amd64"
        ;;
      esac
    ;;
    *)
      printf "${YELLOW}Please specify app_name (snell|realm|gost|ss|nali|ddns-go|nexttrace)\n\n${NC}";
      exit
    ;;
  esac
}
install_deps () {
    case "${DISTRO}" in
    Debian*|Ubuntu*)
      apt install -y curl wget zip unzip tar xz-utils gzip;
    ;;
    CentOS*|RedHat*)
      yum install -y curl wget zip unzip tar xz gzip;
    ;;
    *)
    ;;
  esac
}
not_support_ipv6 () {
  app="$1"
  if [ -z "$ipv4" ]; then
    printf "\n${RED}[x] $app does not support downloading over IPv6. ${NC}\n\n"; exit 1;
  fi
}
download () {
  local temp_dir=$(mktemp -d)
  suffix=$( [[ "$prerelease" = true ]] && echo "releases" || echo "releases/latest" )
  prefix=$( [ -z "$ipv4" ] && echo "https://sh.vps.dance" || echo "https://ghfast.top" )
  if [[ -n "$repo" ]]; then
    # api="https://api.github.com/repos/$repo/$suffix"
    api="https://sh.vps.dance/api/repos/$repo/$suffix"
    # curl -s https://api.github.com/repos/nxtrace/NTrace-core/releases | grep "browser_download_url.*$match" | head -1 | cut -d : -f 2,3 | xargs echo
    url=$( curl -s $api | grep "browser_download_url.*$match" | head -1 | cut -d : -f 2,3 | xargs echo ) # xargs wget
    if [[ -z "$url" ]]; then
      printf "\n${RED}[x] github api error ${NC}\n\n"; exit 1;
    fi
    url="$prefix/$url"
  fi
  # echo $api; echo $url;exit
  # echo -e "\n${GREEN}$app${NC}"
  case "$app" in
    snell)
      version="v3.0.1"
      url="https://raw.githubusercontent.com/VPSDance/files/main/snell/${version}/snell-server-${version}-${match}.zip"
      url="$prefix/$url"
    ;;
    snell4)
      not_support_ipv6 $app
      # https://manual.nssurge.com/others/snell.html
      version="v4.0.1"
      # url="https://raw.githubusercontent.com/VPSDance/files/main/snell/${version}/snell-server-${version}-${match}.zip"
      # url="$prefix/$url"
      url="https://dl.nssurge.com/snell/snell-server-${version}-${match}.zip"
    ;;
    realm)
      if [[ "$debug" != true ]]; then
        rm -rf /usr/bin/realm ./realm;
      fi
    ;;
    nexttrace)
      rm -rf ./nexttrace_*
    ;;
    # wtrace)
    #   not_support_ipv6 $app
    #   case $ARCH in
    #     aarch64)
    #       printf "${RED}[x] $ARCH not supported ${PLAIN}\n${NC}"; exit 1;
    #     ;;
    #     *)
    #      url="https://wtrace.app/packages/linux/worsttrace"
    #     ;;
    #   esac
    # ;;
  esac
  echo -e "${GREEN}\n[Download]${NC}"
  echo "$url"
  if [[ "$debug" != true ]]; then
    if [[ -n "$url" ]]; then
      wget --show-progress -P "$temp_dir" "$url"
    fi
  fi
  # echo -e "\n[Extract files]"
  # tar xJvf .tar.xz/.txz # apt install -y xz-utils
  # tar xzvf .tar.gz
  # tar xvf .tar 
  # unzip -o .zip # apt install -y unzip
  # gzip -d .gz
  if [[ "$debug" = true ]]; then return; fi

  case "$app" in
    snell)
      unzip -o "$temp_dir"/snell*.zip -d "$temp_dir" && rm -f "$temp_dir"/snell-server-*.zip*
      mv "$temp_dir"/snell-server /usr/bin/
    ;;
    snell4)
      unzip -o "$temp_dir"/snell*.zip -d "$temp_dir" && rm -f "$temp_dir"/snell-server-*.zip*
      mv "$temp_dir"/snell-server /usr/bin/snell4-server
    ;;
    realm)
      # curl -s https://api.github.com/repos/zhboner/realm/releases/latest | grep "browser_download_url.*" | cut -d : -f 2,3 | xargs wget -O ./realm {}; chmod +x realm
      if [[ `compgen -G "$temp_dir/realm*.tar.gz"` ]]; then 
        tar xzvf "$temp_dir"/realm*.tar.gz -C "$temp_dir" && rm -f "$temp_dir"/realm*.tar.gz
      fi
      mv "$temp_dir"/realm /usr/bin/realm && chmod +x /usr/bin/realm
    ;;
    gost)
      gzip -d "$temp_dir"/gost-*.gz
      mv "$temp_dir"/gost-* /usr/bin/gost && chmod +x /usr/bin/gost
    ;;
    ss)
      tar xJf "$temp_dir"/shadowsocks-*.xz -C "$temp_dir" && rm -f "$temp_dir"/shadowsocks-*.xz*
      mv "$temp_dir"/ssserver "$temp_dir"/sslocal "$temp_dir"/ssurl "$temp_dir"/ssmanager "$temp_dir"/ssservice /usr/bin/
    ;;
    hysteria-server)
      bash <(curl -fsSL https://get.hy2.sh/)
    ;;
    nali)
      gzip -d "$temp_dir"/nali-*.gz
      mv "$temp_dir"/nali-* /usr/bin/nali && chmod +x /usr/bin/nali
      nali update
    ;;
    # wtrace)
    #   mv "$temp_dir"/worsttrace /usr/bin/worsttrace && chmod +x /usr/bin/worsttrace
    # ;;
    ddns-go)
      tar xzf "$temp_dir"/ddns-go_*tar.gz -C "$temp_dir"
      mv "$temp_dir"/ddns-go /usr/bin/ && rm -f "$temp_dir"/ddns-go_*tar.gz* "$temp_dir"/LICENSE "$temp_dir"/README.md
    ;;
    nexttrace)
      mv "$temp_dir"/nexttrace_* /usr/bin/nexttrace && chmod +x /usr/bin/nexttrace
    ;;
    *);;
  esac
  rm -rf "$temp_dir"
}
gen_service () {
  local service=""
  case "$app" in
    snell)
      service='[Unit]\nDescription=Snell Service\nAfter=network.target\n[Service]\nType=simple\nLimitNOFILE=32768\nRestart=on-failure\nExecStart=/usr/bin/snell-server -c /root/snell.conf\nStandardOutput=syslog\nStandardError=syslog\nSyslogIdentifier=snell-server\n[Install]\nWantedBy=multi-user.target\n'
    ;;
    snell4)
      service='[Unit]\nDescription=Snell Service\nAfter=network.target\n[Service]\nType=simple\nLimitNOFILE=32768\nRestart=on-failure\nExecStart=/usr/bin/snell4-server -c /root/snell4.conf\nStandardOutput=syslog\nStandardError=syslog\nSyslogIdentifier=snell-server\n[Install]\nWantedBy=multi-user.target\n'
    ;;
    realm)
      service='[Unit]\nDescription=realm\nAfter=network-online.target\nWants=network-online.target systemd-networkd-wait-online.service\n[Service]\nType=simple\nUser=root\nRestart=on-failure\nRestartSec=5s\nExecStart=/usr/bin/realm -c /root/realm.toml\n[Install]\nWantedBy=multi-user.target'
    ;;
    gost)
      service='[Unit]\nDescription=gost\nAfter=network-online.target\nWants=network-online.target systemd-networkd-wait-online.service\n[Service]\nType=simple\nUser=root\nRestart=on-failure\nRestartSec=5s\nExecStart=/usr/bin/gost -C /root/gost.json\n[Install]\nWantedBy=multi-user.target'
    ;;
    ss)
      service='[Unit]\nDescription=Shadowsocks\nAfter=network.target\n[Service]\nType=simple\nRestart=on-failure\nExecStart=/usr/bin/ssserver -c /root/ss.json\n[Install]\nWantedBy=multi-user.target\n'
    ;;
    ddns-go)
      service='[Unit]\nDescription=ddns-go\n[Service]\nExecStart=/usr/bin/ddns-go "-l" ":9876" "-f" "120" "-c" "/root/ddns-go.yaml"\nStartLimitInterval=5\nStartLimitBurst=10\nRestart=always\nRestartSec=120\n[Install]\nWantedBy=multi-user.target\n'
    ;;
  esac
  if [[ -n "$service" ]]; then
    echo -e "${GREEN}\n[Generate service]${NC}" >&2
    echo -e "$service" >&2

    echo -e "$service" > "/etc/systemd/system/$app.service"
    systemctl daemon-reload
    systemctl enable "$app"

    echo "$service"
  fi
}
gen_config () {
  if ! [[ -n "$file" ]]; then return; fi # no config path
  # if [[ -f "$file" ]]; then
  #   if ! prompt_yn "\"$file\" already exists, do you want to overwrite it?"; then return; fi
  # else
  #   if ! prompt_yn "Do you want to create \"$file\"?"; then return; fi
  # fi
  # read -p "Specify port number: " port
  # while [[ ! ${port} =~ ^[0-9]+$ ]]; do
  #   echo "Please enter number of port:"
  #   read port
  # done
  # port=$(( ${RANDOM:0:4} + 10000 )) # random 10000-20000
  port="${port:-1234}"
  pass=$(openssl rand -base64 32 | tr -dc A-Za-z0-9 | cut -b1-16)
  # conf=('{'
  # '}')
  # conf="$(printf "%s\n" "${conf[@]}")"
  # conf="$(
  #   echo '{'
  #   echo '}'
  # )"
  case "$app" in
    snell)
      conf="[snell-server]\nlisten = ::0:$port\nipv6 = false\npsk = $pass\nobfs = tls"
    ;;
    snell4)
      conf="[snell-server]\nlisten = ::0:$port\nipv6 = false\npsk = $pass" #v4
    ;;
    realm)
      conf=(''
        '[log]'
        'level = "warn"'
        ''
        '[dns]'
        '# mode = "ipv6_then_ipv4" # ipv4_then_ipv6, ipv6_then_ipv4'
        ''
        '[network]'
        'no_tcp = false'
        'use_udp = true'
        ''
        '[[endpoints]]'
        'listen = "0.0.0.0:10001"'
        'remote = "test.com:80"'
        ''
        '[[endpoints]]'
        'listen = "0.0.0.0:10002"'
        'remote = "1.1.1.1:443"'
      '')

      conf="$(printf "%s\n" "${conf[@]}")"
    ;;
    gost)
      conf=('{'
        ' "Debug": true,'
        ' "Retries": 0,'
        ' "ServeNodes": ['
        '   "tcp://:10002/1.1.1.1:443"'
        ' ],'
        ' "ChainNodes": ['
        ' ],'
        ' "Routes": ['
        ' ]'
      '}')
      conf="$(printf "%s\n" "${conf[@]}")"
    ;;
    ss)
      conf=('{'
      '"mode": "tcp_and_udp",'
      '"fast_open": false,'
      '"ipv6_first": true,'
      '"servers": ['
      '{'
        ' "address": "::",'
        ' "port": '$port','
        ' "password": "'$pass'",'
        ' "method": "chacha20-ietf-poly1305",'
        ' "timeout": 300'
      '}'
      ']}')
      conf="$(printf "%s\n" "${conf[@]}")"
    ;;
  esac
  # echo "--- file: $file, conf: $conf"
  if [[ -n "$file" && -n "$conf" ]]; then
    echo -e "${GREEN}\n[Create config file]${NC} \"$file\", for example:"
    echo -e "$conf"
  fi
  if [[ -f "/root/realm.json" && "$app" == "realm" ]]; then
    printf "\n%b\n" "${YELLOW}Convert Realm1 to Realm2 config${NC}: realm convert realm.json > realm.toml";
  fi
}
finally () {
  local service="$*"
  local ip=`curl -Ls ip.sb || echo 'localhost'`;
  # echo -e "finally: $service"

  if [[ -n "$service" ]]; then
    echo -e "${GREEN}\n[Enable and start service]${NC}"
  else
    echo -e "${GREEN}\n[Usage]${NC}"
  fi
  service_tips="${GREEN}systemctl enable $app; systemctl restart $app; systemctl status $app;${NC}"
  case "$app" in
    hysteria-server)
      tips="Please modify the ${RED}listen${NC}, ${RED}acme.domains${NC}, ${RED}acme.email${NC}, and ${RED}masquerade.proxy.url${NC} in the config file."
      tips+="\nDocs: https://v2.hysteria.network/en/docs/getting-started/Server/"
      tips+="\n\n$service_tips"
    ;;
    nali)
      tips="nali update;\nping g.cn | nali;\ntraceroute 189.cn | nali"
    ;;
    # wtrace)
    #   tips="worsttrace g.cn;"
    # ;;
    ddns-go)
      systemctl restart $app;
      tips="\nOpen http://$ip:9876 for configuration."
      tips+="\n\n$service_tips"
    ;;
    nexttrace)
      tips="nexttrace -T -f"
    ;;
    *)
      tips="$service_tips"
    ;;
  esac
  # if [[ -n "$file" ]]; then
  #   tips+="\n\n${GREEN}[Config file]${NC} \"$file\"\n"
  # fi
  if [[ -n "$tips" ]]; then
    echo -e "$tips\n"
  fi
}

# echo "name: $name; repo=$repo; prerelease=$prerelease"
init

with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER OS ARCH DISTRO name prerelease debug ipv4 app file repo match RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC 2>/dev/null)"
    local declare_funcs="$(declare -f)"
    cmd="$declare_vars; $declare_funcs; $1 "'"${@:2}"'
  else
    cmd="$1 "'"${@:2}"'
  fi

  if [[ $EUID -ne 0 ]]; then
    sudo bash -c "$cmd" -- "$@" < /dev/tty
  else
    bash -c "$cmd" -- "$@" -- "$@"
  fi
}

with_sudo install_deps
with_sudo download
service=$(with_sudo gen_service)
# echo -e "gen_service:\n$service"
# with_sudo echo "-- $service"
# with_sudo echo -e "$service"
with_sudo gen_config
with_sudo finally "$service"
