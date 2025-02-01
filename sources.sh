#!/usr/bin/env bash
# sudo bash <(curl -Lso- https://sh.vps.dance/sources.sh) debian11
# sudo bash <(curl -Lso- https://sh.vps.dance/sources.sh) debian12
# sudo bash <(curl -Lso- https://sh.vps.dance/sources.sh) aliyun

sources_list="/etc/apt/sources.list"
name=$( tr '[:upper:]' '[:lower:]' <<<"$1" )

debian_sources() {
  local version=$1
  local codename=""
  local components="main"
  
  case "$version" in
    "11"|"debian11")
      codename="bullseye"
      ;;
    "12"|"debian12")
      codename="bookworm"
      components="main non-free-firmware"
      ;;
  esac

  backup_sources

  (
  echo "deb http://deb.debian.org/debian $codename $components"
  echo "deb-src http://deb.debian.org/debian $codename $components"
  echo "deb http://security.debian.org/debian-security $codename-security $components"
  echo "deb-src http://security.debian.org/debian-security $codename-security $components"
  echo "deb http://deb.debian.org/debian $codename-updates $components"
  echo "deb-src http://deb.debian.org/debian $codename-updates $components"
  # echo "deb http://deb.debian.org/debian $codename-backports $components"
  # echo "deb-src http://deb.debian.org/debian $codename-backports $components"
  ) > $sources_list
}

aliyun() {
  backup_sources
  # main
  sed -i -E 's#https?://[^/]+/debian#https://mirrors.aliyun.com/debian#g' $sources_list
  # security
  sed -i -E 's#https?://[^/]+/debian-security#https://mirrors.aliyun.com/debian-security#g' $sources_list
  sed -i -E 's#https?://security\.debian\.org#https://mirrors.aliyun.com/debian-security#g' $sources_list
  # backports
  sed -i -E 's#https?://[^/]+/debian.*-backports#https://mirrors.aliyun.com/debian-backports#g' $sources_list
}

backup_sources() {
  # add timestamp to backup file
  local timestamp=$(date +%Y%m%d_%H%M%S)
  cp $sources_list{,."$timestamp".bak}
  echo "Backup created: $sources_list.$timestamp.bak"
}

upgrade_tips() {
  echo "Please run:"
  echo "apt update -y && apt upgrade -y && apt autoremove -y && apt autoclean -y"
  echo "cat /etc/os-release"
}
sources_tips() {
  echo "cat $sources_list"
}

main() {
  if [[ "$name" == "debian11" ]]; then
    debian_sources "11"
    upgrade_tips
  elif [[ "$name" == "debian12" ]]; then
    debian_sources "12"
    upgrade_tips
  elif [[ "$name" == "aliyun" ]]; then
    aliyun
    sources_tips
  else
    echo "Error: not supported."
    exit 1
  fi
  # echo "Done."
}
main
