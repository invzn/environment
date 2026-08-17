#!/usr/bin/env bash
#
# Enroll your own Secure Boot keys and sign the whole boot chain (sbctl).
#
# Run AFTER the system is installed, booted, and proven — this is a hardening
# step, not an install step. Prerequisites:
#   1. The install used the kit's UKI layout (chroot-setup.sh does this).
#   2. The firmware is in Secure Boot SETUP MODE: firmware setup screen →
#      Secure Boot Configuration → clear/delete existing keys if needed.
#      Do NOT enable Secure Boot yet — that's the LAST step, after signing.
#
# What it does (idempotent — safe to re-run):
#   * installs sbctl, creates a platform keypair (once)
#   * enrolls your key + Microsoft's vendor certs (-m: some hardware's own
#     option ROMs are signed by the MS third-party CA; enrolling without it
#     can brick boot before the bootloader ever runs)
#   * signs the SOURCE systemd-boot binary in /usr/lib — this is load-bearing:
#     the kit enables systemd-boot-update.service, which silently redeploys
#     the bootloader to the ESP at boot after systemd updates. If only the ESP
#     copies were signed, that redeploy would replace them with UNSIGNED
#     binaries and the next reboot would fail Secure Boot validation.
#     (Learned the hard way. The same applies to any manual `bootctl install`:
#     with the source signed, what it copies is already signed.)
#   * signs both ESP bootloader copies and every UKI, then verifies
#   * tells you how to flip the firmware toggle — it cannot do that for you
#
# Signing stays automatic afterward: sbctl's pacman hook re-signs everything
# in its database on every transaction (runs after mkinitcpio rebuilds UKIs).
# The one gap: rebuilding UKIs OUTSIDE pacman (a manual `mkinitcpio -P`, e.g.
# after editing /etc/kernel/cmdline) does NOT trigger the hook — follow any
# manual rebuild with:  sudo sbctl sign-all && sudo sbctl verify
#
# Recovery if the machine ever refuses to boot after this: firmware setup →
# Secure Boot Configuration → disable ("Attempt Secure Boot" off) → boot
# normally → fix signatures (sbctl verify / sign-all) → re-enable.
#
# Run as root on the installed system:  sudo ./setup-secureboot.sh
#
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"

SD_SRC="/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
ESP_BOOT=(/boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI)

[ -d /sys/firmware/efi ] || die "not a UEFI boot — Secure Boot needs UEFI"
ls /boot/EFI/Linux/*.efi >/dev/null 2>&1 \
  || die "no UKIs in /boot/EFI/Linux — this script requires the kit's UKI layout"

sb_state="$(bootctl status 2>/dev/null | grep -i 'Secure Boot:' || true)"
echo ">> Current state: ${sb_state:-unknown}"

if echo "$sb_state" | grep -q 'enabled'; then
  echo ">> Secure Boot is already enabled — verifying signatures only."
else
  echo "$sb_state" | grep -qi 'setup' \
    || die "firmware is not in Setup Mode — enter firmware setup and clear/reset Secure Boot keys first"
fi

pacman -S --needed --noconfirm sbctl

# --- Keys (create once, enroll once) ---------------------------------------
# Key existence on disk is the reliable check (`sbctl status` wording varies
# by version). Path moved across sbctl releases; accept either.
if [ ! -d /var/lib/sbctl/keys ] && [ ! -d /usr/share/secureboot/keys ]; then
  echo ">> Creating Secure Boot platform keys"
  sbctl create-keys
fi
if echo "$sb_state" | grep -qi 'setup'; then
  echo ">> Enrolling keys (+ Microsoft vendor certs)"
  sbctl enroll-keys -m
fi

# --- Sign: source bootloader, ESP copies, every UKI ------------------------
echo ">> Signing boot chain"
sbctl sign -s "$SD_SRC"
# Deploy the now-signed source to both ESP locations (also refreshes the
# 'Linux Boot Manager' NVRAM entry).
bootctl install
for f in "${ESP_BOOT[@]}"; do sbctl sign -s "$f"; done
for u in /boot/EFI/Linux/*.efi; do sbctl sign -s "$u"; done

# --- Verify: EVERYTHING the boot chain touches must be signed --------------
echo ">> Verifying"
verify_out="$(sbctl verify 2>&1 || true)"
printf '%s\n' "$verify_out"
# Raw /boot/vmlinuz-* kernels are UKI ingredients, never booted directly —
# unsigned is their correct state. Anything ELSE unsigned is a stop-ship.
if printf '%s\n' "$verify_out" | grep -Ei 'is not signed' | grep -qv 'vmlinuz'; then
  die "unsigned boot-chain files remain (see above) — do NOT enable Secure Boot yet"
fi

echo
echo "All signed. Final steps (manual, in this order):"
echo "  1. systemctl reboot --firmware-setup"
echo "  2. Secure Boot Configuration → enable ('Attempt Secure Boot') → save"
echo "  3. After boot:  bootctl status | grep 'Secure Boot'   → 'enabled (user)'"
echo
echo "Consider also setting a firmware supervisor password — without one,"
echo "anyone at the keyboard can simply disable Secure Boot again."
