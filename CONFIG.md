# Configuration record — System76 Lemur Pro Arch install

Every meaningful Arch decision, its option space, and the selection baked into
this kit. **Legend:** **bold** = selected · *default* = Arch default not overridden ·
⏳ = consciously deferred/off.

> **Note on "decision #N" references:** the scripts and README cite decision
> numbers from the original planning discussion, which do **not** correspond to
> this file's section numbers. Treat them as opaque labels tying related
> choices together; this file is the authoritative record of what was decided.

## 1 · Firmware & boot
| Option | Choices | Selected |
|---|---|---|
| Boot mode | UEFI / BIOS-legacy | **UEFI** |
| Secure Boot | on / off | ⏳ **off** (likely unsupported on Open Firmware) |
| Bootloader | GRUB / systemd-boot / rEFInd / EFISTUB / Limine | **systemd-boot** |
| Boot timeout | seconds | **3s** |
| Console mode | auto / max / keep | **max** |
| Boot entries | — | **arch + arch-fallback + linux-lts (+ lts-fallback)** — resilience (decision #2/#6) |

## 2 · Disk & partitioning
| Option | Choices | Selected |
|---|---|---|
| Partition table | GPT / MBR | **GPT** |
| Tool | sgdisk / fdisk / parted | **sgdisk** |
| ESP size | — | **1 GiB** |
| Layout | — | **ESP + single LUKS partition** |

## 3 · Encryption
| Option | Choices | Selected |
|---|---|---|
| Scheme | none / LUKS / LUKS+LVM / LVM-on-LUKS | **LUKS, plain (no LVM)** |
| LUKS version | luks1 / luks2 | **luks2** |
| Cipher/KDF | — | *default* (aes-xts-plain64, argon2id) |
| `/boot` encryption | encrypted (GRUB) / plain ESP | **plain ESP (unencrypted)** |
| TPM2 auto-unlock | yes / no | ⏳ **no** (deferred) |
| TRIM / discard | continuous / batched / off | **batched** — LUKS opened `--allow-discards --persistent`, weekly `fstrim.timer` (decision #1) |

## 4 · Filesystem
| Option | Choices | Selected |
|---|---|---|
| Root FS | ext4 / btrfs / xfs / zfs / f2fs | **Btrfs** |
| Subvolumes | — | **@, @home, @log, @pkg, @snapshots** |
| Mount opts | — | **noatime,compress=zstd:1,ssd** (no continuous discard — weekly `fstrim.timer` instead, decision #1) |
| Compression | none / zstd / lzo / zlib | **zstd:1** |
| ESP FS | — | **FAT32** |

## 5 · Swap
| Option | Choices | Selected |
|---|---|---|
| Type | none / partition / swapfile / zram | **zram** |
| zram size | — | **½ RAM (12 GiB)** |
| zram compression | lzo / lz4 / zstd | **zstd** |
| `vm.swappiness` | 0–200 | **100** |
| `vm.page-cluster` | — | **0** |
| Hibernate | yes / no | ⏳ **no** (`enable-hibernate.sh` later) |

## 6 · Kernel & initramfs
| Option | Choices | Selected |
|---|---|---|
| Kernel | linux / linux-lts / linux-zen / linux-hardened | **linux** (primary) + **linux-lts** (lifeboat, decision #6) |
| Microcode | intel-ucode / amd-ucode | **intel-ucode** |
| Initramfs gen | mkinitcpio / dracut / booster | **mkinitcpio** |
| Hook style | busybox / systemd | **systemd** (`sd-encrypt`) |
| HOOKS | — | **base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck** |

## 7 · Locale & time
| Option | Choices | Selected |
|---|---|---|
| `LANG` | — | **en_US.UTF-8** |
| Console keymap | — | **us** |
| Timezone | — | **America/Puerto_Rico** |
| RTC | UTC / localtime | **UTC** |
| Time sync | none / timesyncd / chrony / ntpd | **systemd-timesyncd** |

## 8 · Identity & accounts
| Option | Choices | Selected |
|---|---|---|
| Hostname | — | **lemur** |
| Root account | enabled / locked | **enabled** — kept for emergency/`sulogin` rescue access, which matches the manual-recovery boot philosophy (decisions #2/#9) |
| Primary user | — | **`NEWUSER`** (default `user`; named to dodge zsh's special `USERNAME` parameter on archiso) |
| Groups | — | **wheel** |
| Shell | — | **/bin/bash** |
| Privilege escalation | sudo / doas | **sudo** (wheel) |

## 9 · Networking
| Option | Choices | Selected |
|---|---|---|
| Manager | NetworkManager / systemd-networkd / iwd / netctl | **NetworkManager** (+`iwd` installed) |
| WiFi backend | wpa_supplicant / iwd | **iwd** (NM backend via drop-in; more reliable on Intel — wpa_supplicant stays an unused NM dep) |
| DNS | NM-internal / resolved / openresolv | *NM-internal* (default) |
| Firewall | none / nftables / ufw / firewalld | **nftables**, default-drop inbound |
| Inbound services | — | **none opened** |

## 10 · Audio & graphics
| Option | Choices | Selected |
|---|---|---|
| Audio stack | PipeWire / PulseAudio / ALSA-only | **PipeWire** |
| Session mgr | wireplumber / media-session | **wireplumber** |
| PulseAudio compat | — | **pipewire-pulse** |
| GPU userspace | — | **mesa + vulkan-intel** |
| Display server | Xorg / Wayland | **Wayland** (sway/wlroots; KMS + mesa, no Xorg driver needed) |
| X11 app compat | — | **xorg-xwayland** |

## 11 · Desktop
| Option | Choices | Selected |
|---|---|---|
| WM/DE | — | **sway** (i3-compatible config; swaybg/swayidle installed) |
| Status bar | — | **swaybar + i3status** (swaybar consumes the i3status protocol) |
| Screen lock | — | **swaylock** |
| Launcher | — | **wmenu + rofi** (sway's default `$menu` is `wmenu-run`) |
| Terminal | — | **ghostty** (staged `~/.config/sway/config` sets `$term ghostty`) |
| Display manager | none / ly / lightdm / sddm / gdm | **none — type `sway`** at the TTY |
| Notifications | — | **mako + libnotify** (smartd/restic notifiers depend on `notify-send`) |
| Screen share | — | **xdg-desktop-portal-wlr** |
| Fonts | — | **ttf-dejavu, ttf-font-awesome** |
| Browser | — | **firefox** |

## 12 · Snapshots & rollback
| Option | Choices | Selected |
|---|---|---|
| Tool | none / snapper / timeshift / btrbk | **snapper + snap-pac** |
| `root` scope | — | **pacman pre/post, keep ~10, no timeline** |
| `home` scope | — | **daily timeline (7 daily / 4 weekly)** |
| Boot-menu rollback | grub-btrfs / manual | **manual** (systemd-boot, live-USB recovery) |
| `/boot` in snapshots | yes / no | **no** — ESP isn't a subvolume, so a snapper rollback does NOT restore the kernel; reinstall the matching kernel or boot `linux-lts` to repair (decision #9, see README) |

## 13 · Package management
| Option | Choices | Selected |
|---|---|---|
| multilib (32-bit) | on / off | ⏳ **off** (enable on demand) |
| AUR helper | none / yay / paru / aurutils | **paru** |
| Mirror tool | none / reflector / rate-mirrors | **reflector** (seed once, US/HTTPS/rate) |
| Mirror refresh timer | on / off | ⏳ **off** |
| pacman tweaks (Color, ParallelDownloads) | — | **Color + ParallelDownloads=5** (enabled) |

## 14 · Hardware / vendor (System76)
| Option | Choices | Selected |
|---|---|---|
| Power/fan/charge | none / TLP / system76-power | **system76-power** |
| EC/ACPI drivers | — | **system76-dkms, system76-acpi-dkms** (model-dependent — verify, decision #11) |
| DKMS kernel headers | — | **linux-headers + linux-lts-headers** (DKMS builds for both kernels; `dkms status` asserted — decision #11) |
| Firmware updates | — | **fwupd** |
| Firmware type | Open Firmware / AMI | **Open Firmware** (assumed) |

## 15 · Backups
| Option | Choices | Selected |
|---|---|---|
| Tool | none / restic / borg / btrbk / rsync | **restic** |
| Destination | local drive / cloud / NAS | **cloud-first — Backblaze B2** (private bucket, all prior versions kept; **no Object Lock** — see Retention; accessed via the **S3-compatible endpoint** — restic's native `b2:` backend trips B2's API-version gate on newer accounts, restic #5741) |
| Scope | /home+/etc / /home / full | **/home only** |
| Encryption | — | **client-side AES-256** (B2 stores ciphertext only; strength = repo-password entropy — 8-word CSPRNG diceware, decision #8) |
| Daily key rights | full / append-only | **append-only (no delete)** — a compromised host can't destroy offsite history; worst case is hiding files, recoverable while the bucket keeps prior versions (decision #4) |
| Schedule | — | **daily systemd timer** (Persistent, randomized) |
| Retention | — | **quarterly `restic-maintenance`** — `forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6` + `prune` + full `check`, using a full-rights key pasted from the password manager (never stored on the laptop). Object Lock rejected: per-object retention expires while restic packs stay referenced indefinitely, and it blocks `prune` (decision #4) |
| Repo locks | — | append-only key can't delete restic's per-run locks → lifecycle rule on the `<host>/home/locks/` prefix ONLY (hide 1 d → delete); monthly check runs `--no-lock`; `restic unlock` during maintenance |
| Monitoring | — | **login-time staleness notifier (`systemctl --user`) + monthly `restic check --no-lock` + maintenance-overdue nag (>120 d)** (decision #5/#10) |
| Recovery prereqs | — | **off-device password manager + printed emergency card** (decision #6) |
| Excludes | — | **/home/.snapshots (decision #2), caches, trash, node_modules/target/.venv, etc.** |
| Setup | — | run `setup-backups.sh` after creating the B2 bucket, both keys (daily append-only on-device · maintenance full-rights in the password manager), and the locks-prefix lifecycle rule |
| Local drive copy | yes / no | ⏳ **deferred** (2nd restic repo later — fast restores + a place for tiered count-based retention, decision #4) |

## 16 · Maintenance & verification
| Option | Choices | Selected |
|---|---|---|
| Boot stub updates | manual / auto | **`systemd-boot-update.service`** — keeps the ESP stub current (decision #10) |
| TRIM | continuous / weekly / off | **weekly `fstrim.timer`** (decision #1) |
| Btrfs scrub | none / scheduled | **monthly `btrfs-scrub@-.timer`** — surfaces bit-rot (decision #10) |
| Backup integrity | none / scheduled | **monthly `restic check`** (decision #10) |
| Disk health | none / smartd | **`smartd`** on the NVMe + login-time desktop SMART alerts (decision #10) |
| Real-hardware acceptance | — | **post-install checklist** — DKMS/hibernate/WiFi/backlight/power (decision #12, see README) |

## Threat model (explicit)
In scope: **opportunistic theft** (device stolen, never returned) and a **B2 data
breach** exposing encrypted backups for future ("harvest-now-decrypt-later")
decryption. FDE covers theft-at-rest; client-side AES-256 + a high-entropy repo
password covers the breach (decision #7/#8). Ransomware on the laptop is
covered by the append-only daily B2 key (can't delete history). A stolen B2
*account* login could still destroy history — mitigated by credential hygiene
(unique password + 2FA, stored off-device), not Object Lock, whose per-object
retention would expire while restic packs stay live. **Out of scope:** targeted
physical tamper (evil-maid), network adversaries, nation-state. Several
deferrals below follow directly from this scope.

## Consciously not configured
| Thing | Status | Why |
|---|---|---|
| Hibernate | ⏳ deferred | zram covers daily; `enable-hibernate.sh` when wanted |
| Secure Boot / TPM2 | ⏳ off | low threat; likely unsupported firmware |
| Evil-maid / physical tamper | ❌ out of scope | threat model is theft + B2-breach only; FDE protects theft-at-rest, not tamper-then-return (decision #7) |
| Encrypted DNS (DoT/DoH) | ❌ out of scope | plaintext DNS; network adversaries aren't in the threat model (decision #7) |
| multilib | ⏳ off | not gaming on the iGPU; 2-line flip later |
| Mirror auto-refresh | ⏳ off | seeded once is enough |
| Kernel hardening / AppArmor | ❌ none | stock `linux`; not in scope |
