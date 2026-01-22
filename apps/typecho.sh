#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Typecho 升级脚本

用法:
  ./typecho.sh [-s 站点目录] [--dry-run]

选项:
  -s, --site       站点根目录 (默认: 当前目录)
  --dry-run        仅预演(dry-run), 不改动文件
  -h, --help       显示帮助
EOF
}

SITE_ROOT="${PWD}"
SH_PORT="${SH_PORT:-}"
SH="https://sh.vps.dance${SH_PORT:+:${SH_PORT}}"
ZIP_URL="${SH}/https://github.com/typecho/typecho/releases/latest/download/typecho.zip"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--site)
      SITE_ROOT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

copy_dir() {
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$1/" "$2/"
  else
    cp -a "$1/." "$2/"
  fi
}

copy_file() {
  cp -a "$1" "$2"
}

prompt_yn() {
  local msg="$1"
  read -r -p "$msg [y/N]: " yn </dev/tty
  case "${yn:-N}" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}

detect_admin_dir() {
  local cfg="$SITE_ROOT/config.inc.php"
  local admin="admin"
  local line=""

  if [ -f "$cfg" ]; then
    if command -v rg >/dev/null 2>&1; then
      line="$(rg -m 1 "__TYPECHO_ADMIN_DIR__" "$cfg" || true)"
    else
      line="$(grep -m 1 "__TYPECHO_ADMIN_DIR__" "$cfg" || true)"
    fi
    if [ -n "$line" ]; then
      admin="$(echo "$line" | sed -E "s/.*'([^']+)'.*/\\1/")"
    fi
  fi

  admin="${admin#/}"
  admin="${admin%/}"
  echo "$admin"
}

if [ ! -f "$SITE_ROOT/config.inc.php" ]; then
  echo "错误: 未找到 config.inc.php, 已终止. 请确认站点根目录正确."
  exit 1
fi

need_cmd unzip
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo "Missing required command: curl or wget"
  exit 1
fi

ADMIN_DIR="$(detect_admin_dir)"
TS="$(date +%Y%m%d%H%M%S)"
STAGING="/tmp/typecho-upgrade/.staging_$TS"
BACKUP="/tmp/typecho-upgrade/$TS"
TMP_DIR="$(mktemp -d -t typecho-upgrade.XXXXXX)"
ZIP_PATH="$TMP_DIR/typecho.zip"
SRC_DIR="$TMP_DIR/src"
HAS_INSTALL_DIR=0

cleanup() {
  rm -rf "$STAGING" "$TMP_DIR"
}

rollback() {
  if [ -d "$BACKUP" ]; then
    if [ -d "$BACKUP/$ADMIN_DIR" ]; then
      [ -d "$SITE_ROOT/$ADMIN_DIR" ] && rm -rf "$SITE_ROOT/$ADMIN_DIR"
      mv "$BACKUP/$ADMIN_DIR" "$SITE_ROOT/$ADMIN_DIR"
    fi
    if [ -d "$BACKUP/install" ]; then
      [ -d "$SITE_ROOT/install" ] && rm -rf "$SITE_ROOT/install"
      mv "$BACKUP/install" "$SITE_ROOT/install"
    fi
    if [ -d "$BACKUP/var" ]; then
      [ -d "$SITE_ROOT/var" ] && rm -rf "$SITE_ROOT/var"
      mv "$BACKUP/var" "$SITE_ROOT/var"
    fi
    if [ -f "$BACKUP/index.php" ]; then
      [ -f "$SITE_ROOT/index.php" ] && rm -f "$SITE_ROOT/index.php"
      mv "$BACKUP/index.php" "$SITE_ROOT/index.php"
    fi
    if [ -f "$BACKUP/install.php" ]; then
      [ -f "$SITE_ROOT/install.php" ] && rm -f "$SITE_ROOT/install.php"
      mv "$BACKUP/install.php" "$SITE_ROOT/install.php"
    fi
  fi
}

trap 'echo "Upgrade failed, rolling back..."; rollback; cleanup; exit 1' ERR

mkdir -p "$SRC_DIR"

