#!/usr/bin/env bash
#
# Arch Linux automated installer — System76 Lemur Pro
# LUKS2 full-disk encryption + Btrfs + systemd-boot.
#
# Run from the OFFICIAL Arch ISO live environment (or the custom ISO this kit
# builds). Review the CONFIG block below before running.
#
#   WARNING: this ERASES $DISK. There is no undo.
#
set -euo pipefail

### ---------------- CONFIG (override via env, e.g. DISK=/dev/sda ./install.sh) ----------------
DISK="${DISK:-/dev/nvme0n1}"          # target disk — WILL BE WIPED
NEWHOST="${NEWHOST:-lemur}"           # hostname
# NEWUSER, not USERNAME: zsh (the archiso shell) treats USERNAME as a special
# parameter tied to the process's user — `USERNAME=x ./install.sh` arrives here
# as USERNAME=root and the install silently targets root. Found the hard way.
NEWUSER="${NEWUSER:-user}"            # your login name
TIMEZONE="${TIMEZONE:-America/Puerto_Rico}"
LOCALE="${LOCALE:-en_US.UTF-8}"
KEYMAP="${KEYMAP:-us}"
EFI_SIZE="${EFI_SIZE:-1G}"
### --------------------------------------------------------------------------------------------

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Preflight -------------------------------------------------------------
[ "$(id -u)" -eq 0 ]      || die "run as root"
[ -d /sys/firmware/efi ]  || die "not booted in UEFI mode — fix firmware settings first"
[ -b "$DISK" ]            || die "$DISK is not a block device"
[ -z "${USERNAME:-}" ]    || die "USERNAME is ignored (zsh special parameter) — unset it and use NEWUSER=<name> instead"
[ "$NEWUSER" != "root" ]  || die "NEWUSER must not be root"
ping -c1 -W3 archlinux.org >/dev/null 2>&1 || die "no network — connect first (iwctl / nmcli)"

# nvme/mmc use a 'p' between disk and partition number; sata/scsi do not.
if [[ "$DISK" == *nvme* || "$DISK" == *mmcblk* ]]; then PSEP="p"; else PSEP=""; fi
EFI_PART="${DISK}${PSEP}1"
LUKS_PART="${DISK}${PSEP}2"

# --- Confirm the wipe ------------------------------------------------------
echo
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS "$DISK"
echo
echo "About to DESTROY ALL DATA on $DISK and install Arch (LUKS + Btrfs)."
read -rp "Type the disk path ($DISK) to confirm: " confirm
[ "$confirm" = "$DISK" ] || die "confirmation mismatch — aborting"

timedatectl set-ntp true || true

# --- Partition -------------------------------------------------------------
echo ">> Partitioning $DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+"$EFI_SIZE" -t1:ef00 -c1:EFI       "$DISK"
sgdisk -n2:0:0            -t2:8309 -c2:cryptroot "$DISK"
partprobe "$DISK"; udevadm settle

# --- Encrypt ---------------------------------------------------------------
echo ">> Creating LUKS2 container on $LUKS_PART (you'll set the disk passphrase)"
cryptsetup luksFormat --type luks2 "$LUKS_PART"
echo ">> Unlocking it"
# --allow-discards lets the weekly fstrim.timer (decision #1) reach the NVMe;
# --persistent stores that flag in the LUKS header so initramfs unlock honours
# it too. Batched TRIM, not continuous (no discard= in the Btrfs mount opts) —
# minimises how long the free-block map is exposed.
cryptsetup open --allow-discards --persistent "$LUKS_PART" cryptroot

# --- Filesystems + Btrfs subvolumes ---------------------------------------
echo ">> Formatting filesystems"
mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs -f /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
for sv in @ @home @log @pkg @snapshots; do btrfs subvolume create "/mnt/$sv"; done
umount /mnt

# No continuous discard= here (decision #1): TRIM is batched via fstrim.timer.
O=noatime,compress=zstd:1,ssd
mount -o "$O,subvol=@"          /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots,boot}
mount -o "$O,subvol=@home"      /dev/mapper/cryptroot /mnt/home
mount -o "$O,subvol=@log"       /dev/mapper/cryptroot /mnt/var/log
mount -o "$O,subvol=@pkg"       /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount -o "$O,subvol=@snapshots" /dev/mapper/cryptroot /mnt/.snapshots
mount "$EFI_PART" /mnt/boot

# --- Mirrors: seed a fast list once (US/HTTPS/by-rate) ---------------------
# pacstrap copies the live mirrorlist into the new system, so seeding here is
# enough — no reflector timer on the target (decision #6).
if command -v reflector >/dev/null; then
  echo ">> Seeding mirrorlist with reflector"
  reflector --country US --protocol https --latest 20 --sort rate \
    --save /etc/pacman.d/mirrorlist || echo "reflector failed — keeping ISO mirrorlist"
fi

# --- Base system (Intel: intel-ucode + vulkan-intel) -----------------------
# Extras fold in the config decisions: zram-generator (#1 swap), snapper+snap-pac
# (#2 snapshots), nftables (#3 firewall), smartmontools (#10 disk health).
# linux-lts is the lifeboat kernel (#6): a known-good second boot target so a
# bad `linux` update is a menu pick, not a live-USB rescue. timesyncd ships
# with systemd.
echo ">> pacstrap base system"
pacstrap -K /mnt base linux linux-lts linux-firmware btrfs-progs dosfstools intel-ucode \
  vim sudo networkmanager iwd \
  mesa vulkan-icd-loader vulkan-intel \
  zram-generator nftables snapper snap-pac smartmontools

genfstab -U /mnt >> /mnt/etc/fstab

# --- Configure inside chroot ----------------------------------------------
echo ">> Running in-chroot configuration"
install -m0755 "$HERE/chroot-setup.sh" /mnt/root/chroot-setup.sh
arch-chroot /mnt /root/chroot-setup.sh \
  "$NEWHOST" "$NEWUSER" "$TIMEZONE" "$LOCALE" "$KEYMAP" "$LUKS_PART"
rm -f /mnt/root/chroot-setup.sh

# Stage the post-boot scripts in the new user's home for convenience.
for s in post-install.sh enable-hibernate.sh setup-backups.sh; do
  if [ -f "$HERE/$s" ]; then
    install -m0755 "$HERE/$s" "/mnt/home/$NEWUSER/$s"
    arch-chroot /mnt chown "$NEWUSER:$NEWUSER" "/home/$NEWUSER/$s"
  fi
done

echo
echo "==================================================================="
echo " Base install complete."
echo "   1) umount -R /mnt && reboot"
echo "   2) log in as '$NEWUSER', then run:  ~/post-install.sh"
echo "      (installs paru + system76-power/dkms + firmware updates)"
echo "   3) enable the desktop SMART-alert notifier (a root unit can't do this"
echo "      for you):  systemctl --user enable --now smartd-alert-check.timer"
echo "      (after ~/setup-backups.sh, also enable restic-staleness-check.timer)"
echo "==================================================================="
