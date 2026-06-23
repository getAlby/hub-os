#!/usr/bin/env bash
# Weekly non-interactive Alby Hub auto-update. GPG + SHA256 verified, with rollback.
# NOTE: updating restarts the hub, which re-locks the wallet unless auto-unlock is
# enabled (same as any reboot). Enable auto-unlock for fully hands-off updates.
set -uo pipefail
HOME_DIR=/opt/albyhub
ARCH=aarch64
ASSET="albyhub-Server-Linux-${ARCH}.tar.bz2"
exec >>/var/log/albyhub-update.log 2>&1
echo "=== $(date '+%F %T') auto-update check ==="

[ -f "$HOME_DIR/disable-autoupdate" ] && { echo "disabled via flag; skipping"; exit 0; }

latest=$(curl -fsSL https://api.github.com/repos/getAlby/hub/releases/latest \
  | grep -oE '"tag_name":[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
installed=$(cat "$HOME_DIR/VERSION" 2>/dev/null || echo "")
[ -n "$latest" ] || { echo "could not resolve latest release"; exit 0; }
[ "$latest" = "$installed" ] && { echo "up to date ($installed)"; exit 0; }
echo "update available: ${installed:-unknown} -> $latest"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; cd "$tmp"
base="https://github.com/getAlby/hub/releases/download/$latest"
curl -fL -o "$ASSET" "$base/$ASSET"
curl -fL -o manifest.txt "$base/manifest.txt"
curl -fL -o manifest.txt.asc "$base/manifest.txt.asc"

export GNUPGHOME="$tmp/gnupg"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
gpg --batch --import "$HOME_DIR"/keys/*.asc
gpg --batch --verify manifest.txt.asc manifest.txt || { echo "GPG verify FAILED; aborting"; exit 1; }
exp=$(grep "$ASSET" manifest.txt | awk '{print $1}')
act=$(sha256sum "$ASSET" | awk '{print $1}')
{ [ -n "$exp" ] && [ "$exp" = "$act" ]; } || { echo "sha256 mismatch; aborting"; exit 1; }
echo "verified $latest"

mkdir -p "$tmp/new"; tar -xf "$ASSET" -C "$tmp/new"
[ -x "$tmp/new/bin/albyhub" ] || { echo "extracted binary missing; aborting"; exit 1; }

systemctl stop albyhub
rm -rf "$HOME_DIR/bin.bak" "$HOME_DIR/lib.bak"
mv "$HOME_DIR/bin" "$HOME_DIR/bin.bak"; mv "$HOME_DIR/lib" "$HOME_DIR/lib.bak"
mv "$tmp/new/bin" "$HOME_DIR/bin"; mv "$tmp/new/lib" "$HOME_DIR/lib"
setcap CAP_NET_BIND_SERVICE=+eip "$HOME_DIR/bin/albyhub"; ldconfig
echo "$latest" > "$HOME_DIR/VERSION"
chown -R albyhub:albyhub "$HOME_DIR/bin" "$HOME_DIR/lib" "$HOME_DIR/VERSION"
systemctl start albyhub

sleep 5
if systemctl is-active --quiet albyhub; then
  echo "updated to $latest OK"; rm -rf "$HOME_DIR/bin.bak" "$HOME_DIR/lib.bak"
else
  echo "service failed after update; ROLLING BACK to $installed"
  rm -rf "$HOME_DIR/bin" "$HOME_DIR/lib"
  mv "$HOME_DIR/bin.bak" "$HOME_DIR/bin"; mv "$HOME_DIR/lib.bak" "$HOME_DIR/lib"
  setcap CAP_NET_BIND_SERVICE=+eip "$HOME_DIR/bin/albyhub"; ldconfig
  echo "$installed" > "$HOME_DIR/VERSION"; chown -R albyhub:albyhub "$HOME_DIR/bin" "$HOME_DIR/lib" "$HOME_DIR/VERSION"
  systemctl start albyhub
  exit 1
fi
