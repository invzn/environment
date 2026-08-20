#!/usr/bin/env bash
#
# In-chroot configuration. Invoked by install.sh via arch-chroot — not meant
# to be run directly. Args (positional, non-secret):
#   $1 hostname  $2 username  $3 timezone  $4 locale  $5 keymap  $6 luks-partition
#
# Passwords are prompted interactively here (never passed as args).
#
set -euo pipefail

NEWHOST="$1"; USERNAME="$2"; TIMEZONE="$3"; LOCALE="$4"; KEYMAP="$5"; LUKS_PART="$6"

# --- Time / locale / console ----------------------------------------------
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc
sed -i "s/^#\s*${LOCALE} /${LOCALE} /" /etc/locale.gen
grep -q "^${LOCALE} " /etc/locale.gen || { echo "ERROR: failed to uncomment ${LOCALE} in /etc/locale.gen" >&2; exit 1; }
locale-gen
echo "LANG=$LOCALE"   > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# --- Hostname / hosts ------------------------------------------------------
echo "$NEWHOST" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${NEWHOST}.localdomain ${NEWHOST}
EOF

systemctl enable NetworkManager
systemctl enable systemd-timesyncd   # decision #5: time sync (NM does NOT sync the clock)
systemctl enable nftables            # decision #3: firewall (ruleset written below)

# Maintenance hygiene (decision #1/#10): set-and-forget timers so a low-touch
# laptop stays current and catches silent rot. (restic check lives in
# setup-backups.sh, alongside restic itself.)
systemctl enable systemd-boot-update.service  # keep the ESP boot stub current
systemctl enable fstrim.timer                 # weekly batched TRIM (LUKS opened --allow-discards)
systemctl enable btrfs-scrub@-.timer          # monthly scrub of / — surfaces bit-rot
systemctl enable smartd.service               # SMART monitoring of the NVMe (notifications below)

# --- pacman UX: colour + parallel downloads (minor polish) -----------------
sed -i 's/^#Color$/Color/'                       /etc/pacman.conf
sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf

# --- WiFi backend: iwd (minor polish) --------------------------------------
# iwd is already installed and is more reliable/faster on modern Intel WiFi than
# wpa_supplicant. NetworkManager drives iwd over D-Bus, so iwd.service is NOT
# enabled separately. (wpa_supplicant stays as an NM dependency, just unused.)
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi_backend.conf <<'EOF'
[device]
wifi.backend=iwd
EOF

# --- SMART alert notifications (decision #10) ------------------------------
# smartd runs as root and can't reach your session D-Bus, so (like the backup
# notifier, decision #5) it writes a persistent marker on any SMART warning and
# a `systemctl --user` unit surfaces it as a desktop notification at login.
mkdir -p /var/lib/smartd
cat > /etc/smartd.conf <<'EOF'
# Monitor all devices; daily short + weekly long self-test; temperature warnings;
# on any SMART warning run smartd-notify (no MTA — -m <nomailer> suppresses mail).
DEVICESCAN -a -o on -S on -s (S/../.././02|L/../../6/03) -W 4,55,70 -m <nomailer> -M exec /usr/local/bin/smartd-notify
EOF

cat > /usr/local/bin/smartd-notify <<'EOF'
#!/usr/bin/env bash
# Invoked by smartd (-M exec) as root on a SMART warning. Persists the alert so
# the per-user login notifier can surface it (root has no session D-Bus).
set -euo pipefail
msg="${SMARTD_DEVICE:-disk}: ${SMARTD_MESSAGE:-SMART warning}"
printf '%s  %s\n' "$(date -u +%FT%TZ)" "$msg" >> /var/lib/smartd/alerts
logger -t smartd-notify "$msg"
EOF
chmod 755 /usr/local/bin/smartd-notify

cat > /usr/local/bin/smartd-alert-check <<'EOF'
#!/usr/bin/env bash
# Runs as your normal user in the graphical session: desktop-notify any SMART
# alert recorded by smartd-notify that hasn't been shown yet.
set -euo pipefail
ALERTS=/var/lib/smartd/alerts
SEEN="${XDG_STATE_HOME:-$HOME/.local/state}/smartd-alerts.seen"
[ -f "$ALERTS" ] || exit 0
mkdir -p "$(dirname "$SEEN")"; touch "$SEEN"
new="$(comm -13 <(sort -u "$SEEN") <(sort -u "$ALERTS"))"
[ -n "$new" ] || exit 0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  command -v notify-send >/dev/null && notify-send -u critical "Disk SMART alert" "$line" || echo "SMART: $line"
done <<<"$new"
sort -u "$ALERTS" > "$SEEN"
EOF
chmod 755 /usr/local/bin/smartd-alert-check

