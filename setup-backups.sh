#!/usr/bin/env bash
#
# Backup setup (decision #8): restic -> Backblaze B2, client-side encrypted,
# /home scope, daily systemd timer. Run ONCE on the installed system as root,
# AFTER you've created a B2 bucket + an APPEND-ONLY application key.
#
# Why restic + B2: AES-256 client-side encryption — B2 only ever stores
# ciphertext. The random 256-bit master key is wrapped by a scrypt-derived key,
# so the whole backup is only as strong as your REPOSITORY PASSWORD (decision
# #8: 8-word diceware, generated with real randomness). The repo is deduplicated
# + versioned and offsite by construction.
#
# Ransomware resistance (decision #4): the daily credential on this always-on
# laptop is an APPEND-ONLY B2 key — it can add data but NOT delete it, so a
# compromised host cannot destroy the offsite history. Retention is therefore
# enforced SERVER-SIDE by B2 Object Lock + a lifecycle rule, NOT by
# `restic forget --prune` (which would need the delete rights we don't grant).
#
# Create first at backblaze.com:
#   * a private B2 bucket (e.g. lemur-backups) with OBJECT LOCK enabled
#   * a DEFAULT lifecycle / retention rule matching how long you want history
#     kept. NOTE: B2 lifecycle is TIME-based only, so this replaces restic's
#     count-based 7/4/6 with e.g. "keep versions 180 days" (see CONFIG #15).
#   * an application key scoped to that bucket WITHOUT the deleteFiles
#     capability (read + write, no delete) -> note the keyID and key
#
# RECOVERY PREREQUISITES (decision #6) — do these BEFORE relying on backups:
#   * Your password manager must be OFF-DEVICE / recoverable (cloud-synced or
#     replicated to your phone). A local-only vault that lives only in /home is
#     a chicken-and-egg trap: you'd need the repo password to restore the vault
#     that holds the repo password.
#   * Keep a PRINTED emergency card (restic repo password + Backblaze account
#     login) somewhere off-site. The repo password has no reset.
#
# Then:  sudo ./setup-backups.sh
#
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"

echo ">> Installing restic"
pacman -S --needed --noconfirm restic

mkdir -p /etc/restic
chmod 700 /etc/restic

# --- Credentials (prompted; secrets never echoed or passed as args) --------
cat <<'NOTE'

Use a B2 application key WITHOUT delete permission (append-only). Retention is
handled by the bucket's Object Lock + lifecycle rule — not by this machine.
NOTE
read -rp  "B2 bucket name: " BUCKET
[ -n "$BUCKET" ] || die "bucket required"
read -rp  "B2 application key ID (append-only key): " KEYID
[ -n "$KEYID" ] || die "key ID required"
read -rsp "B2 application key: " APPKEY; echo
[ -n "$APPKEY" ] || die "application key required"

REPO_PATH="$(hostname)/home"     # object-name prefix inside the bucket

cat <<'NOTE'

The restic REPOSITORY PASSWORD encrypts everything in the backup. If you LOSE
it, your backups are UNRECOVERABLE — there is no reset.

