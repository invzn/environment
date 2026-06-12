#!/usr/bin/env bash
#
# Enable hibernation (suspend-to-disk) on the installed Lemur Pro.
#
# Decision #1 deferred this: zram covers everyday swap; this script adds the
# disk-backed swap that hibernate requires, the day you decide you want it.
#
# What it does (idempotent — safe to re-run):
#   * creates a dedicated, snapshot-excluded @swap subvolume mounted at /swap
#   * creates a NOCOW Btrfs swapfile >= RAM (so the hibernate image always fits)
#   * computes the physical resume offset
#   * adds resume=/resume_offset= to the systemd-boot entry + an fstab line
#
# The swapfile lives INSIDE your LUKS volume, so the hibernate image is
# encrypted at rest and resume happens cleanly after the boot-time unlock.
#
# Run as root on the installed system:  sudo ./enable-hibernate.sh
#
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"

ROOT_DEV="/dev/mapper/cryptroot"
ENTRY="/boot/loader/entries/arch.conf"
SWAP_MNT="/swap"
SWAPFILE="$SWAP_MNT/swapfile"

[ -b "$ROOT_DEV" ] || die "$ROOT_DEV not found — is this the Lemur Pro install?"
[ -f "$ENTRY" ]    || die "$ENTRY not found — expected systemd-boot entry"

# Size = RAM rounded up to whole GiB (image can't exceed RAM, so >= RAM is safe).
ram_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
size_gib=$(( (ram_kb + 1048575) / 1048576 ))
echo ">> RAM ~${size_gib}GiB → swapfile ${size_gib}GiB"

# --- @swap subvolume (top-level sibling of @, excluded from snapshots) ------
if ! findmnt -no TARGET "$SWAP_MNT" >/dev/null 2>&1; then
  top="$(mktemp -d)"
  mount -o subvolid=5 "$ROOT_DEV" "$top"
  [ -d "$top/@swap" ] || btrfs subvolume create "$top/@swap"
  umount "$top"; rmdir "$top"
  mkdir -p "$SWAP_MNT"
  mount -o noatime,subvol=@swap "$ROOT_DEV" "$SWAP_MNT"
fi

# Persist the @swap mount in fstab (once).
if ! grep -q 'subvol=/@swap\|subvol=@swap' /etc/fstab; then
  uuid="$(blkid -s UUID -o value "$ROOT_DEV")"
  printf 'UUID=%s  %s  btrfs  noatime,subvol=@swap  0 0\n' "$uuid" "$SWAP_MNT" >> /etc/fstab
fi

# --- Swapfile (NOCOW, uncompressed — Btrfs requires this) ------------------
if [ ! -f "$SWAPFILE" ]; then
  # btrfs-progs >= 6.1 sets NOCOW + correct flags for us.
  btrfs filesystem mkswapfile --size "${size_gib}g" --uuid clear "$SWAPFILE"
fi
swapon "$SWAPFILE" 2>/dev/null || true

# Persist the swapfile in fstab, lower priority than zram so zram is used first.
if ! grep -q "$SWAPFILE" /etc/fstab; then
  printf '%s  none  swap  defaults,pri=-2  0 0\n' "$SWAPFILE" >> /etc/fstab
fi

# --- Resume plumbing -------------------------------------------------------
offset="$(btrfs inspect-internal map-swapfile -r "$SWAPFILE")"
[ -n "$offset" ] || die "could not determine resume_offset"
echo ">> resume_offset = $offset"

if grep -q 'resume=' "$ENTRY"; then
  echo ">> resume= already present in $ENTRY — leaving boot entry as-is"
else
  sed -i "/^options / s|\$| resume=${ROOT_DEV} resume_offset=${offset}|" "$ENTRY"
  echo ">> patched $ENTRY"
fi

# systemd-based initramfs handles resume from the cmdline; rebuild to be safe.
mkinitcpio -P

echo
echo "Hibernation enabled. Test with:  systemctl hibernate"
echo "(zram is everyday swap at higher priority; this disk swap is primarily for"
echo " hibernate, but the kernel MAY spill to it under heavy memory pressure once"
echo " zram fills — with swappiness=100 that's not 'reserved', just lower-priority.)"