install -d -m 755 /etc/systemd/user
cat > /etc/systemd/user/smartd-alert-check.service <<'EOF'
[Unit]
Description=Surface new smartd SMART alerts as desktop notifications

[Service]
Type=oneshot
ExecStart=/usr/local/bin/smartd-alert-check
EOF
cat > /etc/systemd/user/smartd-alert-check.timer <<'EOF'
[Unit]
Description=Check for new SMART alerts at login and periodically

[Timer]
OnStartupSec=1min
OnUnitActiveSec=1h

[Install]
WantedBy=default.target
EOF

# --- Initramfs: systemd + sd-encrypt for LUKS unlock ----------------------
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' \
  /etc/mkinitcpio.conf

# --- Bootloader: systemd-boot + UKIs (decision #7 rev2) --------------------
# Unified Kernel Images instead of loader entries: kernel + initramfs +
# cmdline in ONE .efi per (kernel, preset). systemd-boot auto-discovers them
# from EFI/Linux/ — no entry files to keep in sync — and each is a single
# signable artifact, which is what makes Secure Boot coverage of the
# *initramfs* possible later (setup-secureboot.sh). Without UKIs, SB signs
# the kernel but the initramfs — the part an evil maid would trojan to steal
# the LUKS passphrase — rides along unverified.
bootctl install
LUKS_UUID="$(blkid -s UUID -o value "$LUKS_PART")"
# Shared kernel cmdline, baked into every UKI at build time (microcode is
# embedded via the `microcode` hook, so no separate intel-ucode line).
# Post-install cmdline changes (e.g. enable-hibernate.sh's resume=) edit this
# file and re-run `mkinitcpio -P` — there are no entry files to patch.
printf '%s\n' "rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw" \
  > /etc/kernel/cmdline

# Boot resilience (decision #2/#6): four UKIs from two installed kernels.
#   arch-linux.efi              — primary `linux`
#   arch-linux-fallback.efi     — `linux`, fallback initramfs (botched-image guard)
#   arch-linux-lts.efi          — `linux-lts` lifeboat (known-good kernel pick)
#   arch-linux-lts-fallback.efi — lts + fallback (belt and suspenders)
install -d /boot/EFI/Linux
for k in linux linux-lts; do
  cat > "/etc/mkinitcpio.d/${k}.preset" <<EOF
# arch-lemurpro kit: UKI layout (kernel updates rebuild these via pacman hook)
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-${k}"
PRESETS=('default' 'fallback')
default_uki="/boot/EFI/Linux/arch-${k}.efi"
fallback_uki="/boot/EFI/Linux/arch-${k}-fallback.efi"
fallback_options="-S autodetect"
EOF
done
mkinitcpio -P
for u in arch-linux arch-linux-fallback arch-linux-lts arch-linux-lts-fallback; do
  [ -f "/boot/EFI/Linux/${u}.efi" ] || { echo "ERROR: UKI ${u}.efi was not built" >&2; exit 1; }
done
# pacstrap's initial kernel install built classic initramfs images before the
# presets were switched; they're dead weight on the ESP now.
rm -f /boot/initramfs-linux*.img

cat > /boot/loader/loader.conf <<EOF
default arch-linux.efi
timeout 3
console-mode max
EOF

# --- sway (Wayland) desktop + audio (Phase 5) ------------------------------
# polkit: sway acquires the seat via systemd-logind, which needs polkit.
# xorg-xwayland: X11-only apps keep working inside sway.
# mako + libnotify: the smartd and restic staleness notifiers call notify-send —
#   without a daemon + libnotify those alerts silently vanish.
# xdg-desktop-portal-wlr: screen share/capture for wlroots compositors.
# udisks2: `udisksctl mount` lets the seated user mount USB sticks without
#   sudo (via polkit) — no automount daemon, mounts land in /run/media/$USER.
pacman -S --noconfirm --needed \
  sway swaybg swaylock swayidle xorg-xwayland polkit \
  i3status wmenu rofi \
  ghostty ttf-dejavu ttf-font-awesome \
  network-manager-applet pavucontrol pipewire pipewire-pulse wireplumber \
  brightnessctl playerctl firefox \
  wl-clipboard mako libnotify udisks2 \
  xdg-desktop-portal xdg-desktop-portal-wlr

