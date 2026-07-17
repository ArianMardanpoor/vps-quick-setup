#!/bin/bash

# ============================================================
# setup.sh - Auto installer for nice_params dependencies
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_sep() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================
# Step 1: Update system & install prerequisites
# ============================================================
print_sep
print_step "Step 1: Updating system and installing prerequisites..."
print_sep

sudo apt-get update -qq
sudo apt-get install -y -qq git ca-certificates python3 python3-venv python3-pip curl wget build-essential pkg-config libssl-dev

print_success "Prerequisites installed ✓"

# ============================================================
# Step 2: Check Go
# ============================================================
print_sep
print_step "Step 2: Checking Go installation..."
print_sep

if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install it first:"
    echo "    sudo apt-get install -y golang-go"
    exit 1
else
    print_success "Go found: $(go version) ✓"
fi

export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# ============================================================
# Step 3: Install Rust (for x8)
# ============================================================
print_sep
print_step "Step 3: Installing Rust (for x8 compilation)..."
print_sep

if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_success "Rust installed ✓"
else
    print_success "Rust already installed ✓"
fi

# ============================================================
# Step 4: Install x8
# ============================================================
print_sep
print_step "Step 4: Installing x8..."
print_sep

if command -v x8 &> /dev/null; then
    print_warning "x8 already installed, updating..."
    sudo rm -f /usr/local/bin/x8
fi

git clone --depth 1 https://github.com/sh1yo/x8 /tmp/x8-build
(cd /tmp/x8-build && cargo build --release && sudo cp ./target/release/x8 /usr/local/bin/)
rm -rf /tmp/x8-build

print_success "x8 installed ✓"
x8 --version || true

# ============================================================
# Step 5: Install fallparams
# ============================================================
print_sep
print_step "Step 5: Installing fallparams..."
print_sep

export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

go install github.com/ImAyrix/fallparams@latest

FALLPATH=$(find "$HOME/go/bin" -name "fallparams" 2>/dev/null | head -1)
if [ -n "$FALLPATH" ]; then
    sudo cp "$FALLPATH" /usr/local/bin/ 2>/dev/null || true
fi

if command -v fallparams &> /dev/null; then
    print_success "fallparams installed ✓"
else
    print_error "fallparams installation failed"
    exit 1
fi

fallparams -h 2>&1 | head -1 || true

# ============================================================
# Step 6: Install ffuf
# ============================================================
print_sep
print_step "Step 6: Installing ffuf..."
print_sep

if [ -d "/tmp/ffuf-build" ]; then
    rm -rf /tmp/ffuf-build
fi

git clone https://github.com/ffuf/ffuf /tmp/ffuf-build
(cd /tmp/ffuf-build && go get && go build)
sudo cp /tmp/ffuf-build/ffuf /usr/local/bin/
rm -rf /tmp/ffuf-build

if command -v ffuf &> /dev/null; then
    print_success "ffuf installed ✓"
else
    print_error "ffuf installation failed"
    exit 1
fi

ffuf -V || true

# ============================================================
# Step 7: Install dirsearch
# ============================================================
print_sep
print_step "Step 7: Installing dirsearch..."
print_sep

python3 -m venv ~/.venvs/dirsearch
source ~/.venvs/dirsearch/bin/activate
python -m pip install --upgrade pip -q
python -m pip install "git+https://github.com/maurosoria/dirsearch.git" -q

print_success "dirsearch installed ✓"
dirsearch --version || true

# ============================================================
# Step 8: Clone wordlist
# ============================================================
print_sep
print_step "Step 8: Fetching wordlist for nice_params..."
print_sep

if [ -d "$HOME/wordlist" ]; then
    print_warning "wordlist folder exists, updating..."
    (cd "$HOME/wordlist" && git pull)
else
    git clone https://github.com/ArianMardanpoor/wordlist.git "$HOME/wordlist"
fi

print_success "Wordlist downloaded: $HOME/wordlist ✓"

if ! grep -q "X8_WORDLIST_PATH" ~/.bashrc 2>/dev/null; then
    echo 'export X8_WORDLIST_PATH="$HOME/wordlist/param.txt"' >> ~/.bashrc
    echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
fi

print_success "Environment variables set ✓"

# ============================================================
# Step 9: nice_params installation check
# ============================================================
print_sep
print_step "Step 9: Checking nice_params..."
print_sep

if [ ! -f /usr/local/bin/nice_params ] && [ ! -f ~/go/bin/nice_params ]; then
    print_warning "nice_params not found! Compile it with:"
    echo "    go build -o nice_params main.go"
    echo "    sudo cp nice_params /usr/local/bin/"
else
    print_success "nice_params already installed ✓"
fi

# ============================================================
# Summary
# ============================================================
print_sep
print_success "All tools installed successfully! ✨"
print_sep
echo ""
echo "Installed tools:"
echo "   ✓ Go         → $(go version)"
echo "   ✓ x8         → $(which x8 2>/dev/null || echo '/usr/local/bin/x8')"
echo "   ✓ fallparams → $(which fallparams 2>/dev/null || echo '/usr/local/bin/fallparams')"
echo "   ✓ ffuf       → $(which ffuf 2>/dev/null || echo '/usr/local/bin/ffuf')"
echo "   ✓ dirsearch  → ~/.venvs/dirsearch/bin/dirsearch"
echo "   ✓ wordlist   → $HOME/wordlist/param.txt"
echo ""
echo "Next steps:"
echo "   1. Reload shell: source ~/.bashrc"
echo ""
echo "   2. Compile nice_params:"
echo "      go build -o nice_params main.go"
echo "      sudo cp nice_params /usr/local/bin/"
echo ""
echo "   3. Environment variable set:"
echo "      export X8_WORDLIST_PATH=\"$HOME/wordlist/param.txt\""
echo ""

source ~/.bashrc 2>/dev/null || true
