# Arch Linux on System76 Lemur Pro

A step-by-step install guide for a System76 **Lemur Pro** (Intel iGPU, **no NVIDIA**)
with **LUKS2 full-disk encryption**, a **Btrfs** snapshot-friendly layout, **systemd-boot**,
and a **sway (Wayland)** desktop.

## Hardware notes

- The Lemur Pro is **Intel** — microcode is `intel-ucode`, GPU userspace is `mesa` +
  `vulkan-intel`. These are baked into the commands below.
- The Lemur Pro ships **System76 Open Firmware (coreboot)**. In its setup menu, ensure
  **UEFI** mode. Leave Secure Boot **disabled** unless you specifically need it (Arch
  supports it, but it's extra setup).
- `/boot` is left **unencrypted** in this layout (standard tradeoff — exposes boot binaries,
  not your data). See "Caveats" for the GRUB-encrypted-`/boot` alternative.

---

## Phase 0 — Prep the installer

1. Download the Arch ISO + signature from archlinux.org, verify, and write to USB:
   ```bash
   gpg --keyserver-options auto-key-retrieve --verify archlinux-*.iso.sig
   sudo dd if=archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
2. Boot the USB (`F7`/`Esc` for the boot menu on System76; pick the UEFI USB entry).
3. Get online:
   ```bash
   # Wired is usually automatic. WiFi:
   iwctl
   [iwd]# station wlan0 get-networks
   [iwd]# station wlan0 connect "YOUR_SSID"
   [iwd]# exit
   ping -c3 archlinux.org
   ```
4. Sync the clock: `timedatectl set-ntp true`

---

## Phase 1 — Partition

> ⚠️ This **erases the disk**. Confirm the device with `lsblk` first — usually `/dev/nvme0n1`.

```bash
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI         /dev/nvme0n1   # 1G EFI System Partition
sgdisk -n2:0:0   -t2:8309 -c2:cryptroot   /dev/nvme0n1   # rest = LUKS
```

Result: `nvme0n1p1` (EFI) and `nvme0n1p2` (LUKS).

---

## Phase 2 — Encrypt + Btrfs

```bash
# Create + open the LUKS2 container (set your disk passphrase here)
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

# Filesystems
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs /dev/mapper/cryptroot

# Subvolumes
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Remount with subvolumes + SSD-friendly options
O=noatime,compress=zstd:1,ssd,discard=async
mount -o $O,subvol=@          /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}
mount -o $O,subvol=@home      /dev/mapper/cryptroot /mnt/home
mount -o $O,subvol=@log       /dev/mapper/cryptroot /mnt/var/log
mount -o $O,subvol=@pkg       /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount -o $O,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot
```

---

## Phase 3 — Base install

```bash
pacstrap -K /mnt base linux linux-firmware btrfs-progs intel-ucode \
  vim sudo networkmanager iwd \
  mesa vulkan-icd-loader vulkan-intel

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

---

## Phase 4 — System config (inside chroot)

```bash
# Time / locale / hostname
ln -sf /usr/share/zoneinfo/REGION/CITY /etc/localtime   # e.g. America/Puerto_Rico
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'lemur' > /etc/hostname

# Root + your user
passwd
useradd -mG wheel YOURNAME
passwd YOURNAME
EDITOR=vim visudo            # uncomment: %wheel ALL=(ALL:ALL) ALL

systemctl enable NetworkManager
```

### Initramfs (encryption-critical)

Edit `/etc/mkinitcpio.conf`, set HOOKS to the systemd encrypt stack:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

(Don't rebuild yet — the build happens below, as UKIs.)

### Bootloader (systemd-boot + UKIs)

The kernel, initramfs, and cmdline are built into a single **Unified Kernel
Image** that systemd-boot auto-discovers — no entry files, and one signable
artifact per kernel if you later enable Secure Boot (`setup-secureboot.sh`).

```bash
bootctl install
blkid -s UUID -o value /dev/nvme0n1p2   # note this UUID (the partition, not the mapper)
```

`/etc/kernel/cmdline` (one line; paste the UUID):

```
rd.luks.name=PASTE-UUID-HERE=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
```

Point the preset at UKI output — in `/etc/mkinitcpio.d/linux.preset`, comment
the `default_image=`/`fallback_image=` lines and set:

```
default_uki="/boot/EFI/Linux/arch-linux.efi"
fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"
```

Build, then point the boot menu's default at the UKI:

```bash
mkdir -p /boot/EFI/Linux
mkinitcpio -P
```

`/boot/loader/loader.conf`:

```
default arch-linux.efi
timeout 3
console-mode max
```

> The microcode is auto-bundled by the `microcode` hook — no separate initrd
> line. The **kit** additionally installs `linux-lts` and builds four UKIs
> (each kernel × normal/fallback initramfs) for boot resilience — worth
> replicating if you're following this by hand; `chroot-setup.sh` is the
> reference.

Finish:

```bash
exit
umount -R /mnt
swapoff -a 2>/dev/null
reboot
```

On boot you'll be prompted for the LUKS passphrase, then land at a TTY login.

---

## Phase 5 — sway desktop (Wayland)

Log in, reconnect WiFi if needed (`nmcli device wifi connect SSID password ...`), then:

```bash
sudo pacman -S sway swaybg swaylock swayidle xorg-xwayland polkit \
  i3status wmenu rofi \
  ghostty \
  ttf-dejavu ttf-font-awesome \
  network-manager-applet pavucontrol pipewire pipewire-pulse wireplumber \
  brightnessctl playerctl \
  wl-clipboard mako libnotify udisks2 \
  xdg-desktop-portal xdg-desktop-portal-wlr \
  firefox

mkdir -p ~/.config/sway
cp /etc/sway/config ~/.config/sway/config
sed -i 's/^set \$term .*/set $term ghostty/' ~/.config/sway/config
sway
```

No Xorg driver dance on Wayland — sway drives the Lemur Pro's Intel iGPU straight through
KMS + mesa. `polkit` is required for sway to get the seat from systemd-logind, and
`xorg-xwayland` keeps X11-only apps working. In sway: `Mod+Enter` = terminal, `Mod+d` =
launcher (`wmenu`); the config syntax is i3's, so i3 muscle memory carries over. For
auto-launch, exec `sway` from your shell profile on tty1 or install a light display
manager like `ly`.

---

## Phase 6 — System76-specific bits (after first boot)

Install an AUR helper:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si
```

Then:

```bash
# Power / fan / charge control (replaces TLP — don't run both)
paru -S system76-power
sudo systemctl enable --now com.system76.PowerDaemon.service

# Embedded-controller / ACPI quirks (airplane-mode key, kbd backlight, etc.)
paru -S system76-dkms system76-acpi-dkms

# Firmware updates (Open Firmware models) via fwupd
sudo pacman -S fwupd
fwupdmgr refresh && fwupdmgr get-updates
```

`system76-power` exposes CLI commands (e.g. `system76-power charge-thresholds`) you can bind
to sway keys for backlight / battery-threshold control.

---

## Caveats

- **`/boot` is unencrypted.** Standard pragmatic tradeoff — exposes boot binaries, not data.
  Encrypting `/boot` too requires GRUB and is rarely worth it on a laptop.
- **TPM2 auto-unlock** (optional): with the `sd-encrypt` setup you can later run
  `systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2` to unlock without typing the
  passphrase. Accept the tradeoff: protects a powered-off machine, weaker on a stolen
  running/suspended one.
- **Snapshots:** the Btrfs subvolume layout is ready for it — install `snapper` + `snap-pac`
  for automatic pre/post-pacman snapshots.
