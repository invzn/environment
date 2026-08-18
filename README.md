# Arch Linux installer kit — System76 Lemur Pro

Automated, reproducible Arch install for a Lemur Pro: **LUKS2 full-disk encryption +
Btrfs + systemd-boot + sway (Wayland)**, plus System76 power/DKMS tooling. See
[`../arch-system76-install.md`](../arch-system76-install.md) for the manual walkthrough
this kit automates.

> ⚠️ **`install.sh` erases the target disk.** It guards on UEFI + a typed-disk
> confirmation, but there is no undo. The LUKS passphrase and account passwords are
> prompted interactively — never hardcoded.

## Files

| File | Runs | Purpose |
|------|------|---------|
| `install.sh` | live ISO, as root | Seed mirrors, partition, encrypt, Btrfs, pacstrap, then call `chroot-setup.sh` |
| `chroot-setup.sh` | inside `arch-chroot` (called by `install.sh`) | Locale, users, initramfs, bootloader, sway, zram, firewall, snapshots, time sync |
| `post-install.sh` | first boot, as your user | AUR helper + `system76-power`/DKMS + firmware updates |
| `setup-secureboot.sh` | later, as root (optional) | Secure Boot: sbctl keys, enroll, sign the UKI boot chain |
| `enable-hibernate.sh` | later, as root (optional) | Adds a NOCOW Btrfs swapfile + resume plumbing for hibernate |
| `setup-backups.sh` | later, as root | restic → B2 daily backups + staleness notifier + quarterly `restic-maintenance` |
| `test-vm.sh` | your dev machine (macOS/Linux) | Dry-run the installer in a throwaway UEFI QEMU VM |
| `archiso/build-iso.sh` | an Arch box with `archiso` | Bundles the scripts into a bootable `.iso` |
| `archiso/extra-packages.x86_64` | — | Packages added to the *live* installer image |

## Verify in a VM before touching the laptop (recommended)

`test-vm.sh` boots a throwaway **UEFI** QEMU guest with the disk presented as
**NVMe** (so it shows up as `/dev/nvme0n1` and the installer runs with its
defaults), with NAT networking so `pacstrap` reaches the mirrors.

```bash
# 1. install qemu  (macOS: brew install qemu · Arch: pacman -S qemu-full)
# 2. dry-run the installer against the official Arch ISO (or your built one):
./test-vm.sh --iso /path/to/archlinux.iso
#    inside the guest: run ./install.sh  (disk is /dev/nvme0n1, no override needed)
# 3. after it finishes, power off and verify the REAL boot path:
./test-vm.sh --boot-disk        # expect: LUKS prompt → TTY login → sway
#    (no GPU in the VM: launch with  WLR_RENDERER_ALLOW_SOFTWARE=1 sway)
```

Throwaway artifacts (disk image, UEFI vars) live in `./.vm/`; `--fresh` recreates
them. The disk image is sparse — a 40G image only consumes the few GB actually used.

> **Apple Silicon note:** an arm64 Mac has no hardware acceleration for an x86_64
> guest, so the VM runs under **TCG emulation — slow but correct**. It faithfully
> verifies the installer's *logic* (partitioning, LUKS, Btrfs, snapper, boot), which
> is the whole point of the dry-run; it just won't be fast. An Intel Mac or Linux box
> with KVM runs it at near-native speed.

## Real-hardware acceptance checklist (the VM can't cover this)

