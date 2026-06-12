# Arch Linux installer kit — System76 Lemur Pro

Automated, reproducible Arch install for a Lemur Pro: **LUKS2 full-disk encryption +
Btrfs + systemd-boot + i3 (X11)**, plus System76 power/DKMS tooling. See
[`../arch-system76-install.md`](../arch-system76-install.md) for the manual walkthrough
this kit automates.

> ⚠️ **`install.sh` erases the target disk.** It guards on UEFI + a typed-disk
> confirmation, but there is no undo. The LUKS passphrase and account passwords are
> prompted interactively — never hardcoded.

## Files

| File | Runs | Purpose |
|------|------|---------|
| `install.sh` | live ISO, as root | Seed mirrors, partition, encrypt, Btrfs, pacstrap, then call `chroot-setup.sh` |
| `chroot-setup.sh` | inside `arch-chroot` (called by `install.sh`) | Locale, users, initramfs, bootloader, i3, zram, firewall, snapshots, time sync |
| `post-install.sh` | first boot, as your user | AUR helper + `system76-power`/DKMS + firmware updates |
| `enable-hibernate.sh` | later, as root (optional) | Adds a NOCOW Btrfs swapfile + resume plumbing for hibernate |
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
./test-vm.sh --boot-disk        # expect: LUKS prompt → TTY login → startx → i3
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
- [ ] **Graphics** — `startx` → i3 on the real i915 (resolution, no tearing);
      external display via the USB-C/HDMI port if you use one.
- [ ] **Suspend/resume** — `systemctl suspend`, lid close/open.
- [ ] **Hibernate** (only after `enable-hibernate.sh`) — `systemctl hibernate`
      then resume cleanly.
- [ ] **Power/charge** — `system76-power charge-thresholds`, fan behaviour sane.
- [ ] **Firmware** — `fwupdmgr get-updates`.
- [ ] **Backups** — `systemctl --user enable --now restic-staleness-check.timer`,
      run the first `restic-backup`, confirm a snapshot lands in B2.
- [ ] **SMART alerts** — `systemctl --user enable --now smartd-alert-check.timer`
      (desktop notification for disk warnings; root smartd can't notify your session).

## Configured options (decided, baked in)

| Area | Choice |
|------|--------|
| Kernel | **`linux` + `linux-lts` lifeboat**, fallback-initramfs entries — bad updates are a boot-menu pick |
| Swap | **zram** (½ RAM, zstd); hibernate deferred to `enable-hibernate.sh` |
| Snapshots | **snapper + snap-pac** — pacman pre/post on `@`, daily timeline on `@home` (`/boot` excluded — see kernel-rollback note) |
| Backups | **restic → B2**, append-only key + Object Lock, login-staleness notifier + monthly `restic check` |
| Firewall | **nftables**, default-drop inbound, nothing opened |
| TRIM | **weekly `fstrim.timer`** (LUKS `--allow-discards`), no continuous discard |
| Maintenance | **`systemd-boot-update`, `fstrim`, monthly `btrfs scrub`, `smartd`** enabled |
| Multilib | **off** (uncomment in `pacman.conf` on demand) |
| Time sync | **systemd-timesyncd** enabled |
| Mirrors | **reflector** seeded once (US/HTTPS/by-rate), no timer |
| Secure Boot | **skipped** (likely unsupported on System76 Open Firmware anyway) |

## Route A — run the scripts on the stock Arch ISO (simplest)

1. Boot the official Arch ISO, get online (`iwctl` / `nmcli`).
2. Fetch this `arch-lemurpro/` directory (git clone, `curl`, or USB) so the three
   scripts sit together.
3. **Review and edit the CONFIG block** at the top of `install.sh` — at minimum
   `DISK`, `NEWHOST`, `USERNAME`, `TIMEZONE`. Or override via env:
   ```bash
   DISK=/dev/nvme0n1 USERNAME=chris TIMEZONE=America/Puerto_Rico ./install.sh
   ```
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
- **`/boot` is unencrypted** (FAT32 ESP holding the kernel/initramfs). Standard laptop
  tradeoff. The `sd-encrypt` initramfs leaves room to add TPM2 auto-unlock later:
  `systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2`. Secure Boot was deliberately
  skipped (decision #7) — likely unsupported on System76 Open Firmware regardless.
- **Snapshots are not backups:** snapper protects against bad updates and fat-fingered
  deletes, but the snapshots live on the same LUKS volume — not safe against disk death
  or theft. Add real off-device backups separately.
- **Kernel rollback is partial — `/boot` is not in the snapshots.** The ESP is
  FAT32, not a Btrfs subvolume, so a `snapper rollback` restores `/usr/lib/modules`
  (on `@`) but **not** the kernel image/initramfs on `/boot`. After rolling back a
  transaction that bumped the kernel, the running `vmlinuz` and the restored modules
  mismatch. Fix: reinstall the matching kernel version (`pacman -S linux` at the
  restored version, which rewrites the ESP), **or** boot the `linux-lts` entry —
  an independent, self-consistent kernel — to get a shell and repair from there
  (decision #9). So snap-pac protects *userspace* updates fully; *kernel* rollbacks
  need this extra step.
- **Boot resilience without GRUB:** two kernels (`linux` + `linux-lts`) and a
  fallback-initramfs entry for each mean a bad `linux`/initramfs update is a
  boot-menu arrow-key away from recovery, not a live-USB rescue (decision #6).
  Only a *disk/FS-level* catastrophe (can't mount `@`) still needs a live USB —
  unavoidable with any bootloader. Accepted tradeoff for a clean boot stack
  (decision #2).
- **Hibernate is opt-in:** zram covers everyday swap; run `enable-hibernate.sh` if/when
  you want suspend-to-disk (decision #1).
