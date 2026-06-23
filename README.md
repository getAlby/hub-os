# Hub OS

A ready-to-flash Raspberry Pi image that runs **Alby Hub** (self-custodial
Lightning, LDK backend) with **zero manual install** — flash, boot, open
`http://albyhub.local`. Built with [CustomPiOS](https://github.com/guysoft/CustomPiOS).

## Why

Manually installing Alby Hub on a Pi means SSH + `curl | bash` + a signature
prompt + systemd setup, and Raspberry Pi Imager's newer cloud-init path can
silently drop WiFi/SSH config. This image bakes all of that in and stays on the
stable Bookworm first-boot path, so onboarding is just:

1. Flash with Raspberry Pi Imager → pick **Alby Hub**, set WiFi + password.
2. Insert the card, power on, wait ~2 min.
3. Open `http://albyhub.local`, set a password, save your seed, open a channel.

No terminal. Tested target: Raspberry Pi Zero 2 W (512 MB) and up.

## What's baked in (`src/modules/albyhub`)

- Alby Hub `aarch64` binary + `libldk_node.so` in `/opt/albyhub`, **GPG-verified**
  at build time against a pinned release (`ALBYHUB_VERSION`).
- `albyhub.service` (systemd, runs as dedicated `albyhub` user, port 80,
  lean LDK config: remote Esplora, no in-RAM network graph).
- `setcap` for port 80, `ld.so.conf.d` entry for the LDK lib.
- `gpu_mem=16` (frees ~48 MB) and `vm.swappiness=10` + 1 GB swap.
- `avahi-daemon` for `albyhub.local`; default hostname `albyhub`.

## What Imager handles at flash time (not baked)

WiFi credentials, SSH enable/key, user/password, locale/timezone, hostname.
The image keeps the stock Bookworm firstboot intact so Imager's customization
screen works.

## Build

```bash
git submodule update --init --recursive   # pulls src/CustomPiOS
sudo bash ./build.sh -d                    # -d downloads the base image; emits workspace/*.img
```

CI (`.github/workflows/build.yml`) builds on tag push and publishes
`HubOS-<ver>-arm64.img.xz` + sha256 to a GitHub release.

## Distribution

Host `docs/os-list.json` and point users at it so the image appears inside
Raspberry Pi Imager:

```bash
rpi-imager --repo https://getalby.github.io/hub-os/os-list.json
```

(or ship a clickable `.rpi-imager-manifest`). `init_format: systemd` is declared
so Imager applies customization correctly. Fill in the two sha256 fields from
the release artifacts.

## Configuration

Edit `src/modules/albyhub/config` — pinned version, swap size, user, hostname.
Bump `ALBYHUB_VERSION` to ship a new image; users can also self-update in place
via `/opt/albyhub/update.sh`.

## Status

Scaffold. Before first publish: add the CustomPiOS submodule, confirm release
asset names (`manifest.txt` / `manifest.txt.asc`) for the pinned tag, and run a
flash test on a Zero 2 W + a Pi 4/5.
