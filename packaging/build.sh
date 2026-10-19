#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/packaging/stage"
PACKAGING="$ROOT/packaging"
DIST="$ROOT/dist"
VERSION="$(grep -E '^version:' "$ROOT/pubspec.yaml" | sed -E 's/version:\s*([0-9.]+).*/\1/' | cut -d+ -f1)"
NAME="轻图-flutter-${VERSION}-win64-绿色版"
INSTALLER_MODE="${INSTALLER:-both}"
EXE_NAME="qingtu_flutter.exe"

find_flutter() {
  [[ -n "${FLUTTER_BIN:-}" && -x "$FLUTTER_BIN" ]] && { echo "$FLUTTER_BIN"; return; }
  local sdk="$ROOT/../.flutter/bin/flutter"
  [[ -x "$sdk" ]] && { echo "$sdk"; return; }
  command -v flutter 2>/dev/null || true
}

FLUTTER="$(find_flutter || true)"
[[ -n "$FLUTTER" ]] || { echo "未找到 flutter，请设置 PATH 或 FLUTTER_BIN"; exit 1; }

cd "$ROOT"
"$FLUTTER" pub get
"$FLUTTER" build windows --release

RELEASE="$ROOT/build/windows/x64/runner/Release"
[[ -f "$RELEASE/$EXE_NAME" ]] || { echo "未找到 $RELEASE/$EXE_NAME"; exit 1; }

PORTABLE_DIR="$DIST/$NAME"
rm -rf "$DIST"
mkdir -p "$PORTABLE_DIR"
cp -a "$RELEASE/." "$PORTABLE_DIR/"
cp -f "$STAGE/启动.bat" "$STAGE/使用说明.txt" "$PORTABLE_DIR/"

(cd "$DIST" && tar -a -cf "${NAME}.zip" "$NAME")
echo "绿色版: $DIST/${NAME}.zip ($(du -sh "$PORTABLE_DIR" | cut -f1))"

if [[ "$INSTALLER_MODE" == "nsis" || "$INSTALLER_MODE" == "both" ]]; then
  INSTALLER_STAGE="$PACKAGING/installer-stage"
  rm -rf "$INSTALLER_STAGE"
  mkdir -p "$INSTALLER_STAGE"
  cp -r "$PORTABLE_DIR"/* "$INSTALLER_STAGE/"
  SETUP_EXE="$DIST/轻图-flutter-${VERSION}-win64-setup.exe"
  SETUP_ASCII="$DIST/Qingtu-Flutter-${VERSION}-win64-setup.exe"
  for p in "/c/Program Files (x86)/NSIS/makensis.exe" "/c/Program Files/NSIS/makensis.exe"; do
    if [[ -f "$p" ]]; then
      "$p" "//INPUTCHARSET" "UTF8" "//DVERSION=$VERSION" \
        "//DSTAGE_DIR=$(cygpath -w "$INSTALLER_STAGE")" \
        "//DOUTFILE=$(cygpath -w "$SETUP_ASCII")" \
        "$(cygpath -w "$PACKAGING/nsis/setup.nsi")"
      mv -f "$SETUP_ASCII" "$SETUP_EXE"
      echo "安装包: $SETUP_EXE ($(du -sh "$SETUP_EXE" | cut -f1))"
      break
    fi
  done
  if [[ ! -f "$SETUP_EXE" ]]; then
    echo "未找到 NSIS (makensis)，跳过安装包。"
  fi
fi
