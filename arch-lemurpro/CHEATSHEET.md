# Cheatsheet — daily operations

Owner's manual for the installed system (`blitzen`-style setup: LUKS2 + Btrfs +
UKIs + Secure Boot + sway). Companion to `README.md` (installing) and
`CONFIG.md` (why things are the way they are).

## Boot & login

Power on → systemd-boot menu (auto-continues) → **LUKS passphrase** → TTY login
→ type `sway`.

Boot menu picks, when you need them:
- **Arch Linux** — daily driver (`linux` kernel UKI). The default.
- **fallback** entries — same kernel, initramfs with every module; pick when a
  boot fails right after an update ("can't find disk"-style failures).
- **linux-lts** — independent older kernel; pick when a `linux` update itself
  is broken (graphics, WiFi, panic). Fully functional lifeboat — DKMS modules
  are built for it too.

## Sway quick reference

`Mod` = Super/Windows key. Caps Lock is **Ctrl** (everywhere, including the
LUKS prompt and TTY).

| Keys | Action |
|---|---|
| `Mod+Enter` | terminal (ghostty) |
| `Mod+d` | launcher — type an app name |
| `Mod+Shift+Q` | close window |
| `Mod+1`…`9` (and `Ctrl+1`…`5` if configured) | switch workspace |
| `Mod+Shift+1`…`9` | move window to workspace |
| `Mod+arrows` / `Mod+h j k l` | move focus |
| `Mod+Escape` | lock screen (if configured) |
| `Mod+Shift+C` | reload sway config (`exec` lines need a re-login) |
| `Mod+Shift+E` | exit sway → back to TTY |

Config lives in `~/.config/sway/config`; bar modules in
`~/.config/i3status/config` (test edits by running `i3status` in a terminal).
Wallpaper: `output * bg <path> fill`. Locking on lid close comes from the
`swayidle … before-sleep` line.

## WiFi & network

NetworkManager owns networking (the live-ISO `iwctl` does not exist here).

```bash
nmtui                                           # menu: activate/edit connections
nmcli device wifi list                          # scan
nmcli device wifi connect "SSID" password 'pw'  # join new network
nmcli connection up "SSID"                      # switch to a known network
```

Known networks auto-reconnect. Firewall is nftables, default-drop inbound —
nothing listens; if you ever open a port temporarily, prefer a transient
`nft insert rule …` over editing `/etc/nftables.conf`.

## USB drives

udisks2 handles removable media — no sudo needed (polkit grants it to the
seated user), no automount daemon.

```bash
lsblk -f                          # find the stick (e.g. sda1) after plugging in
udisksctl mount -b /dev/sda1      # mounts at /run/media/$USER/<label>
udisksctl unmount -b /dev/sda1    # always unmount before pulling the stick
```

FAT32/exFAT work out of the box; NTFS mounts read/write via the kernel
`ntfs3` driver. Formatting or fsck of exFAT/NTFS needs `exfatprogs`/`ntfs-3g`
(not installed).

## Updating

```bash
sudo pacman -Syu
```

Weekly is a good cadence. Read the output; if something needs manual steps,
it's announced there and at archlinux.org news. AUR packages
(`system76-power` etc.): `paru -Syu` covers repo + AUR together.

What happens automatically on kernel/boot updates (pacman hooks):
1. mkinitcpio rebuilds all four UKIs,
2. sbctl re-signs them (and the systemd-boot source binary),
3. snap-pac takes pre/post snapshots of `@`.

**After updating, before you forget:** if the update touched a kernel, a
reboot gets you onto it; no urgency, but don't accumulate months of distance
between running and installed kernels.

## ⚠️ Secure Boot rules (the ones that can cost you a boot)

1. **Any manual `mkinitcpio -P` leaves the UKIs UNSIGNED** (pacman's signing
   hook only runs on pacman transactions). Always follow with:
   ```bash
   sudo sbctl sign-all && sudo sbctl verify
   ```
   (`vmlinuz-*` showing unsigned is normal — they're ingredients, not boot
   targets. Anything else unsigned: fix before rebooting.)
2. Kernel cmdline changes go in `/etc/kernel/cmdline`, then `mkinitcpio -P`,
   then rule 1. There are no loader entry files to edit.
3. If the machine ever refuses to boot with a Secure Boot error: firmware
   setup (`Esc` at power-on) → Secure Boot Configuration → disable → boot →
   `sudo sbctl verify` → sign what's missing → re-enable. Nothing is lost.

