# pocket-kali

<p align="center">
  <a href="https://github.com/highoncomputers/pocket-kali/releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/highoncomputers/pocket-kali?style=flat-square"></a>
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square"></a>
  <a href="https://github.com/highoncomputers/pocket-kali/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/highoncomputers/pocket-kali/ci.yml?branch=main&style=flat-square&label=CI"></a>
  <a href="https://github.com/highoncomputers/pocket-kali"><img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20Termux-brightgreen?style=flat-square"></a>
  <a href="https://github.com/highoncomputers/pocket-kali/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/highoncomputers/pocket-kali?style=flat-square"></a>
</p>

**One-command Kali Linux + XFCE4 desktop for Termux — Zero configuration, fully automated.**

## Screenshot

> *Screenshot coming soon — submit one via PR!*

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

## FAQ

**Q: Do I need root (su) to run this?**

A: No. pocket-kali runs entirely inside Termux's sandboxed environment.

**Q: Why does the installer use F-Droid Termux and not Google Play?**

A: The Google Play version of Termux is outdated and lacks features like `termux-x11`. Always use F-Droid.

**Q: Can I install additional tools after the setup?**

A: Yes — run `kali` and then `apt-get install <package>` as usual.

**Q: What if the download fails?**

A: The installer retries up to 3 times with `axel`. If it still fails, check your internet connection and try again.

**Q: How do I uninstall pocket-kali?**

A: Remove the Kali proot container with `proot-distro remove kali` and delete `~/.pocket-kali/`.

**Q: Does this work on 32-bit (armv7l) devices?**

A: The Kali Nethunter rootfs is ARM64 only. 32-bit devices are not supported.

**Q: Will this work on non-Android Linux (e.g., ChromeOS Linux container)?**

A: No — the installer checks for Termux's `/data/data/com.termux` directory and will exit if not found.

## Troubleshooting

### "kali: command not found"

Run `source ~/.bashrc` or restart Termux. If it persists, check `~/bin/` was created:

```bash
ls -la ~/bin/kali
```

### GUI doesn't start / X11 blank screen

1. Make sure **Termux-X11 APK** is installed — download from the [releases page](https://github.com/termux/termux-x11/releases).
2. Set **Termux battery to Unrestricted** — `Settings > Apps > Termux > Battery > Unrestricted`.
3. Run `killall termux-x11 2>/dev/null; killall pulseaudio 2>/dev/null` then try `kali-gui` again.
4. If still broken, check the log: `cat ~/pocket-kali.log | tail -50`.

### Installation stuck at "Installing Kali Linux Rootfs"

The rootfs tarball is ~300 MB. On slow connections this can take 10+ minutes. Check `~/pocket-kali.log` for download progress. If it truly hangs, cancel (Ctrl+C) and re-run — the installer is idempotent.

### Audio not working

Restart PulseAudio:

```bash
pulseaudio --kill 2>/dev/null; pulseaudio --start
```

Then do `kali-gui` again. Inside the Kali session, verify PulseAudio is connecting:

```bash
pactl info
```

### Out of space

Kali rootfs + XFCE4 takes ~1.5 GB after installation. Run `kali` then `apt-get clean` to clear package cache.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting bugs, suggesting features, and submitting pull requests.

## Security

See [SECURITY.md](SECURITY.md) for our security policy and vulnerability reporting process.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Credits

Built on the [Kali Nethunter rootfs](https://www.kali.org/docs/nethunter/) — the official Kali Linux distribution for mobile devices.

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