# --- User + sudo -----------------------------------------------------------
useradd -mG wheel -s /bin/bash "$USERNAME"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# The sed no-ops silently if upstream reformats the comment — and a user with
# no sudo makes post-install.sh dead on arrival. Fail loudly instead.
grep -q '^%wheel ALL=(ALL:ALL) ALL$' /etc/sudoers || { echo "ERROR: failed to enable %wheel in /etc/sudoers" >&2; exit 1; }

# sway starts by typing `sway` at the TTY login — no display manager, same
# philosophy as the old startx flow. Stage a user config from the packaged
# default and point $term at ghostty (upstream default is foot, not installed).
install -d -m 755 "/home/$USERNAME/.config/sway"
cp /etc/sway/config "/home/$USERNAME/.config/sway/config"
sed -i 's/^set \$term .*/set $term ghostty/' "/home/$USERNAME/.config/sway/config"
# Assert the sed landed — if upstream renames $term the config would silently
# keep pointing Mod+Enter at a terminal that isn't installed.
grep -q '^set \$term ghostty$' "/home/$USERNAME/.config/sway/config" \
  || { echo "ERROR: failed to point sway's \$term at ghostty in /home/$USERNAME/.config/sway/config" >&2; exit 1; }
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config"

# --- Swap: zram (decision #1) ---------------------------------------------
# zram = ½ RAM (12G on this 24G machine, a ceiling not a reservation), zstd.
# Hibernate is intentionally NOT set up here — run enable-hibernate.sh later.
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
cat > /etc/sysctl.d/99-zram.conf <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF

# --- Firewall: nftables, default-drop inbound (decision #3) ----------------
cat > /etc/nftables.conf <<'EOF'
#!/usr/bin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        ct state invalid drop
        ct state established,related accept
        iif "lo" accept
        ip protocol icmp accept
        # meta l4proto (not `ip6 nexthdr`) so ICMPv6 behind extension headers
        # still matches — NDP/RA is ICMPv6; dropping it kills IPv6 entirely
        meta l4proto ipv6-icmp accept
        # no inbound services opened (decision: none for now)
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
    chain output {
        type filter hook output priority filter; policy accept;
    }
}
EOF
chmod 700 /etc/nftables.conf

# --- Snapshots: snapper + snap-pac, minimal-plus (decision #2) -------------
# root config reuses the existing @snapshots subvol mounted at /.snapshots, so
# we do the standard "let snapper make its own, then swap ours back in" dance.
snapper_set() { sed -i "s|^${2}=.*|${2}=\"${3}\"|" "/etc/snapper/configs/${1}"; }

if mountpoint -q /.snapshots; then umount /.snapshots; fi
rm -rf /.snapshots
snapper --no-dbus -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount /.snapshots                      # remounts @snapshots from fstab
chmod 750 /.snapshots

# root: snapshots driven by the pacman hook (snap-pac), not a timeline
snapper_set root TIMELINE_CREATE no
snapper_set root NUMBER_CLEANUP yes
snapper_set root NUMBER_LIMIT 10
snapper_set root NUMBER_LIMIT_IMPORTANT 10
snapper_set root ALLOW_USERS "$USERNAME"
snapper_set root SYNC_ACL yes   # ALLOW_USERS grants snapper ops only; ACLs let $USERNAME read the snapshot files

# home: modest daily timeline for file recovery, no hourly churn
snapper --no-dbus -c home create-config /home
snapper_set home TIMELINE_CREATE yes
snapper_set home TIMELINE_CLEANUP yes
snapper_set home TIMELINE_LIMIT_HOURLY 0
snapper_set home TIMELINE_LIMIT_DAILY 7
snapper_set home TIMELINE_LIMIT_WEEKLY 4
snapper_set home TIMELINE_LIMIT_MONTHLY 0
snapper_set home TIMELINE_LIMIT_YEARLY 0
snapper_set home ALLOW_USERS "$USERNAME"
snapper_set home SYNC_ACL yes

systemctl enable snapper-timeline.timer   # drives the @home daily timeline
systemctl enable snapper-cleanup.timer    # prunes per the limits above

# --- Passwords (interactive) ----------------------------------------------
# Retry loops: exhausting passwd's attempts would otherwise abort (set -e) the
# whole install at the very last step, after everything else succeeded.
echo ">> Set the ROOT password:"
until passwd; do echo ">> try again"; done
echo ">> Set the password for '$USERNAME':"
until passwd "$USERNAME"; do echo ">> try again"; done

# A bootable system nobody can log into is the worst failure mode — assert both
# accounts actually ended up with a password hash (caught a real bug once).
for acct in root "$USERNAME"; do
  grep -Eq "^${acct}:\\\$" /etc/shadow || { echo "ERROR: no password hash for '$acct' in /etc/shadow" >&2; exit 1; }
done
