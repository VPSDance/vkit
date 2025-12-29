#!/usr/bin/env bash

# https://github.com/teddysun/across/blob/master/bench.sh

SH_PORT="${SH_PORT:-}"; SH="https://sh.vps.dance${SH_PORT:+:${SH_PORT}}"

main() {
  bash <(
    curl -Lso- ${SH}/raw/teddysun/across/master/bench.sh \
    | sed "/Los Angeles/Ii speed_test '3633' 'Shanghai CT'" \
    | sed "/Los Angeles/Ii speed_test '27594' 'Guangzhou CT'" \
    | sed "/Los Angeles/Ii speed_test '29071' 'Chengdu CT'" \
    | sed "/Los Angeles/Ii speed_test '4870' 'Changsha CU'" \
    | sed "/Los Angeles/Ii speed_test '24447' 'ShangHai CU'" \
    | sed "/Los Angeles/Ii speed_test '4575' 'Chengdu CM'" \
    | sed "/Los Angeles/Ii speed_test '29105' \"Xi'an CM\"" \
    | sed "/.*, CN/Id"
    # | sed "/Los Angeles/Ii speed_test '29071' 'Chengdu CT'" \
    # | sed "/Los Angeles/Ii speed_test '34115' 'TianJin CT'" \
    # | sed "/Los Angeles/Ii speed_test '54312' 'Hangzhou CM'" \
    # | sed "/Los Angeles/Ii speed_test '26940' 'Yinchuan CM'" \
    # | sed "/Los Angeles/Ii speed_test '16145' 'Lanzhou CM'" \
  )
}
main
# ./speedtest-cli/speedtest --progress=no --server-id="29071" --accept-license --accept-gdpr

# https://www.speedtest.net/api/js/servers?search=China%20Telecom
# https://www.speedtest.net/api/js/servers?search=电信
# https://www.speedtest.net/api/js/servers?search=China%20Unicom
# https://www.speedtest.net/api/js/servers?search=联通
# https://www.speedtest.net/api/js/servers?search=China%20Mobile
# https://www.speedtest.net/api/js/servers?search=移动
