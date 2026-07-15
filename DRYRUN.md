# Lemur Pro installer — VM dry-run one-pager

Run the whole installer in a throwaway QEMU VM before it touches real hardware.
The one non-obvious bit: with the **official** Arch ISO the scripts aren't on the
guest, so you serve them from your Mac over QEMU's host route (`10.0.2.2` = your
Mac, as seen from inside the guest). With a **custom ISO** from `archiso/build-iso.sh`
the scripts are already at `/root` — skip steps 1 (Terminal A) and 3.

## On your Mac (two terminals)

**Terminal A — serve the scripts** (leave running):
```bash
cd /Users/crosario/Development/remote/github.com/invzn/llm/arch-lemurpro
python3 -m http.server 8000
```

**Terminal B — launch the VM** (needs `brew install qemu` once):
```bash
cd /Users/crosario/Development/remote/github.com/invzn/llm/arch-lemurpro
./test-vm.sh --iso ~/Downloads/archlinux-x86_64.iso
```

## In the guest window

**1. Boot:** at the Arch boot menu press **Enter** on *"Arch Linux install medium
(x86_64, UEFI)"* (or wait for the timeout). You land at `root@archiso ~ #`.

**2. Confirm network** (QEMU auto-DHCPs the virtio NIC):
```bash
ping -c2 10.0.2.2          # your Mac — proves the host route works
ping -c2 archlinux.org     # proves internet/DNS works
```
> If `archlinux.org` fails but `10.0.2.2` works:
> `systemctl restart systemd-networkd systemd-resolved` and retry.

**3. Pull the scripts from your Mac** (all five, same directory — install.sh
stages the last three into the new user's home, matching a real install):
```bash
mkdir -p kit && cd kit
for f in install.sh chroot-setup.sh post-install.sh enable-hibernate.sh setup-backups.sh; do
  curl -fLO http://10.0.2.2:8000/$f
done
chmod +x *.sh
```

**4. Run the installer** (disk is `/dev/nvme0n1` — the default — so no `DISK=` needed):
```bash
USERNAME=chris NEWHOST=lemur ./install.sh
```
Respond to the prompts, in order:
- `Type the disk path (/dev/nvme0n1) to confirm:` → type **`/dev/nvme0n1`** ↵
- **LUKS passphrase** → enter, then verify (twice)
- *(install runs: partition → encrypt → Btrfs → pacstrap → snapper/firewall/zram → bootloader)*
- `Set the ROOT password:` → type, twice
- `Set the password for 'chris':` → type, twice

**5. Finish & shut down:**
```bash
umount -R /mnt
poweroff
```

## Back on your Mac — verify the *real* boot path
```bash
./test-vm.sh --boot-disk
```
Expected sequence in the guest:
1. **LUKS passphrase prompt** (your disk passphrase) →
2. **TTY login** (`lemur login:`) → log in as `chris` →
3. `startx` → **i3 appears** (`Mod+Enter` = terminal, `Mod+d` = launcher).

If all three happen, the installer is verified end-to-end. Then `Ctrl+C` the Python
server in Terminal A.

## Gotchas
- **It'll be slow** — Apple Silicon emulating x86_64. `pacstrap` and `mkinitcpio` are
  the long poles; slowness is not a hang.
- **Mouse capture:** click into the window to grab, **Ctrl+Alt+G** to release (install
  is keyboard-only anyway).
- **`curl: connection refused`** in step 3 = the Python server (Terminal A) isn't
  running, or you're not in the `arch-lemurpro` dir where the `.sh` files live.
- **Reset and start over:** `./test-vm.sh --fresh --iso <path>` wipes the throwaway
  disk + UEFI vars in `./.vm/` and begins clean.