## Snapshots & rollback (snapper)

```bash
sudo snapper -c root list                 # system snapshots (pacman pre/post)
sudo snapper -c home list                 # daily /home timeline
sudo snapper -c root status <n1>..<n2>    # what changed between two
sudo snapper -c root undochange <n1>..<n2> <path>   # restore one file/dir
```

Bad update, userspace: boot still works → `undochange` or full rollback per
the snapper docs. Bad update, **kernel**: the ESP isn't snapshotted — boot the
**linux-lts** menu entry, then reinstall the wanted kernel version (hooks
rebuild + re-sign UKIs). Snapshots are on the same disk — they are not
backups.

## Backups (restic → B2)

Runs daily via `restic-backup.timer`; `/home` only; client-side encrypted;
the on-disk key **cannot delete** history (append-only by design).

```bash
systemctl list-timers | grep restic                  # timers armed?
ls -l /var/lib/restic-backup/                        # last-success / last-failure stamps
journalctl -u restic-backup -n 20                    # last run's log
sudo systemctl start restic-backup.service           # force a run now
```

A lock-cleanup error at the end of a run is **expected** (append-only key);
success = fresh `last-success` stamp. The staleness notifier nags on login if
backups go quiet >36h.

**Restore** (do a small test restore occasionally — an unrestored backup is a
hypothesis, not a backup):
```bash
set -a; . /etc/restic/b2.env; set +a
restic snapshots --no-lock                            # list what exists
restic restore latest --target /tmp/restore --include /home/crosario/some/path
```

**Quarterly ritual** (calendar it): `sudo restic-maintenance` — paste the
full-rights key from the password manager. Runs unlock → forget (7d/4w/6m) →
prune → full check. Never store that key on this machine.

The repo password has **no reset**. It lives in the password manager and on
the printed card. Protect both.

## Hibernate

`systemctl hibernate` — full power-off, session resumes after the LUKS prompt.
zram handles everyday swap; the disk swapfile exists mainly for the hibernate
image. Lid close = suspend (not hibernate) by default.

## Health & noise triage

- **Fans roaring**: `ps aux --sort=-%cpu | head` first. Usual suspects:
  restic backup running, monthly `btrfs scrub`, an AUR compile. Idle-but-loud:
  `system76-power profile balanced`.
- **SMART alerts** arrive as desktop notifications (timer:
  `smartd-alert-check.timer` — enable once per user session setup).
- **Scary dmesg lines**: a log line is only a problem if a capability you use
  is broken. Known-benign on this machine: `GSC proxy … timeout` (Intel
  HDCP/media path), missing `qat_*` firmware notes.
- Journals: `journalctl -b` (this boot), `journalctl -b -1 -p err` (last
  boot's errors).

## Recovery cheatsheet (worst days)

- **Boot fails after update** → menu-pick fallback or linux-lts (see Boot).
- **Secure Boot refuses everything** → disable SB in firmware, boot, re-sign
  (see Secure Boot rules).
- **Machine won't boot at all** → Arch USB stick (disable SB first to boot
  it), then:
  ```bash
  cryptsetup open /dev/nvme0n1p2 cryptroot
  mount -o subvol=@ /dev/mapper/cryptroot /mnt
  mount /dev/nvme0n1p1 /mnt/boot
  arch-chroot /mnt
  ```
  …and repair from there.
- **Disk died** → new disk, reinstall from the kit, `restic restore` /home
  from B2. This is the day the repo password card pays for itself.

## Where things live

| Thing | Path |
|---|---|
| Kernel cmdline | `/etc/kernel/cmdline` |
| UKIs | `/boot/EFI/Linux/*.efi` |
| mkinitcpio presets | `/etc/mkinitcpio.d/*.preset` |
| Secure Boot keys | `/var/lib/sbctl/` |
| restic env + password | `/etc/restic/` (root-only) |
| Backup stamps | `/var/lib/restic-backup/` |
| Firewall | `/etc/nftables.conf` |
| Console keymap | `/etc/vconsole.conf` (+ custom map in `/usr/local/share/kbd/keymaps/`) |
| sway / i3status config | `~/.config/sway/config`, `~/.config/i3status/config` |
| Snapper configs | `/etc/snapper/configs/{root,home}` |
