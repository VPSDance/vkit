#!/usr/bin/env bash

# bash <(curl -L -s check.unlock.media)
# https://github.com/lmc999/RegionRestrictionCheck

SH_PORT="${SH_PORT:-}"; SH="https://sh.vps.dance${SH_PORT:+:${SH_PORT}}"

url="lmc999/RegionRestrictionCheck/main/check.sh"

url="${SH}/raw/$url"
main() {
  bash <(
    curl -L -s $url \
    | sed '/^[ \t]*echo\( -e\)\? "[-]*"\(.*\)\?$/d' \
    | sed '/^[ \t]*echo\( -e\)\? "[=]*"\(.*\)\?$/d' \
    | sed 's/ CheckV6().*$/&\n printf "%-39s\\n" \| sed "s\/\\s\/-\/g"/' \
    | sed 's/ Goodbye().*$/&\n printf "%-39s\\n" \| sed "s\/\\s\/-\/g"/' \
    | sed '/echo\( -e\)\? ""\(.*\)\?$/d'
  )
}
main
