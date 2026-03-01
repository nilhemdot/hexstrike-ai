#!/usr/bin/env bash
# HexStrike AI - Security Tools Installer
# Installs all external tools required by HexStrike v6.0
# Usage: sudo bash install_tools.sh

set -e

GOPATH="${GOPATH:-/root/go}"
GO_BIN="/usr/local/go/bin/go"
HEXSTRIKE_ENV="/home/user/hexstrike-ai/hexstrike-env"
PYTHON="${HEXSTRIKE_ENV}/bin/python3"
PIP="${HEXSTRIKE_ENV}/bin/pip"

export PATH="$PATH:/usr/local/go/bin:${GOPATH}/bin:/opt/rbenv/versions/3.3.6/bin"

log() { echo "[*] $*"; }
ok()  { echo "[+] $*"; }
err() { echo "[-] $* (skipping)"; }

# ============================================================
# APT Tools
# ============================================================
log "Installing apt-based tools..."
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    nmap masscan \
    hydra john hashcat medusa \
    gdb radare2 binwalk \
    nikto sqlmap dirb gobuster ffuf \
    foremost steghide libimage-exiftool-perl \
    binutils checksec \
    fierce dnsenum \
    patator ophcrack \
    dirsearch
ok "apt tools installed"

# ============================================================
# Feroxbuster (Rust binary from GitHub release)
# ============================================================
log "Installing feroxbuster..."
curl -sLo /tmp/feroxbuster.zip \
    https://github.com/epi052/feroxbuster/releases/latest/download/x86_64-linux-feroxbuster.zip
unzip -o /tmp/feroxbuster.zip feroxbuster -d /usr/local/bin
chmod +x /usr/local/bin/feroxbuster
ok "feroxbuster installed"

# ============================================================
# RustScan (from GitHub release)
# ============================================================
log "Installing rustscan..."
curl -sLo /tmp/rustscan.deb.zip \
    https://github.com/bee-san/RustScan/releases/download/2.4.1/rustscan.deb.zip
unzip -o /tmp/rustscan.deb.zip -d /tmp/rustscan_pkg
dpkg -i /tmp/rustscan_pkg/*.deb
ok "rustscan installed"

# ============================================================
# Go-based tools (using direct proxy to avoid storage.googleapis.com)
# ============================================================
install_go() {
    local pkg="$1" name="$2"
    log "Installing ${name}..."
    GOPROXY=direct GONOSUMCHECK='*' GONOSUMDB='*' \
        "${GO_BIN}" install "${pkg}" 2>/dev/null && ok "${name} installed" || err "${name}"
}

install_go "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "subfinder"
install_go "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" "nuclei"
install_go "github.com/projectdiscovery/httpx/cmd/httpx@latest" "httpx"
install_go "github.com/projectdiscovery/katana/cmd/katana@latest" "katana"
install_go "github.com/hahwul/dalfox/v2@latest" "dalfox"
install_go "github.com/lc/gau/v2/cmd/gau@latest" "gau"
install_go "github.com/tomnomnom/waybackurls@latest" "waybackurls"
install_go "github.com/tomnomnom/anew@latest" "anew"
install_go "github.com/tomnomnom/qsreplace@latest" "qsreplace"
install_go "github.com/Emoe/kxss@latest" "kxss"

# ============================================================
# Gem-based tools
# ============================================================
log "Installing gem tools..."
gem install wpscan evil-winrm 2>/dev/null | grep "Successfully" || true
GEM_BIN="$(gem environment | grep 'EXECUTABLE DIRECTORY' | awk '{print $NF}')"
[ -n "$GEM_BIN" ] && {
    ln -sf "${GEM_BIN}/wpscan"    /usr/local/bin/wpscan
    ln -sf "${GEM_BIN}/evil-winrm" /usr/local/bin/evil-winrm
}
ok "gem tools installed"

# ============================================================
# Pip-based tools (into hexstrike venv)
# ============================================================
log "Installing pip tools..."
"${PIP}" install \
    wafw00f arjun \
    volatility3 \
    autorecon \
    2>/dev/null | grep "Successfully installed" || true

"${PIP}" install git+https://github.com/Pennyw0rth/NetExec.git         2>/dev/null | grep "Successfully" || true
"${PIP}" install git+https://github.com/cddmp/enum4linux-ng.git        2>/dev/null | grep "Successfully" || true
"${PIP}" install git+https://github.com/lgandx/Responder.git           2>/dev/null | grep "Successfully" || true
"${PIP}" install git+https://github.com/devanshbatham/ParamSpider.git  2>/dev/null | grep "Successfully" || true
ok "pip tools installed"

# theHarvester requires Python 3.12+
log "Installing theHarvester (system python3.12)..."
python3.12 -m pip install git+https://github.com/laramies/theHarvester.git \
    --break-system-packages --ignore-installed PyYAML 2>/dev/null | grep "Successfully" || err "theHarvester"

# ============================================================
# Extra symlinks for venv tools
# ============================================================
log "Creating symlinks..."
ln -sf "${HEXSTRIKE_ENV}/bin/nxc" /usr/local/bin/crackmapexec
ln -sf "${HEXSTRIKE_ENV}/bin/vol" /usr/local/bin/volatility3
curl -sLo /usr/local/bin/hash-identifier \
    https://raw.githubusercontent.com/blackploit/hash-identifier/master/hash-id.py
chmod +x /usr/local/bin/hash-identifier
ok "symlinks created"

# ============================================================
# Summary
# ============================================================
echo ""
echo "========================================"
echo "  HexStrike Tool Installation Summary"
echo "========================================"
export PATH="$PATH:${GOPATH}/bin"
for t in nmap masscan rustscan subfinder nuclei fierce dnsenum autorecon theHarvester \
          responder nxc crackmapexec enum4linux-ng gobuster feroxbuster dirsearch ffuf \
          dirb httpx katana nikto sqlmap wpscan arjun paramspider dalfox wafw00f \
          hydra john hashcat medusa patator evil-winrm hash-identifier ophcrack \
          gdb radare2 binwalk checksec strings objdump volatility3 foremost steghide exiftool; do
    if which "$t" &>/dev/null; then
        printf "  %-22s \e[32m✓\e[0m\n" "$t"
    else
        printf "  %-22s \e[31m✗\e[0m\n" "$t"
    fi
done
echo ""
