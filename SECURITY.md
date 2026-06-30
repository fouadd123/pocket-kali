# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in pocket-kali, please **do not** open a public issue.

Instead, email the maintainer directly or open a [draft security advisory](https://github.com/highoncomputers/pocket-kali/security/advisories/new).

We will acknowledge receipt within **48 hours** and provide an estimated timeline for a fix.

## Scope

pocket-kali downloads and installs third-party software (Termux packages, Kali Nethunter rootfs). We are not responsible for vulnerabilities in those upstream projects. Please report them to the respective maintainers:

- **Termux**: https://github.com/termux/termux-packages/issues
- **Kali Linux**: https://bugs.kali.org/
- **XFCE4**: https://gitlab.xfce.org/

## Self-Assessment

pocket-kali runs as a non-root process inside Termux's sandboxed environment. The installer:

- Does **not** require device root (no `su`).
- Does **not** collect or transmit personal data (aside from an anonymous install counter).
- Does **not** open network ports on the host (SSH runs inside the proot container only).

## Recommendations

- Always install Termux from **F-Droid** (not Google Play) to get the latest security patches.
- Review `install.sh` before running it — the project values transparency.