if command -v curl >/dev/null 2>&1; then
  curl -fL "$ZIP_URL" -o "$ZIP_PATH"
else
  wget -O "$ZIP_PATH" "$ZIP_URL"
fi

unzip -q "$ZIP_PATH" -d "$SRC_DIR"

SRC_ROOT="$SRC_DIR"
if [ ! -f "$SRC_ROOT/index.php" ]; then
  SRC_ROOT="$(find "$SRC_DIR" -maxdepth 2 -type f -name index.php -print -quit | xargs -r dirname)"
fi
if [ -z "${SRC_ROOT:-}" ] || [ ! -f "$SRC_ROOT/index.php" ]; then
  echo "Error: could not locate Typecho files in the zip."
  exit 1
fi
if [ ! -d "$SRC_ROOT/admin" ] || [ ! -d "$SRC_ROOT/var" ] || [ ! -f "$SRC_ROOT/install.php" ]; then
  echo "Error: zip contents look incomplete (admin/var/install.php missing)."
  exit 1
fi

mkdir -p "$STAGING/$ADMIN_DIR" "$STAGING/install" "$STAGING/var"
copy_dir "$SRC_ROOT/admin" "$STAGING/$ADMIN_DIR"
copy_dir "$SRC_ROOT/var" "$STAGING/var"
copy_file "$SRC_ROOT/index.php" "$STAGING/index.php"
copy_file "$SRC_ROOT/install.php" "$STAGING/install.php"
if [ -n "$ADMIN_DIR" ] && [ -f "$STAGING/install.php" ]; then
  sed -E -i "s#(define\\('__TYPECHO_ADMIN_DIR__',\\s*')[^']*('\\);)#\\1/${ADMIN_DIR}/\\2#" "$STAGING/install.php"
fi

if [ -d "$SRC_ROOT/install" ]; then
  copy_dir "$SRC_ROOT/install" "$STAGING/install"
  HAS_INSTALL_DIR=1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  cat <<EOF
Dry run only. Planned actions:
  - Replace: $SITE_ROOT/$ADMIN_DIR
  - Replace: $SITE_ROOT/install (if present in zip)
  - Replace: $SITE_ROOT/var
  - Replace: $SITE_ROOT/index.php
  - Replace: $SITE_ROOT/install.php
  - Backup to: $BACKUP
EOF
  cleanup
  trap - ERR
  exit 0
fi

mkdir -p "$BACKUP"
[ -d "$SITE_ROOT/$ADMIN_DIR" ] && mv "$SITE_ROOT/$ADMIN_DIR" "$BACKUP/$ADMIN_DIR"
[ -d "$SITE_ROOT/var" ] && mv "$SITE_ROOT/var" "$BACKUP/var"
[ -f "$SITE_ROOT/index.php" ] && mv "$SITE_ROOT/index.php" "$BACKUP/index.php"
[ -f "$SITE_ROOT/install.php" ] && mv "$SITE_ROOT/install.php" "$BACKUP/install.php"

mv "$STAGING/$ADMIN_DIR" "$SITE_ROOT/$ADMIN_DIR"
mv "$STAGING/var" "$SITE_ROOT/var"
mv "$STAGING/index.php" "$SITE_ROOT/index.php"
mv "$STAGING/install.php" "$SITE_ROOT/install.php"

if [ "$HAS_INSTALL_DIR" -eq 1 ]; then
  [ -d "$SITE_ROOT/install" ] && mv "$SITE_ROOT/install" "$BACKUP/install"
  mv "$STAGING/install" "$SITE_ROOT/install"
else
  rm -rf "$STAGING/install"
fi

cleanup
trap - ERR

cat <<EOF
升级文件已替换完成.
下一步:
  1) 登录后台并按提示完成升级.
  2) 若升级后出现 500 错误, 请先禁用插件并切换到默认主题, 再逐个启用排查.
备份(用于回滚): $BACKUP
EOF

echo "建议先确认站点运行正常再删除备份."
if prompt_yn "Delete backup now?"; then
  rm -rf "$BACKUP"
  echo "备份已删除."
fi
