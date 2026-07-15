#!/usr/bin/env bash
#
# Backup setup (decision #8): restic -> Backblaze B2, client-side encrypted,
# /home scope, daily systemd timer. Run ONCE on the installed system as root,
# AFTER you've created the B2 bucket + keys described below.
#
# Why restic + B2: AES-256 client-side encryption — B2 only ever stores
# ciphertext. The random 256-bit master key is wrapped by a scrypt-derived key,
# so the whole backup is only as strong as your REPOSITORY PASSWORD (decision
# #8: 8-word diceware, generated with real randomness). The repo is deduplicated
# + versioned and offsite by construction.
#
# Ransomware resistance (decision #4): the credential stored ON this laptop is
# an APPEND-ONLY B2 key — it can add data but NOT delete it, so a compromised
# host cannot destroy the offsite history. (Worst case with a stolen append-only
# key: the attacker "hides" files — hide is a write operation on B2 — but hidden
# versions are not destroyed while the bucket keeps all prior versions; they
# are recoverable from the B2 console/API.)
#
# Retention therefore does NOT run from this machine's stored key. It runs
# ~quarterly via `sudo restic-maintenance` (installed below), which prompts for
# a separate FULL-RIGHTS maintenance key that lives ONLY in your password
# manager — never on this disk — and then runs:
#   unlock -> forget (7 daily / 4 weekly / 6 monthly) -> prune -> check
#
# Deliberately NOT used (decision #4):
#   * B2 Object Lock — its per-object retention expires N days after upload,
#     while restic pack files stay live and referenced for years. So it doesn't
#     protect old history from an account takeover, and it blocks `prune`.
#     Account takeover is mitigated by credential hygiene instead: strong
#     unique B2 password + 2FA, stored off-device.
#   * bucket-wide lifecycle rules — a "delete old versions" rule would
#     eventually delete LIVE pack files (restic packs are immutable and
#     referenced indefinitely) and silently destroy the repo. The default
#     "keep all versions" is what makes the append-only design safe.
#
# One restic wrinkle with an append-only key: restic writes a lock file each
# run and cannot delete it afterwards, so locks/ accumulates stale entries.
#   * the daily runner judges success by restic's own "snapshot <id> saved"
#     summary, so the expected lock-cleanup failure isn't a failed backup
#   * the monthly integrity check runs `restic check --no-lock`
#   * `restic-maintenance` clears leftovers with `restic unlock` (has delete)
#   * a lifecycle rule scoped to ONLY the locks/ prefix (below) keeps the
#     clutter from piling up between maintenance runs
#
# Create first at backblaze.com:
#   * a private B2 bucket (e.g. lemur-backups). Object Lock NOT needed. NO
#     bucket-wide lifecycle rule — keep all versions (the default).
#   * one lifecycle rule scoped to the prefix   <hostname>/home/locks/   :
#     hide after 1 day, delete hidden after 1 day. restic locks are ephemeral;
#     hidden locks disappear from restic's view. Do NOT widen this prefix.
#   * the DAILY key: an application key scoped to the bucket WITHOUT the
#     deleteFiles capability (read + write, no delete) -> keyID + key go on
#     this machine (prompted below).
#   * the MAINTENANCE key: a second application key WITH full rights to the
#     bucket. Store it ONLY in your password manager; you'll paste it when
#     running `sudo restic-maintenance` (~quarterly).
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

Use the DAILY B2 application key here — the one WITHOUT delete permission
(append-only). The full-rights MAINTENANCE key stays in your password manager
and is only ever typed into `sudo restic-maintenance`.
NOTE
read -rp  "B2 bucket name: " BUCKET
[ -n "$BUCKET" ] || die "bucket required"
read -rp  "B2 application key ID (append-only DAILY key): " KEYID
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
# No `restic forget --prune` here (decision #4): the append-only key can't
# delete; retention runs quarterly via restic-maintenance with the off-device
# key. Writes a success/failure stamp the desktop staleness-notifier reads
# (decision #5).
install -d -m 755 /var/lib/restic-backup
cat > /usr/local/bin/restic-backup <<'EOF'
#!/usr/bin/env bash
# Daily backup runner. The append-only key cannot delete restic's per-run lock
# file, so a fully successful backup can still exit non-zero on that final
# cleanup — restic's "snapshot <id> saved" summary line is the ground truth
# for "the backup landed".
set -euo pipefail
fail() { date -u +%s > /var/lib/restic-backup/last-failure; exit 1; }
trap fail ERR
set -a; . /etc/restic/b2.env; set +a
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
restic backup /home \
  --one-file-system \
  --exclude-file=/etc/restic/excludes.txt \
  --exclude-caches \
  --tag home 2>&1 | tee "$log" && rc=0 || rc=$?
