#!/usr/bin/env bash
#
# test-vm.sh — dry-run the Lemur Pro installer in a throwaway UEFI QEMU VM,
# so the whole partition → LUKS → Btrfs → snapper → boot path gets *executed*
# before it ever touches the real laptop.
#
# Faithful-ish on purpose:
#   * x86_64 + UEFI (OVMF firmware)         — install.sh requires UEFI
#   * disk presented as emulated NVMe       — appears as /dev/nvme0n1, so the
#                                             installer runs with its defaults
#   * user-mode NAT networking              — pacstrap can reach the mirrors
#
# Works on macOS (HVF, or TCG on Apple Silicon) and Linux (KVM if available).
# Nothing here needs root, and the disk/vars live in ./.vm/ (throwaway).
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Defaults / args -------------------------------------------------------
DISK_IMG="${DISK_IMG:-$HERE/.vm/lemur-test.qcow2}"
VARS_IMG="${VARS_IMG:-$HERE/.vm/uefi-vars.fd}"
DISK_SIZE="${DISK_SIZE:-40G}"
RAM="${RAM:-4096}"          # MB
CPUS="${CPUS:-4}"
ISO="${ISO:-}"
MODE=install                # install | boot-disk
FRESH=0

usage() {
  cat <<EOF
Usage: $0 [--iso PATH] [--fresh] [--boot-disk] [--disk-size N]

  --iso PATH      Arch ISO to boot (install mode). Defaults to the newest
                  archiso/out/*.iso if you built one; otherwise pass an
                  official Arch ISO.
  --fresh         Recreate the throwaway disk + UEFI vars from scratch.
  --boot-disk     Boot the installed disk instead of the ISO — use this AFTER
                  a successful install to verify the LUKS unlock + sway come up.
  --disk-size N   Disk image size (default $DISK_SIZE).

Env overrides: RAM (MB), CPUS, DISK_IMG, ISO
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --iso)        ISO="$2"; shift 2;;
    --fresh)      FRESH=1; shift;;
    --boot-disk)  MODE=boot-disk; shift;;
    --disk-size)  DISK_SIZE="$2"; shift 2;;
    -h|--help)    usage; exit 0;;
    *) echo "unknown arg: $1" >&2; usage; exit 1;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
find_first() { for f in "$@"; do [ -f "$f" ] && { printf '%s' "$f"; return 0; }; done; return 1; }

# --- Tooling ---------------------------------------------------------------
QEMU=qemu-system-x86_64
command -v "$QEMU"    >/dev/null || die "$QEMU not found. macOS: 'brew install qemu' · Arch: 'pacman -S qemu-full' · Debian: 'apt install qemu-system-x86'"
command -v qemu-img  >/dev/null || die "qemu-img not found (comes with qemu)"

# --- OVMF firmware (code = read-only, vars = per-VM writable copy) ----------
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
  Darwin)
    BREW="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
    OVMF_CODE="$(find_first "$BREW/share/qemu/edk2-x86_64-code.fd" /usr/local/share/qemu/edk2-x86_64-code.fd)" || true
    OVMF_VARS_TMPL="$(find_first "$BREW/share/qemu/edk2-i386-vars.fd" /usr/local/share/qemu/edk2-i386-vars.fd)" || true
    ;;
  Linux)
    OVMF_CODE="$(find_first \
      /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2/x64/OVMF_CODE.fd \
      /usr/share/OVMF/OVMF_CODE.4m.fd     /usr/share/OVMF/OVMF_CODE.fd \
      /usr/share/edk2-ovmf/x64/OVMF_CODE.fd)" || true
    OVMF_VARS_TMPL="$(find_first \
      /usr/share/edk2/x64/OVMF_VARS.4m.fd /usr/share/edk2/x64/OVMF_VARS.fd \
      /usr/share/OVMF/OVMF_VARS.4m.fd     /usr/share/OVMF/OVMF_VARS.fd \
      /usr/share/edk2-ovmf/x64/OVMF_VARS.fd)" || true
    ;;
  *) die "unsupported host OS: $OS";;
esac
[ -n "${OVMF_CODE:-}" ]      || die "OVMF firmware code not found — install 'edk2-ovmf' (Linux) or 'qemu' (macOS bundles it)"
[ -n "${OVMF_VARS_TMPL:-}" ] || die "OVMF vars template not found alongside the firmware"

# --- Acceleration ----------------------------------------------------------
ACCEL=tcg; CPUFLAG=max; WARN=""
case "$OS" in
  Darwin)
    if [ "$ARCH" = "x86_64" ]; then ACCEL=hvf; CPUFLAG=host
    else WARN="Apple Silicon host emulating x86_64 via TCG — it WILL be slow (no cross-arch hardware accel). Fine for a logic dry-run, just be patient."; fi
    ;;
  Linux)
    if [ "$ARCH" = "x86_64" ] && [ -w /dev/kvm ]; then ACCEL=kvm; CPUFLAG=host; fi
    ;;
esac

# --- Display: zoom-to-fit scales the guest to the window/fullscreen size ----
case "$OS" in
  Darwin) DISPLAY_OPT="cocoa,zoom-to-fit=on";;
  *)      DISPLAY_OPT="gtk,zoom-to-fit=on";;
esac

# --- Throwaway disk + UEFI vars --------------------------------------------
mkdir -p "$HERE/.vm"
if [ "$FRESH" = 1 ]; then rm -f "$DISK_IMG" "$VARS_IMG"; fi
[ -f "$DISK_IMG" ] || { echo ">> Creating $DISK_SIZE throwaway disk: $DISK_IMG"; qemu-img create -f qcow2 "$DISK_IMG" "$DISK_SIZE" >/dev/null; }
[ -f "$VARS_IMG" ] || cp "$OVMF_VARS_TMPL" "$VARS_IMG"

# --- ISO (install mode) ----------------------------------------------------
if [ "$MODE" = install ]; then
  if [ -z "$ISO" ]; then
    ISO="$(ls -t "$HERE"/archiso/out/*.iso 2>/dev/null | head -n1 || true)"
  fi
  [ -n "$ISO" ] && [ -f "$ISO" ] || die "no ISO. Pass --iso PATH (an official Arch ISO, or one built by archiso/build-iso.sh)"
fi

# --- Assemble QEMU command -------------------------------------------------
ARGS=(
  -name lemur-test
  -machine q35,accel="$ACCEL"
  -cpu "$CPUFLAG"
  -smp "$CPUS"
  -m "$RAM"
  # virtio-gpu, not std VGA: sway/wlroots needs a proper KMS driver; bochs-drm
  # (std) is flaky under wlroots, virtio-gpu is the supported path.
  -vga virtio
  -display "$DISPLAY_OPT"
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
  -drive if=pflash,format=raw,file="$VARS_IMG"
  -drive if=none,id=nvm,file="$DISK_IMG",format=qcow2
  -device nvme,serial=lemurtest,drive=nvm
  # hostfwd: `ssh -p 2222 <user>@localhost` from the host — the Cocoa display
  # has no clipboard sharing, so a real terminal is the usable path for pasting
  # keys/passwords during testing. Bound to 127.0.0.1 (host-only).
  -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22
)
if [ "$MODE" = install ]; then
  ARGS+=( -cdrom "$ISO" -boot order=d,menu=on )
else
  ARGS+=( -boot order=c,menu=on )
fi

# --- Summary + launch ------------------------------------------------------
echo "=================================================================="
echo " QEMU dry-run VM"
echo "   mode:   $MODE"
echo "   accel:  $ACCEL    cpu: $CPUFLAG    smp: $CPUS    ram: ${RAM}MB"
echo "   disk:   $DISK_IMG ($DISK_SIZE → emulated NVMe → /dev/nvme0n1)"
[ "$MODE" = install ] && echo "   iso:    $ISO"
[ -n "$WARN" ] && echo "   NOTE:   $WARN"
echo
if [ "$MODE" = install ]; then
  cat <<'EOF'
 In the guest (network DHCP is automatic on the virtio NIC):
   * The disk is /dev/nvme0n1 — matches install.sh's default, no override needed.
   * Custom ISO (archiso): scripts are already at /root — run ./install.sh
   * Official Arch ISO:    fetch the scripts first, then run ./install.sh
 When it finishes: power off the guest, then re-run with --boot-disk to verify
 the LUKS passphrase prompt, systemd-boot, and sway actually come up.
EOF
else
  echo " Booting the installed disk — you should get the LUKS passphrase prompt,"
  echo " then a TTY login. Log in and run 'WLR_RENDERER_ALLOW_SOFTWARE=1 sway'"
  echo " to confirm sway works (the env var is VM-only: no GPU in the guest)."
fi
echo "=================================================================="
echo
exec "$QEMU" "${ARGS[@]}"
