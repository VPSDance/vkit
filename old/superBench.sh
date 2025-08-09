#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://raw.githubusercontent.com/VPSDance/vkit/main/superBench.sh)
# Reference:
# https://github.com/oooldking/script

ver_lte() { # <=
  [  "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$1" ] && return 0 || return 1
}
python_version() {
  python -V 2>&1 | awk '{print $2}' # | awk -F '.' '{print $1}'
}
main() {
  # fix python3 error
  local ver=$(python_version) # echo $ver
  curl -Lso- https://raw.githubusercontent.com/oooldking/script/master/tools.py > tools.py
  if (ver_lte 3 $ver); then
    sed -i 's/print \(.*\)$/print(\1)/g' tools.py
    sed -i 's/,urllib2,/,/g' tools.py
    sed -i 's/,json,sys.*$/&\nimport urllib.request as urllib2/' tools.py
    sed -i '/reload(sys).*$/d' tools.py
    sed -i '/sys.setdefaultencoding.*$/d' tools.py
    sed -i "s/para.encode('utf-8')/para/g" tools.py
  fi
  bash <(
    curl -Lso- https://raw.githubusercontent.com/oooldking/script/master/superbench_git.sh \
    | sed 's/^.*fast\.com.*$/:;/I' \
    | sed 's/^.*[ /]fast_com.*.py.*$/#/I' \
    | sed "s/27377' 'Beijing/34115' 'TianJin/Ig" \
    | sed "s/27154' 'TianJin/4870' 'Changsha/Ig" \
    | sed "s/26678' 'Guangzhou 5G/13704' 'Nanjing/Ig" \
    | sed "/17184' 'Tianjin/Id" \
    | sed "/.*28491' 'Changsha/Id" \
    | sed '/^[ \t]*speed_fast_com$/d'
    # | sed "/.*26850' 'Wuxi/Id"
    # | sed "s/27249' 'Nanjing 5G/15863' 'Nanning/Ig"
  )
}
main

# https://www.speedtest.net/api/js/servers?search=China%20Telecom
# https://www.speedtest.net/api/js/servers?search=电信
# https://www.speedtest.net/api/js/servers?search=China%20Unicom
# https://www.speedtest.net/api/js/servers?search=联通
# https://www.speedtest.net/api/js/servers?search=China%20Mobile
# https://www.speedtest.net/api/js/servers?search=移动
