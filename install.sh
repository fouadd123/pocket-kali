#!/data/data/com.termux/files/usr/bin/bash
# pocket-kali - One-shot Kali Linux + XFCE4 desktop for Termux
# Repository: https://github.com/highoncomputers/pocket-kali
# License: GPL-3.0
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/highoncomputers/pocket-kali/main/install.sh | bash

# ── Config ──────────────────────────────────────────────────────────────
KALI_USER="kali"
LOG_FILE="${HOME}/pocket-kali.log"
STATE_DIR="${HOME}/.pocket-kali"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="${PREFIX}/var/lib/proot-distro/containers/kali/rootfs"
KALI_HOME="${ROOTFS}/home/${KALI_USER}"
TOTAL_STEPS=9

exec 2>>"${LOG_FILE}"

# ── Colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()  { echo -e "${BLUE}[i]${NC} $*"; }
ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; log "WARN" "$*"; }
error_(){ echo -e "${RED}[✗]${NC} $*"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" >> "$LOG_FILE"; }

# ── Helpers ─────────────────────────────────────────────────────────────
step_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE} Step ${1}/${TOTAL_STEPS}: ${2}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "INFO" "Step ${1}/${TOTAL_STEPS}: ${2}"
}

is_done() { [[ -f "${STATE_DIR}/$1" ]]; }
mark_done() { mkdir -p "${STATE_DIR}"; touch "${STATE_DIR}/$1"; }

retry() {
    local cmd="$1" max=3 attempt=1 outfile
    outfile="$(mktemp)"
    while [[ $attempt -le $max ]]; do
        if eval "$cmd" >"$outfile" 2>&1; then
            rm -f "$outfile"
            return 0
        fi
        warn "Retrying (${attempt}/${max})..."
        log "WARN" "Retry ${attempt}/${max}: $(tail -3 "$outfile")"
        ((attempt++)); sleep 3
    done
    error_ "Failed after ${max} attempts: $cmd"
    log "ERROR" "Failed after ${max} attempts: $(tail -5 "$outfile")"
    rm -f "$outfile"
    return 1
}

run_in_kali() {
    local cmd="$1"
    log "INFO" "proot: $*"
    proot-distro login kali --shared-tmp -- /bin/bash -c "$cmd"
}

# ── Step 1: System Check ───────────────────────────────────────────────
step_system_check() {
    step_header 1 "System Check"
    info "Checking system compatibility..."

    if [[ ! -d /data/data/com.termux ]]; then
        error_ "This script must be run inside Termux on Android"; exit 1
    fi

    arch=$(uname -m); ok "Architecture: ${arch}"

    avail=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $avail -lt 2000000 ]]; then
        error_ "Insufficient storage (need 2GB+, have $((avail/1024))MB)"; exit 1
    fi
    ok "Storage: $((avail/1024))MB available"

    if is_done "system_check"; then info "Already checked, skipping"
    else mark_done "system_check"; fi
}