if [ "$rc" -ne 0 ] && ! grep -Eq '^snapshot [0-9a-f]+ saved$' "$log"; then
  fail
fi
date -u +%s > /var/lib/restic-backup/last-success
EOF
chmod 755 /usr/local/bin/restic-backup

# --- Maintenance: retention + prune + full check (quarterly, interactive) ---
# The ONLY place delete rights are used. The full-rights key is pasted from
# the password manager at runtime and never touches the disk (decision #4).
cat > /usr/local/bin/restic-maintenance <<'EOF'
#!/usr/bin/env bash
# Quarterly restic repo maintenance:
#   unlock — clear stale locks the append-only daily key couldn't delete
#   forget — retention: keep 7 daily / 4 weekly / 6 monthly snapshots
#   prune  — actually delete the data only forgotten snapshots referenced
#   check  — full integrity check, this time under a real exclusive lock
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run as root:  sudo restic-maintenance" >&2; exit 1; }
set -a; . /etc/restic/b2.env; set +a
echo "Paste the full-rights MAINTENANCE key from your password manager."
read -rp  "B2 maintenance key ID: " B2_ACCOUNT_ID
[ -n "$B2_ACCOUNT_ID" ] || exit 1
read -rsp "B2 maintenance key: " B2_ACCOUNT_KEY; echo
[ -n "$B2_ACCOUNT_KEY" ] || exit 1
export B2_ACCOUNT_ID B2_ACCOUNT_KEY
restic unlock
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic check
date -u +%s > /var/lib/restic-backup/last-maintenance
echo "Maintenance complete."
EOF
chmod 755 /usr/local/bin/restic-maintenance

# --- Initialise the repo (idempotent) --------------------------------------
set -a; . /etc/restic/b2.env; set +a
if restic cat config >/dev/null 2>&1; then
  echo ">> restic repo already initialised — reusing"
else
  echo ">> Initialising restic repo at $RESTIC_REPOSITORY"
  restic init
fi
# Start the maintenance-overdue clock (the login notifier nags after ~120 days).
[ -f /var/lib/restic-backup/last-maintenance ] || date -u +%s > /var/lib/restic-backup/last-maintenance

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
# "backup ran" != "backup is restorable". --no-lock because the append-only key
# can create but not delete locks, and `check` normally wants an exclusive one.
# Lock-free checking is safe unless it overlaps a running backup — rare, and
# the worst case is a false alarm; re-run to confirm.
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
ExecStart=/usr/bin/restic check --no-lock
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
# (runs IN your i3 session) reads the stamps and warns if the last success is
# stale, the last run failed, or maintenance is overdue. Catches "run failed",
# "never ran", and "retention never happens".
cat > /usr/local/bin/restic-staleness-check <<'EOF'
#!/usr/bin/env bash
# Runs as your normal user inside the graphical session.
set -euo pipefail
STAMP=/var/lib/restic-backup/last-success
FAILED=/var/lib/restic-backup/last-failure
MAINT=/var/lib/restic-backup/last-maintenance
STALE_SECS=129600      # 36h
MAINT_STALE=10368000   # 120 days — maintenance is quarterly-ish
now=$(date -u +%s)
note() { command -v notify-send >/dev/null && notify-send -u critical "Backup" "$1" || echo "Backup: $1"; }

if [ -f "$MAINT" ] && [ $(( now - $(cat "$MAINT") )) -gt "$MAINT_STALE" ]; then
  note "restic maintenance is $(( (now - $(cat "$MAINT")) / 86400 )) days overdue — run: sudo restic-maintenance"
fi

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
Description=Warn if restic backups are stale, failed, or maintenance is overdue

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
  List snapshots:              set -a; . /etc/restic/b2.env; set +a; restic snapshots --no-lock
  Restore a file/dir:          restic restore latest --target /tmp/restore --include /home/you/file

VERIFY the first cycle (two append-only wrinkles, both expected):
  * the backup may end with a lock-cleanup error — that is fine; success is
    the "snapshot <id> saved" line + a fresh /var/lib/restic-backup/last-success
  * then confirm the check path works:  systemctl start restic-check.service
    (runs `restic check --no-lock`; confirm your restic version accepts it)

ONE MANUAL STEP (decision #5) — enable the desktop staleness notifier as your
NORMAL user (a root script cannot enable --user units for you):
  systemctl --user enable --now restic-staleness-check.timer

RETENTION (decision #4) runs ~quarterly, never from this machine's stored key:
  sudo restic-maintenance
(paste the MAINTENANCE key from your password manager; keeps 7 daily /
4 weekly / 6 monthly, prunes, full check. The login notifier nags when it is
>120 days overdue.)

Recovery (decision #6): your restic repo password + Backblaze login MUST live
off this device — password manager AND printed card. They are the ONLY way to
ever read these backups.
EOF
