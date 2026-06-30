# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

- Initial release of pocket-kali
- One-command installer (`curl ... | bash`)
- Automated system compatibility check (architecture, storage)
- Termux dependency installation (`proot-distro`, `termux-x11-nightly`, `pulseaudio`, `axel`)
- Kali Nethunter rootfs download with 4 fallback extraction methods
- XFCE4 desktop with Kali-dark theming
- Performance optimizations (compositing disabled, single workspace, motd disabled)
- PulseAudio TCP forwarding for audio in X11 sessions
- `kali` and `kali-gui` launcher commands
- Idempotent install — safe to re-run (state tracking via `~/.pocket-kali/`)
- Anonymous install counter