The VM dry-run validates the **generic-Arch** layer (partition → LUKS → Btrfs →
snapper → boot). It **cannot** test the **Lemur-Pro-specific** layer — there's no
System76 EC, no real firmware/S4, no i915, and it runs on wired NAT, not WiFi. A
green VM run says nothing about the items below, which are exactly the ones most
likely to break (decision #12). Run these **on the laptop** after first boot +
`post-install.sh`:

- [ ] **DKMS modules built** — `dkms status` shows `system76-*` `installed`
      against **both** `linux` and `linux-lts` (decision #11). A silent
      missing-headers failure means no EC fan/charge control.
- [ ] **WiFi associates** — `nmtui` / `nmcli device wifi connect …` (VM used wired).
- [ ] **Backlight** — `brightnessctl set 50%` actually changes panel brightness.
- [ ] **Graphics** — `sway` on the real i915 (resolution, no tearing);
      external display via the USB-C/HDMI port if you use one.
- [ ] **Suspend/resume** — `systemctl suspend`, lid close/open.
- [ ] **Hibernate** (only after `enable-hibernate.sh`) — `systemctl hibernate`
      then resume cleanly.
- [ ] **Power/charge** — `system76-power charge-thresholds`, fan behaviour sane.
- [ ] **Firmware** — `fwupdmgr get-updates`.
- [ ] **Secure Boot** (optional, after `setup-secureboot.sh` + firmware toggle) —
      `bootctl status` says `Secure Boot: enabled (user)`; then confirm a
      `pacman -Syu` that touches the kernel leaves `sbctl verify` green.
- [ ] **Backups** — `systemctl --user enable --now restic-staleness-check.timer`,
      run the first `restic-backup`, confirm a snapshot lands in B2 (a final
      lock-cleanup error is expected with the append-only key — success is the
      fresh `last-success` stamp), then `systemctl start restic-check.service`
      to confirm `check --no-lock` works.
- [ ] **SMART alerts** — `systemctl --user enable --now smartd-alert-check.timer`
      (desktop notification for disk warnings; root smartd can't notify your session).

## Configured options (decided, baked in)

| Area | Choice |
|------|--------|
| Kernel | **`linux` + `linux-lts` lifeboat**, four **UKIs** (each kernel × normal/fallback initramfs) — bad updates are a boot-menu pick |
| Swap | **zram** (½ RAM, zstd); hibernate deferred to `enable-hibernate.sh` |
| Snapshots | **snapper + snap-pac** — pacman pre/post on `@`, daily timeline on `@home` (`/boot` excluded — see kernel-rollback note) |
| Backups | **restic → B2**, append-only daily key; retention = quarterly `restic-maintenance` (full-rights key kept off-device); staleness notifier + monthly `restic check --no-lock` |
| Firewall | **nftables**, default-drop inbound, nothing opened |
| TRIM | **weekly `fstrim.timer`** (LUKS `--allow-discards`), no continuous discard |
| Maintenance | **`systemd-boot-update`, `fstrim`, monthly `btrfs scrub`, `smartd`** enabled |
| Multilib | **off** (uncomment in `pacman.conf` on demand) |
| Time sync | **systemd-timesyncd** enabled |
| Mirrors | **reflector** seeded once (US/HTTPS/by-rate), no timer |
| Secure Boot | **opt-in via `setup-secureboot.sh`** (sbctl custom keys + MS vendor certs, signed UKIs; verified working on this firmware). Requires firmware Setup Mode; supervisor password recommended |

## Route A — run the scripts on the stock Arch ISO (simplest)

1. Boot the official Arch ISO, get online (`iwctl` / `nmcli`).
2. Fetch this `arch-lemurpro/` directory (git clone, `curl`, or USB) so the
   scripts sit together.
3. **Review and edit the CONFIG block** at the top of `install.sh` — at minimum
   `DISK`, `NEWHOST`, `NEWUSER`, `TIMEZONE`. Or override via env:
   ```bash
   DISK=/dev/nvme0n1 NEWUSER=chris TIMEZONE=America/Puerto_Rico ./install.sh
   ```
   (`NEWUSER`, not `USERNAME` — zsh, the archiso shell, reserves `USERNAME` as a
   special parameter and the value silently arrives as `root`.)
4. Run it, follow the passphrase/password prompts, then `umount -R /mnt && reboot`.
5. Log in as your user and run `~/post-install.sh`.

## Route B — build a custom ISO with the scripts baked in

On any Arch machine:
```bash
sudo pacman -S archiso
cd arch-lemurpro/archiso
sudo ./build-iso.sh                 # ISO lands in ./out/
sudo dd if=out/archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
Boot that ISO — the login `motd` reminds you to run `/root/install.sh`. Same install
flow as Route A, but the scripts and tooling are already on the media (good for
offline installs or reusing across machines).

## Design notes / honest limits

- **What can't be "in the image":** LUKS formatting and disk partitioning happen at
  install time against the real disk, so they're scripted, not pre-baked. A custom ISO
  bundles the *automation*, not an encrypted disk image.
- **Why System76 packages are post-boot:** they're AUR (`system76-power`,
  `system76-dkms`) — network pulls + DKMS compiles — so they don't belong in the ISO or
  the chroot. `post-install.sh` handles them on the real system.
- **`/boot` is unencrypted** (FAT32 ESP holding the UKIs). Standard laptop tradeoff —
  and the reason the kit boots **UKIs**: with `setup-secureboot.sh`, the kernel,
  initramfs, and cmdline are one signed artifact, so ESP tampering (the evil-maid
  initramfs swap) fails signature validation instead of silently booting. Without
  Secure Boot enabled, UKIs cost nothing and simplify the ESP. The `sd-encrypt`
  initramfs leaves room to add TPM2 auto-unlock later:
  `systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2` (best after Secure Boot,
  so PCR 7 measurements are meaningful).
- **Snapshots are not backups:** snapper protects against bad updates and fat-fingered
  deletes, but the snapshots live on the same LUKS volume — not safe against disk death
  or theft. Add real off-device backups separately.
- **Kernel rollback is partial — `/boot` is not in the snapshots.** The ESP is
  FAT32, not a Btrfs subvolume, so a `snapper rollback` restores `/usr/lib/modules`
  (on `@`) but **not** the UKIs on `/boot`. After rolling back a transaction that
  bumped the kernel, the running kernel and the restored modules mismatch. Fix:
  reinstall the matching kernel version (`pacman -S linux` at the restored
  version — the pacman hooks rebuild and re-sign the UKIs), **or** boot the
  `linux-lts` entry —
  an independent, self-consistent kernel — to get a shell and repair from there
  (decision #9). So snap-pac protects *userspace* updates fully; *kernel* rollbacks
  need this extra step.
- **Boot resilience without GRUB:** two kernels (`linux` + `linux-lts`) and a
  fallback-initramfs UKI for each mean a bad `linux`/initramfs update is a
  boot-menu arrow-key away from recovery, not a live-USB rescue (decision #6).
  Only a *disk/FS-level* catastrophe (can't mount `@`) still needs a live USB —
  unavoidable with any bootloader. Accepted tradeoff for a clean boot stack
  (decision #2).
- **Hibernate is opt-in:** zram covers everyday swap; run `enable-hibernate.sh` if/when
  you want suspend-to-disk (decision #1).
