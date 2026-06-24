# Hub OS

A ready-to-flash Raspberry Pi image that runs **Alby Hub** (self-custodial
Lightning) with **zero manual install** — flash, boot, open
`http://albyhub.local`. Built with [CustomPiOS](https://github.com/guysoft/CustomPiOS).

## Why

Manually installing Alby Hub on a Pi means SSH + `curl | bash` + a signature
prompt + systemd setup. This image bakes all of that in, so onboarding is just:

1. Flash the image with **any** flasher — no customization needed.
2. Insert the card, power on, wait ~2 min.
3. On your phone/laptop, join the **`albyhub-setup`** WiFi. A setup page opens
   automatically (captive portal) — pick your home WiFi and confirm.
4. The Pi reboots onto your network. Open `http://albyhub.local`, set a
   password, save your seed, open a channel.

No terminal, no Imager customization. Tested target: Raspberry Pi Zero 2 W
(512 MB) and up.

## What's baked in (`src/modules/albyhub`)

- Alby Hub `aarch64` binary + runtime libraries in `/opt/albyhub`, **GPG-verified**
  at build time against a pinned release (`ALBYHUB_VERSION`). Alby Hub supports
  multiple Lightning backends — you choose one during first-boot setup.
- `albyhub.service` (systemd, runs as dedicated `albyhub` user, port 80,
  with a low-resource default configuration).
- Port-80 binding via systemd `AmbientCapabilities`; `ld.so.conf.d` entry for the bundled libraries.
- `gpu_mem=16` (frees ~48 MB) and `vm.swappiness=10` + 1 GB swap.
- `avahi-daemon` for `albyhub.local`; default hostname `albyhub`.
- **Captive-portal onboarding** ([`bumi/hub-os-config`](https://github.com/bumi/hub-os-config),
  pinned by commit): on first boot with no internet it raises an open
  `albyhub-setup` AP serving a setup page where the user picks their WiFi and a
  few hub options, then reboots online. The same UI stays reachable afterwards
  on `:8090`. Built from source for arm64 and staged into the image by CI.

## First-boot onboarding (captive portal)

No Imager customization is required. On first boot the device checks for
internet; finding none, it broadcasts the open **`albyhub-setup`** WiFi and
serves a captive portal on `192.168.4.1`. The user joins from a phone, the setup
page opens automatically, they choose their home network, and the Pi reboots
onto it. WiFi credentials are stored by NetworkManager and reconnect on boot.

The hub stays off port 80 until the device is online (`albyhub-wait-online`, an
`ExecStartPre` gate) so it never fights the setup portal for `:80`. A WiFi
regulatory country (`ALBYHUB_WIFI_COUNTRY`, default `US`) is baked in — AP mode
needs one set. SSH-based / Imager WiFi setup still works too: if WiFi is already
configured, the portal never appears and the device boots straight online.

## Build

```bash
git submodule update --init --recursive   # pulls src/CustomPiOS
sudo bash ./build.sh -d                    # -d downloads the base image; emits workspace/*.img
```

CI (`.github/workflows/build.yml`) builds on tag push and publishes
`HubOS-<ver>-arm64.img.xz` + sha256 to a GitHub release.

## Distribution

Download the latest `HubOS-<ver>-arm64.img.xz` from the
[latest GitHub release](https://github.com/getAlby/hub-os/releases/latest), then
flash it with **any** tool (Raspberry Pi Imager, Etcher, `dd`) — no
customization step. Boot, join the `albyhub-setup` WiFi to configure your
network, then open `http://albyhub.local`.

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

Builds green in CI and boots on a Raspberry Pi Zero 2 W (hub UI serves on `:80`).
Captive-portal onboarding (`bumi/hub-os-config`) is newly integrated and still
being validated on hardware. Not yet tagged as a release.