Generate it with REAL randomness (dice or a CSPRNG, e.g. `keepassxc-cli`) and
PASTE it from your off-device password manager — you will never type it by hand,
so do NOT optimise for memorability:
        8-word diceware  (~103 bits; safe behind restic's scrypt KDF)
Store it in your password manager AND on your printed emergency card NOW,
before continuing.
NOTE
read -rsp "restic repository password: " RPW; echo
[ -n "$RPW" ] || die "password required"
read -rsp "confirm: " RPW2; echo
[ "$RPW" = "$RPW2" ] || die "passwords do not match"

# --- Write secrets (root-only) ---------------------------------------------
printf '%s' "$RPW" > /etc/restic/password
chmod 600 /etc/restic/password

cat > /etc/restic/b2.env <<EOF
B2_ACCOUNT_ID=$KEYID
B2_ACCOUNT_KEY=$APPKEY
RESTIC_REPOSITORY=b2:$BUCKET:$REPO_PATH
RESTIC_PASSWORD_FILE=/etc/restic/password
EOF
chmod 600 /etc/restic/b2.env

# --- Exclude reproducible junk + snapper snapshots (decision #2/#8) ---------
# /home/.snapshots is the snapper home-timeline subvolume; without excluding it,
# restic would walk 7+ point-in-time copies of /home (restic already versions).
# Explicit exclude = legible intent; the runner also passes --one-file-system as
# a second guard (btrfs gives each subvolume its own st_dev, so the flag stops
# at .snapshots too).
cat > /etc/restic/excludes.txt <<'EOF'
# snapper home-timeline snapshots — never back these up (decision #2)
/home/.snapshots
# caches / trash — reproducible, skip
**/.cache
**/.local/share/Trash
**/.thumbnails
**/.mozilla/firefox/*/cache2
**/.config/*/Cache
**/.config/*/CachedData
# big reproducible dev/build artifacts
**/node_modules
**/target
**/.venv
**/__pycache__
**/.gradle
# VM images / ISOs — usually re-downloadable; uncomment to skip
# **/*.iso
# **/*.qcow2
# **/*.img
EOF

# --- Backup runner ---------------------------------------------------------
# No `restic forget --prune` (decision #4): the append-only key can't delete,
# and retention lives in B2 Object Lock + lifecycle. Writes a success/failure
# stamp the desktop staleness-notifier reads (decision #5).
install -d -m 755 /var/lib/restic-backup
cat > /usr/local/bin/restic-backup <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
set -a; . /etc/restic/b2.env; set +a
fail() { date -u +%s > /var/lib/restic-backup/last-failure; exit 1; }
trap fail ERR
restic backup /home \
  --one-file-system \
  --exclude-file=/etc/restic/excludes.txt \
  --exclude-caches \
  --tag home
date -u +%s > /var/lib/restic-backup/last-success
EOF
chmod 755 /usr/local/bin/restic-backup

# --- Initialise the repo (idempotent) --------------------------------------
set -a; . /etc/restic/b2.env; set +a
if restic cat config >/dev/null 2>&1; then
  echo ">> restic repo already initialised — reusing"
else
  echo ">> Initialising restic repo at $RESTIC_REPOSITORY"
  restic init
fi

# --- Daily backup timer (low-priority, network-aware) ----------------------
cat > /etc/systemd/system/restic-backup.service <<'EOF'
[Unit]
Description=restic backup of /home to Backblaze B2
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
Nice=10
IOSchedulingClass=idle
ExecStart=/usr/local/bin/restic-backup
EOF

cat > /etc/systemd/system/restic-backup.timer <<'EOF'
[Unit]
Description=Daily restic backup of /home

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF

# --- Monthly integrity check (decision #10) --------------------------------
# "backup ran" != "backup is restorable". restic check (read-only — works with
# the append-only key) verifies repo structure.
cat > /etc/systemd/system/restic-check.service <<'EOF'
[Unit]
Description=restic repository integrity check
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
Nice=15
IOSchedulingClass=idle
EnvironmentFile=/etc/restic/b2.env
ExecStart=/usr/bin/restic check
EOF

cat > /etc/systemd/system/restic-check.timer <<'EOF'
[Unit]
Description=Monthly restic integrity check

[Timer]
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=6h

[Install]
WantedBy=timers.target
EOF

# --- Desktop staleness notifier (decision #5) ------------------------------
# A root timer that fails silently is Schroedinger's backup, and a root job
# can't reach your session D-Bus to notify-send anyway. So instead of pushing
# FROM the backup, we check freshness when YOU log in: a `systemctl --user` unit
# (runs IN your i3 session) reads the stamp and warns if the last success is
# stale or the last run failed. Catches both "run failed" and "never ran".
cat > /usr/local/bin/restic-staleness-check <<'EOF'
#!/usr/bin/env bash
# Runs as your normal user inside the graphical session.
set -euo pipefail
STAMP=/var/lib/restic-backup/last-success
FAILED=/var/lib/restic-backup/last-failure
STALE_SECS=129600   # 36h
now=$(date -u +%s)
note() { command -v notify-send >/dev/null && notify-send -u critical "Backup" "$1" || echo "Backup: $1"; }

if [ -f "$FAILED" ] && { [ ! -f "$STAMP" ] || [ "$(cat "$FAILED")" -gt "$(cat "$STAMP")" ]; }; then
  note "Last restic run FAILED. Check: journalctl -u restic-backup"
  exit 0
fi
if [ ! -f "$STAMP" ]; then
  note "No successful backup recorded yet."
  exit 0
fi
age=$(( now - $(cat "$STAMP") ))
if [ "$age" -gt "$STALE_SECS" ]; then
  note "Last successful backup was $(( age / 3600 ))h ago — the timer may be dead."
fi
EOF
chmod 755 /usr/local/bin/restic-staleness-check

install -d -m 755 /etc/systemd/user
cat > /etc/systemd/user/restic-staleness-check.service <<'EOF'
[Unit]
Description=Warn if restic backups are stale or last run failed

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restic-staleness-check
EOF

cat > /etc/systemd/user/restic-staleness-check.timer <<'EOF'
[Unit]
Description=Check restic backup freshness at login and periodically

[Timer]
OnStartupSec=1min
OnUnitActiveSec=4h

[Install]
WantedBy=default.target
EOF

# --- Enable system timers --------------------------------------------------
systemctl daemon-reload
systemctl enable --now restic-backup.timer
systemctl enable --now restic-check.timer

cat <<'EOF'

Backups configured. The FIRST run uploads ~all of /home (plan for overnight;
it's resumable, later runs are incremental).

  Start the first backup now:  systemctl start restic-backup.service
  Watch progress:              journalctl -u restic-backup -f
  List snapshots:              set -a; . /etc/restic/b2.env; set +a; restic snapshots
  Restore a file/dir:          restic restore latest --target /tmp/restore --include /home/you/file

ONE MANUAL STEP (decision #5) — enable the desktop staleness notifier as your
NORMAL user (a root script cannot enable --user units for you):
  systemctl --user enable --now restic-staleness-check.timer

Retention is enforced by B2 Object Lock + lifecycle (decision #4), NOT on this
machine. Confirm the bucket's lifecycle rule keeps the history you want.

Recovery (decision #6): your restic repo password + Backblaze login MUST live
off this device — password manager AND printed card. They are the ONLY way to
ever read these backups.
EOF
