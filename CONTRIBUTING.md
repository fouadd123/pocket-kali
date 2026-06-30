# Contributing to pocket-kali

First off, thanks for taking the time to contribute!

## Code of Conduct

This project adheres to the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Open a [bug report](https://github.com/highoncomputers/pocket-kali/issues/new?template=bug_report.md) and include:

- Your Android version and architecture (`uname -m`)
- Termux version (`pkg show termux` or `termux-info`)
- The contents of `~/pocket-kali.log` if the install failed
- Steps to reproduce

### Suggesting Features

Open a [feature request](https://github.com/highoncomputers/pocket-kali/issues/new?template=feature_request.md).

### Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've changed shell logic, run `shellcheck install.sh`.
3. Ensure your changes are tested inside Termux (or a proot environment).
4. Open a PR against `main` using the [PR template](https://github.com/highoncomputers/pocket-kali/blob/main/.github/PULL_REQUEST_TEMPLATE.md).

## Style Guide

- **Shell**: Target `bash` (specifically the Termux bash at `/data/data/com.termux/files/usr/bin/bash`).
- **Quoting**: Always double-quote variable expansions (`"$var"`) unless you explicitly need word splitting.
- **Error handling**: Use `set -euo pipefail` in standalone scripts; use explicit error checks in the installer.
- **Functions**: Use `snake_case` for function names.
- **Colors**: Use the `info()`, `ok()`, `warn()`, `error_()` helpers defined in `install.sh`.
- **Logging**: Write structured log entries with `log "LEVEL" "message"`.

## Testing

- Run `shellcheck install.sh` on any changes to the installer.
- If you add or modify Termux package installation, verify the package name is correct for the `stable` and `x11-repo` repos.
- For rootfs changes, test with a fresh install (back up your existing Kali container first).

## Project Structure

```
pocket-kali/
├── install.sh              # One-shot installer
├── LICENSE                 # GPL-3.0
├── README.md               # Project documentation
├── CHANGELOG.md            # Release history
├── CONTRIBUTING.md         # This file
├── SECURITY.md             # Security policy
├── .editorconfig           # Editor settings
└── .github/
    ├── workflows/
    │   └── ci.yml          # GitHub Actions CI
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── PULL_REQUEST_TEMPLATE.md
```

## License

By contributing, you agree that your contributions will be licensed under the GPL-3.0 license.