# ── Step 2: Install Termux Dependencies ────────────────────────────────
step_install_deps() {
    step_header 2 "Install Termux Packages"
    if is_done "deps"; then info "Already completed, skipping"; return; fi

    info "Updating package repositories..."
    retry "pkg update -y -o Dpkg::Options::='--force-confold' 2>&1" || true

    info "Upgrading packages..."
    retry "pkg upgrade -y -o Dpkg::Options::='--force-confold' 2>&1" || true

    if [[ ! -d ~/storage ]]; then
        info "Setting up storage access..."
        timeout 15 termux-setup-storage 2>/dev/null || warn "Storage setup skipped (non-fatal)"
    else
        info "Storage already configured, skipping"
    fi

    local packages=(proot-distro x11-repo termux-x11-nightly pulseaudio wget axel)
    local failed=() count=0 total=${#packages[@]}

    for pkg in "${packages[@]}"; do
        ((count++))
        info "[${count}/${total}] Installing ${pkg}..."
        if ! retry "pkg install -y ${pkg} -o Dpkg::Options::='--force-confold' 2>&1"; then
            warn "Failed to install ${pkg}"; failed+=("$pkg")
        fi
    done

    [[ ${#failed[@]} -gt 0 ]] && warn "Some packages failed: ${failed[*]}"
    mark_done "deps"; ok "Termux packages installed"
}

# ── Step 3: Create Launchers (early) ───────────────────────────────────
step_create_launchers() {
    step_header 3 "Create Launcher Commands"
    if is_done "launchers"; then info "Already created, skipping"; return; fi

    mkdir -p "${PREFIX}/bin"

    cat > "${PREFIX}/bin/kali" << 'LAUNCHER_CLI'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
exec proot-distro login kali --shared-tmp
LAUNCHER_CLI

    cat > "${PREFIX}/bin/kali-gui" << 'LAUNCHER_GUI'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
if [[ -f /etc/debian_version ]] || [[ -f /etc/kali_version ]]; then
    echo "Error: kali-gui must be run from Termux, not from inside the proot." >&2
    exit 1
fi
export XDG_RUNTIME_DIR=${TMPDIR:-/tmp}
termux-x11 :0 >/dev/null 2>&1 &
am start -n com.termux.x11/.MainActivity >/dev/null 2>&1 || true
sleep 5
proot-distro login kali --shared-tmp -- bash -c "
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
dbus-launch --exit-with-session xfce4-session
"
LAUNCHER_GUI

    chmod +x "${PREFIX}/bin/kali" "${PREFIX}/bin/kali-gui"

    if [[ ! -x "${PREFIX}/bin/kali" ]]; then
        error_ "Failed to create kali launcher"; exit 1
    fi

    if ! command -v kali &>/dev/null; then
        mkdir -p "${HOME}/bin"
        ln -sf "${PREFIX}/bin/kali" "${HOME}/bin/kali"
        ln -sf "${PREFIX}/bin/kali-gui" "${HOME}/bin/kali-gui"
        if ! grep -q "${HOME}/bin" "${HOME}/.bashrc" 2>/dev/null; then
            echo "" >> "${HOME}/.bashrc"
            echo "# pocket-kali" >> "${HOME}/.bashrc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "${HOME}/.bashrc"
        fi
        ok "Fallback created in ~/bin/"
    fi

    mark_done "launchers"; ok "Launchers created: kali, kali-gui"
}

# ── Step 4: Download & Install Kali Nethunter Rootfs ───────────────────
step_install_kali() {
    step_header 4 "Install Kali Linux Rootfs"
    if is_done "kali_rootfs"; then info "Already installed, skipping"; return; fi

    if [[ -d "$ROOTFS" ]]; then
        info "Existing Kali rootfs found at ${ROOTFS}"
        mark_done "kali_rootfs"
        ok "Kali rootfs already present"
        return
    fi

    local tarball="${HOME}/kali-nethunter-rootfs.tar.xz"
    local url="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-arm64.tar.xz"

    info "Downloading Kali Nethunter rootfs..."
    info "URL: ${url}"

    if command -v axel &>/dev/null; then
        local downloader="axel -o '${tarball}' '${url}'"
    else
        warn "axel not found, falling back to wget"
        local downloader="wget -O '${tarball}' '${url}'"
    fi

    if ! retry "$downloader 2>&1"; then
        error_ "Download failed. Check internet connection and try again."
        exit 1
    fi

    if [[ ! -f "$tarball" ]]; then
        error_ "Downloaded file not found at ${tarball}"; exit 1
    fi

    local size
    size=$(du -h "$tarball" | awk '{print $1}')
    info "Downloaded: ${size}"

    info "Extracting rootfs..."
    mkdir -p "$ROOTFS"

    if bsdtar -xpJf "$tarball" -C "$ROOTFS" --strip-components=1 2>/dev/null; then
        ok "Rootfs extracted"
    else
        warn "bsdtar extraction had issues, trying alternate method..."
        mkdir -p "${PREFIX}/var/lib/proot-distro/containers/kali"
        local tmpdir="${PREFIX}/var/lib/proot-distro/containers/kali/_tmp"
        mkdir -p "$tmpdir"
        bsdtar -xpJf "$tarball" -C "$tmpdir" 2>/dev/null || {
            error_ "Failed to extract rootfs"; exit 1
        }
        if [[ -d "${tmpdir}/kali-arm64" ]]; then
            mv -f "${tmpdir}/kali-arm64"/* "$ROOTFS" 2>/dev/null || true
            mv -f "${tmpdir}/kali-arm64"/.??* "$ROOTFS" 2>/dev/null || true
        else
            mv -f "${tmpdir}"/* "$ROOTFS" 2>/dev/null || true
            mv -f "${tmpdir}"/.??* "$ROOTFS" 2>/dev/null || true
        fi
        rm -rf "$tmpdir"
        ok "Rootfs extracted (alternate method)"
    fi

    rm -f "$tarball"

    if [[ ! -f "${ROOTFS}/etc/os-release" ]]; then
        error_ "Rootfs extraction incomplete — missing /etc/os-release"; exit 1
    fi

    info "Creating proot-distro configuration..."
    cat > "${PREFIX}/etc/proot-distro/kali.sh" << 'PROOTCONF'
DISTRO_NAME="Kali Linux"
DISTRO_COMMENT="Kali Linux (Nethunter rootfs) for Termux — pocket-kali"
PROOTCONF

    # Fix: ensure /etc/resolv.conf exists for network access inside proot
    if [[ ! -f "${ROOTFS}/etc/resolv.conf" ]]; then
        echo "nameserver 8.8.8.8" > "${ROOTFS}/etc/resolv.conf"
        echo "nameserver 8.8.4.4" >> "${ROOTFS}/etc/resolv.conf"
    fi

    mark_done "kali_rootfs"; ok "Kali rootfs installed"
}

# ── Step 5: Configure Kali ─────────────────────────────────────────────
step_configure_kali() {
    step_header 5 "Configure Kali Linux"
    if is_done "configured"; then info "Already configured, skipping"; return; fi

    if [[ ! -d "$ROOTFS" ]]; then
        error_ "Kali rootfs not found at ${ROOTFS}"; exit 1
    fi

    info "Updating package lists..."
    run_in_kali "apt-get update -y 2>&1" || warn "apt update had issues"

    info "Upgrading packages..."
    run_in_kali "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1" || true

    info "Installing XFCE4 desktop (Kali edition)..."
    if ! run_in_kali "DEBIAN_FRONTEND=noninteractive apt-get install -y kali-desktop-xfce 2>&1"; then
        warn "kali-desktop-xfce not available, installing xfce4 directly..."
        run_in_kali "DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-session kali-menu 2>&1" || warn "XFCE4 install had issues"
    fi

    info "Installing core tools..."
    run_in_kali "DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo curl wget git python3 python3-pip \
        nmap netcat-openbsd openssh-server neovim \
        firefox-esr 2>&1" || warn "Some tools may not have installed"

    info "Verifying XFCE4 session..."
    run_in_kali "command -v xfce4-session" || warn "xfce4-session not found — GUI may not work"

    info "Creating user '${KALI_USER}'..."
    run_in_kali "groupadd -f storage 2>/dev/null || true"
    run_in_kali "groupadd -f wheel 2>/dev/null || true"
    run_in_kali "useradd -m -g users -G wheel,audio,video,storage -s /bin/bash ${KALI_USER} 2>/dev/null || true"

    info "Configuring sudo (NOPASSWD)..."
    run_in_kali "echo '${KALI_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${KALI_USER}"
    run_in_kali "chmod 440 /etc/sudoers.d/${KALI_USER}"

    info "Setting environment variables..."
    run_in_kali "echo 'export DISPLAY=:0' >> /home/${KALI_USER}/.bashrc"
    run_in_kali "echo 'export PULSE_SERVER=127.0.0.1' >> /home/${KALI_USER}/.bashrc"

    info "Enabling SSH server..."
    run_in_kali "systemctl enable ssh 2>/dev/null || update-rc.d ssh enable 2>/dev/null || true"

    info "Cleaning package cache..."
    run_in_kali "apt-get clean -y 2>&1" || true

    mark_done "configured"; ok "Kali Linux configured"
}

# ── Step 6: Configure XFCE4 + Performance Tuning ──────────────────────
step_configure_xfce4() {
    step_header 6 "Configure XFCE4 Desktop & Performance"
    if is_done "xfce4"; then info "Already configured, skipping"; return; fi

    if [[ ! -d "$ROOTFS" ]]; then
        error_ "Kali rootfs not found at ${ROOTFS}"; exit 1
    fi

    # Create config directories for both root and kali user
    local root_home="${ROOTFS}/root"
    local user_home="${ROOTFS}/home/${KALI_USER}"

    for home_dir in "$root_home" "$user_home"; do
        [[ ! -d "$home_dir" ]] && continue
        mkdir -p "${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml" \
                 "${home_dir}/.config/xfce4/terminal" \
                 "${home_dir}/.config/gtk-3.0"

        # ── xfwm4: disable compositing, single workspace (PERFORMANCE) ──
        cat > "${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'XFWM4'
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="workspace_count" type="int" value="1"/>
    <property name="theme" type="string" value="Kali-xfwm4"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="click_to_focus" type="bool" value="true"/>
    <property name="borderless_maximize" type="bool" value="true"/>
  </property>
</channel>
XFWM4

        # ── xsettings: Kali-dark theme ──
        cat > "${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'XSETTINGS'
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Kali-dark"/>
    <property name="IconThemeName" type="string" value="Flat-Remix-Blue-Dark"/>
  </property>
</channel>
XSETTINGS

        # ── Desktop: set Kali dragon wallpaper ──
        cat > "${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'XFCEDESK'
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="workspace0" type="empty">
        <property name="last-image" type="string" value="/usr/share/backgrounds/kali/kali-dragon.svg"/>
      </property>
    </property>
  </property>
</channel>
XFCEDESK

        # ── Terminal: dark, transparent, no scrollbar ──
        cat > "${home_dir}/.config/xfce4/terminal/terminalrc" << 'TERMINALRC'
[Configuration]
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=80x24
MiscMenubarDefault=TRUE
MiscConfirmClose=TRUE
MiscTabCloseButtons=TRUE
MiscHighlightUrls=TRUE
MiscCopyOnSelect=FALSE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.850000
TitleMode=TERMINAL_TITLE_HIDE
ScrollingUnlimited=TRUE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
FontName=Monospace 12
TERMINALRC

        # ── GTK: Kali-dark theme ──
        cat > "${home_dir}/.config/gtk-3.0/settings.ini" << 'GTKINI'
[Settings]
gtk-theme-name=Kali-dark
gtk-icon-theme-name=Flat-Remix-Blue-Dark
gtk-font-name=Sans 10
GTKINI

        # Fix owner
        local username="${KALI_USER}"
        [[ "$home_dir" == "$root_home" ]] && username="root"
        run_in_kali "chown -R ${username}:${username} /${home_dir#$ROOTFS}/.config 2>/dev/null || true"
    done

    # ── Performance: Disable kali-motd (neofetch on every login) ──
    info "Disabling kali-motd for faster terminal..."
    run_in_kali "chmod -x /etc/update-motd.d/* 2>/dev/null || true"
    run_in_kali "rm -f /etc/update-motd.d/00-header 2>/dev/null || true"

    # ── Performance: Disable NetworkManager wifi polling ──
    info "Disabling unnecessary services for proot..."
    run_in_kali "systemctl disable NetworkManager-wait-online 2>/dev/null || true"
    run_in_kali "systemctl mask NetworkManager-wait-online 2>/dev/null || true"

    mark_done "xfce4"; ok "XFCE4 configured with performance optimizations"
}

# ── Step 7: Configure PulseAudio ───────────────────────────────────────
step_configure_audio() {
    step_header 7 "Configure PulseAudio"
    if is_done "audio"; then info "Already configured, skipping"; return; fi

    mkdir -p "${HOME}/.config/pulse"
    cat > "${HOME}/.config/pulse/default.pa" << 'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
load-module module-always-sink
EOF

    mark_done "audio"; ok "PulseAudio configured"
}

# ── Step 8: Verify ─────────────────────────────────────────────────────
step_verify() {
    step_header 8 "Verify Installation"
    if is_done "verify"; then info "Already verified, skipping"; return; fi

    info "Checking Kali Linux version..."
    local version
    version=$(proot-distro login kali -- bash -c "cat /etc/os-release 2>/dev/null | head -5 || echo unknown" 2>/dev/null)
    if echo "$version" | grep -qi "kali"; then
        ok "Kali Linux confirmed"
        echo "$version" | while IFS= read -r line; do echo "  ${line}"; done
    else
        info "OS version: ${version}"
    fi

    info "Checking XFCE4..."
    run_in_kali "command -v xfce4-session" && ok "xfce4-session found"

    info "Checking key tools..."
    run_in_kali "command -v nmap" && ok "nmap found"
    run_in_kali "command -v git" && ok "git found"
    run_in_kali "command -v python3" && ok "python3 found"

    mark_done "verify"; ok "Verification complete"
}

# ── Step 9: Finalize ───────────────────────────────────────────────────
step_finalize() {
    step_header 9 "Complete"
    if is_done "finalize"; then info "Already finalized, skipping"; return; fi

    ok "Installation complete!"
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Pocket Kali is ready!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}kali${NC}        - Enter Kali Linux CLI"
    echo -e "  ${YELLOW}kali-gui${NC}    - Launch XFCE4 desktop (Termux-X11 APK required)"
    echo ""
    echo -e "${BLUE}[i]${NC} Prerequisites:"
    echo -e "    • Termux from F-Droid: https://f-droid.org/packages/com.termux/"
    echo -e "    • Termux-X11 APK:      https://github.com/termux/termux-x11/releases"
    echo ""
    echo -e "${YELLOW}[!]${NC} BATTERY OPTIMIZATION (important!)"
    echo -e "    Go to: ${GREEN}Settings > Apps > Termux > Battery > Unrestricted${NC}"
    echo -e "    This prevents Android from killing Termux in the background."
    echo -e "    Without this, X11 sessions may crash after a few minutes."
    echo ""
    echo -e "${YELLOW}[!]${NC} If 'kali' not found: ${GREEN}source ~/.bashrc${NC}"
    echo ""

    mark_done "finalize"
}

# ── Main ────────────────────────────────────────────────────────────────
main() {
    clear
    echo -e "${BLUE}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║              pocket-kali — Kali Linux for Termux            ║
║                   One-shot installer                        ║
║  github.com/highoncomputers/pocket-kali                     ║
╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    echo -e "${BLUE}[i]${NC} Log: ${LOG_FILE}"
    echo ""

    step_system_check
    step_install_deps
    step_create_launchers
    step_install_kali
    step_configure_kali
    step_configure_xfce4
    step_configure_audio
    step_verify
    step_finalize

    # Anonymous install counter
    curl -sL "https://api.countapi.xyz/hit/highoncomputers/pocket-kali-installs" >/dev/null 2>&1 || true
}

main "$@"
