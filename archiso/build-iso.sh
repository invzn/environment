#!/usr/bin/env bash
#
# Build a custom Arch ISO for the Lemur Pro install.
#
# Approach: copy the official 'releng' profile, overlay our package additions and
# the install scripts, then run mkarchiso. We do NOT vendor releng — copying the
# system one keeps the build resilient to upstream changes.
#
# Requirements: an Arch system with 'archiso' installed; run as root.
#   pacman -S archiso
#   sudo ./build-iso.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(cd "$HERE/.." && pwd)"
SRC=/usr/share/archiso/configs/releng
# /var/tmp, NOT /tmp: /tmp is tmpfs on Arch and the mkarchiso work dir runs to
# several GB — building there eats RAM or dies with ENOSPC.
WORK="${WORK:-/var/tmp/archlive-lemurpro}"
OUT="${OUT:-$HERE/out}"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
[ -d "$SRC" ] || { echo "archiso not installed — run: pacman -S archiso"; exit 1; }

echo ">> Staging profile from $SRC"
rm -rf "$WORK"
cp -r "$SRC" "$WORK"

echo ">> Adding installer packages to the live environment"
cat "$HERE/extra-packages.x86_64" >> "$WORK/packages.x86_64"

echo ">> Embedding install scripts into the live root home (/root)"
install -d -m0750 "$WORK/airootfs/root"
install -m0755 "$KIT/install.sh"         "$WORK/airootfs/root/install.sh"
install -m0755 "$KIT/chroot-setup.sh"    "$WORK/airootfs/root/chroot-setup.sh"
install -m0755 "$KIT/post-install.sh"    "$WORK/airootfs/root/post-install.sh"
install -m0755 "$KIT/enable-hibernate.sh" "$WORK/airootfs/root/enable-hibernate.sh"
install -m0755 "$KIT/setup-backups.sh"    "$WORK/airootfs/root/setup-backups.sh"

echo ">> Adding a login hint (motd)"
cat > "$WORK/airootfs/etc/motd" <<'EOF'

  ┌────────────────────────────────────────────────────────────┐
  │  System76 Lemur Pro — Arch installer ISO                    │
  │                                                            │
  │  1. Connect to the network (iwctl / nmcli)                 │
  │  2. Review the CONFIG block:  head -40 /root/install.sh    │
  │  3. Run:  /root/install.sh    (this WIPES the target disk) │
  └────────────────────────────────────────────────────────────┘

EOF

mkdir -p "$OUT"
echo ">> Building ISO (this takes a while and needs network for the package pull)"
mkarchiso -v -w "$WORK/work" -o "$OUT" "$WORK"

echo
echo ">> ISO written to: $OUT"
echo "   Write it with:  dd if=$OUT/archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
