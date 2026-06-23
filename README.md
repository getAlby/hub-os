# Hub OS

A ready-to-flash Raspberry Pi image that runs **Alby Hub** (self-custodial
Lightning) with **zero manual install** — flash, boot, open
`http://albyhub.local`. Built with [CustomPiOS](https://github.com/guysoft/CustomPiOS).

## Why

Manually installing Alby Hub on a Pi means SSH + `curl | bash` + a signature
prompt + systemd setup. This image bakes all of that in, so onboarding is just:

1. Flash the image with **Raspberry Pi Imager 2.0+** (“Use custom”), set WiFi + password.
2. Insert the card, power on, wait ~2 min.
3. Open `http://albyhub.local`, set a password, save your seed, open a channel.

No terminal. Tested target: Raspberry Pi Zero 2 W (512 MB) and up.

## What's baked in (`src/modules/albyhub`)

- Alby Hub `aarch64` binary + runtime libraries in `/opt/albyhub`, **GPG-verified**
  at build time against a pinned release (`ALBYHUB_VERSION`). Alby Hub supports
  multiple Lightning backends — you choose one during first-boot setup.
- `albyhub.service` (systemd, runs as dedicated `albyhub` user, port 80,
  with a low-resource default configuration).
- Port-80 binding via systemd `AmbientCapabilities`; `ld.so.conf.d` entry for the bundled libraries.
- `gpu_mem=16` (frees ~48 MB) and `vm.swappiness=10` + 1 GB swap.
- `avahi-daemon` for `albyhub.local`; default hostname `albyhub`.

## What Imager handles at flash time (not baked)

WiFi credentials, SSH enable/key, user/password, locale/timezone, hostname —
applied on first boot. **Use Raspberry Pi Imager 2.0 or newer** — older versions
don't reliably apply customization to current Raspberry Pi OS (cloud-init), which
silently drops the SSH/WiFi settings.

## Build

```bash
git submodule update --init --recursive   # pulls src/CustomPiOS
sudo bash ./build.sh -d                    # -d downloads the base image; emits workspace/*.img
```

CI (`.github/workflows/build.yml`) builds on tag push and publishes
`HubOS-<ver>-arm64.img.xz` + sha256 to a GitHub release.

## Distribution

Download the latest `HubOS-<ver>-arm64.img.xz` from the
[GitHub Releases](https://github.com/getAlby/hub-os/releases), then flash it with
**Raspberry Pi Imager** ("Use custom") — or any flasher (Etcher, `dd`). Set your
WiFi + hostname in Imager's customisation, write, boot, and open
`http://albyhub.local`.

## Configuration

Edit `src/modules/albyhub/config` — pinned version, swap size, user, hostname.
Bump `ALBYHUB_VERSION` to ship a new image; users can also self-update in place
via `/opt/albyhub/update.sh`.

## Updates

The image keeps itself current with **no SSH**:

- **OS security patches** apply automatically (`unattended-upgrades`).
- **Alby Hub** is checked weekly and updated automatically (GPG + SHA256 verified,
  with rollback) — but **only if auto-unlock is enabled**, since an update restarts
  the hub and would otherwise leave the wallet locked. The updater asks the hub's
  own `/api/info` and skips the update when auto-unlock is off.

So for fully hands-off updates, **enable auto-unlock in Alby Hub → Settings**.
Trade-off: the unlock secret is then stored on the device (your seed phrase
remains your backup). With manual unlock, update when the hub shows
"Update Available". Place a file at `/opt/albyhub/disable-autoupdate` to turn the
app auto-updater off entirely.

## Status

Builds green in CI and boots on a Raspberry Pi Zero 2 W (setup screen serves on
`:80`). Flash with **Raspberry Pi Imager 2.0+** so first-boot customization
applies. Not yet tagged as a release.
