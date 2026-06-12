#!/usr/bin/env bash
#
# Post-install, run AFTER the first boot as your normal (non-root) user.
# Installs an AUR helper + System76 tooling and firmware updates (Phase 6).
#
# Why not in the ISO/chroot? The System76 packages live in the AUR — they pull
# from the network and compile via DKMS, so they belong on the real system.
#
set -euo pipefail

[ "$(id -u)" -ne 0 ] || { echo "run as your normal user, NOT root"; exit 1; }
command -v sudo >/dev/null || { echo "sudo not found"; exit 1; }

echo ">> Toolchain + kernel headers + fwupd"
# linux-headers AND linux-lts-headers are REQUIRED for the System76 DKMS modules
# (decision #11): DKMS compiles against each kernel's headers at install time AND
# on every kernel upgrade. Without them the build fails SILENTLY and the EC fan/
# charge driver never loads. Both kernels get headers so the linux-lts lifeboat
# (decision #6) isn't thermally blind.
sudo pacman -S --needed --noconfirm base-devel git fwupd linux-headers linux-lts-headers

# --- paru (AUR helper) -----------------------------------------------------
if ! command -v paru >/dev/null; then
  echo ">> Building paru from the AUR"
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  ( cd "$tmp/paru" && makepkg -si --noconfirm )
  rm -rf "$tmp"
fi

# --- System76 power + EC/ACPI drivers --------------------------------------
# (#11B) system76-power is a userspace daemon; the DKMS packages add the EC/ACPI
# kernel modules — which not every Lemur Pro model needs. Surface the model so
# you can confirm against System76 docs before relying on the DKMS modules.
model="$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo unknown)"
echo ">> Detected System76 model: $model"
echo ">>   (verify whether system76-dkms/system76-acpi-dkms apply to this model)"

echo ">> System76 power management + DKMS drivers"
paru -S --needed --noconfirm system76-power system76-dkms system76-acpi-dkms
sudo systemctl enable --now system76-power

# Assert the DKMS modules actually BUILT — a missing-headers failure is silent
# (decision #11). dkms status should list each module as 'installed'.
echo ">> Verifying DKMS modules built against installed kernels:"
sudo dkms status
if ! sudo dkms status | grep -qiE 'system76.*installed'; then
  echo "WARNING: system76 DKMS modules are NOT 'installed' — EC fan/charge control" >&2
  echo "         is likely broken. Ensure linux-headers + linux-lts-headers are"  >&2
  echo "         present, then: sudo dkms autoinstall && reboot"                    >&2
fi

# --- Firmware updates (Open Firmware models) -------------------------------
echo ">> Checking firmware updates (fwupd)"
fwupdmgr refresh || true
fwupdmgr get-updates || true

echo
echo "Done. Reboot recommended so the System76 DKMS modules load cleanly."
echo "Tip: 'system76-power charge-thresholds' and bind brightnessctl to i3 keys."
