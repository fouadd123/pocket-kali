# pocket-kali

**One-command Kali Linux + XFCE4 desktop for Termux — Zero configuration, fully automated.**

## Quick Start

Open Termux and run:

```bash
curl -sL https://raw.githubusercontent.com/highoncomputers/pocket-kali/main/install.sh | bash
```

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Termux** | Install from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended) or GitHub |
| **Termux-X11 APK** | Download from the [releases page](https://github.com/termux/termux-x11/releases) and install as a regular Android app |
| **Android** | Version 7.0+, ARM64 (aarch64) recommended |
| **Storage** | 2 GB+ free space |
| **RAM** | 2 GB+ recommended |

> Install Termux from **F-Droid**, not Google Play. The Play Store version is outdated.

## What It Does

The installer automatically:

1. Checks system compatibility
2. Installs required Termux packages (`proot-distro`, `termux-x11-nightly`, `pulseaudio`, `axel`)
3. Downloads the **official Kali Nethunter rootfs** (Kali Linux for ARM64/mobile)
4. Extracts and configures it as a proot-distro container
5. Installs `kali-desktop-xfce` + core tools (nmap, git, python3, firefox-esr, etc.)
6. Configures XFCE4 with **Kali-dark theme**, disables compositing for performance
7. Disables `kali-motd` and unnecessary services for faster operation
8. Creates `kali` and `kali-gui` launcher commands

## Usage

### CLI Environment

```bash
kali
```

Enters the Kali Linux proot environment as root. Type `exit` to return to Termux.

### GUI Desktop

```bash
kali-gui
```

Launches a full XFCE4 desktop via Termux X11 with the Kali dragon wallpaper.

## What Gets Installed

### Termux Packages

- `proot-distro` — Container management
- `termux-x11-nightly` — X11 server
- `pulseaudio` — Audio server (TCP forwarding)
- `axel` — Accelerated downloads

### Kali Linux Packages

- `kali-desktop-xfce` — XFCE4 desktop with Kali theming
- `sudo`, `curl`, `wget`, `git` — System essentials
- `nmap`, `netcat-openbsd` — Network tools
- `python3`, `python3-pip` — Scripting
- `firefox-esr` — Web browser
- `openssh-server` — Remote access
- `neovim` — Text editor

## Commands

| Command | Description |
|---------|-------------|
| `kali` | Enter Kali Linux CLI |
| `kali-gui` | Launch XFCE4 desktop |

## Performance Notes

- **Compositing is disabled** in XFCE4 — significantly improves responsiveness on proot
- **kali-motd is disabled** — no neofetch on login, faster terminal startup
- **Single workspace** — reduces XFCE4 memory overhead
- **Battery optimization**: Go to Settings > Apps > Termux > Battery > Unrestricted to prevent Android from killing the background session

## Credits

Built on the [Kali Nethunter rootfs](https://www.kali.org/docs/nethunter/) — the official Kali Linux distribution for mobile devices.

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
