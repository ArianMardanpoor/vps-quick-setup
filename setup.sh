#!/bin/bash

# ============================================================
# setup.sh - نصب خودکار ابزارهای مورد نیاز برای nice_params
# ============================================================

set -e  # خروج در صورت خطا

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
# مرحله ۱: آپدیت سیستم و پیش‌نیازها
# ============================================================
print_sep
print_step "مرحله ۱: آپدیت سیستم و نصب پیش‌نیازها..."
print_sep

sudo apt-get update -qq
sudo apt-get install -y -qq git ca-certificates python3 python3-venv python3-pip curl wget build-essential pkg-config libssl-dev

print_success "پیش‌نیازها نصب شدند ✓"

# ============================================================
# مرحله ۲: نصب Rust (برای x8)
# ============================================================
print_sep
print_step "مرحله ۲: نصب Rust (برای کامپایل x8)..."
print_sep

if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_success "Rust نصب شد ✓"
else
    print_success "Rust از قبل نصب است ✓"
fi

# ============================================================
# مرحله ۳: نصب x8
# ============================================================
print_sep
print_step "مرحله ۳: نصب x8..."
print_sep

if command -v x8 &> /dev/null; then
    print_warning "x8 از قبل نصب است، در حال آپدیت..."
    sudo rm -f /usr/local/bin/x8
fi

git clone --depth 1 https://github.com/sh1yo/x8 /tmp/x8-build
(cd /tmp/x8-build && cargo build --release && sudo cp ./target/release/x8 /usr/local/bin/)
rm -rf /tmp/x8-build

print_success "x8 نصب شد ✓"
x8 --version || true

# ============================================================
# مرحله ۴: نصب fallparams
# ============================================================
print_sep
print_step "مرحله ۴: نصب fallparams..."
print_sep

if ! command -v go &> /dev/null; then
    print_warning "Go نصب نیست، در حال نصب..."
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm go1.21.5.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi

export PATH=$PATH:/usr/local/go/bin
go install github.com/ImAyrix/fallparams@latest

# پیدا کردن مسیر fallparams
FALLPATH=$(find "$HOME/go/bin" -name "fallparams" 2>/dev/null | head -1)
if [ -n "$FALLPATH" ]; then
    sudo cp "$FALLPATH" /usr/local/bin/ 2>/dev/null || true
fi

print_success "fallparams نصب شد ✓"
fallparams -h 2>&1 | head -1 || true

# ============================================================
# مرحله ۵: نصب ffuf
# ============================================================
print_sep
print_step "مرحله ۵: نصب ffuf..."
print_sep

if [ -d "/tmp/ffuf-build" ]; then
    rm -rf /tmp/ffuf-build
fi

git clone https://github.com/ffuf/ffuf /tmp/ffuf-build
(cd /tmp/ffuf-build && go get && go build)
sudo cp /tmp/ffuf-build/ffuf /usr/local/bin/
rm -rf /tmp/ffuf-build

print_success "ffuf نصب شد ✓"
ffuf -V || true

# ============================================================
# مرحله ۶: نصب dirsearch
# ============================================================
print_sep
print_step "مرحله ۶: نصب dirsearch..."
print_sep

python3 -m venv ~/.venvs/dirsearch
source ~/.venvs/dirsearch/bin/activate
python -m pip install --upgrade pip -q
python -m pip install "git+https://github.com/maurosoria/dirsearch.git" -q

print_success "dirsearch نصب شد ✓"
dirsearch --version || true

# ============================================================
# مرحله ۷: کلون کردن وردلیست
# ============================================================
print_sep
print_step "مرحله ۷: دریافت وردلیست nice_params..."
print_sep

if [ -d "$HOME/wordlist" ]; then
    print_warning "پوشه wordlist از قبل وجود دارد، در حال آپدیت..."
    (cd "$HOME/wordlist" && git pull)
else
    git clone https://github.com/ArianMardanpoor/wordlist.git "$HOME/wordlist"
fi

print_success "وردلیست دریافت شد: $HOME/wordlist ✓"

# تنظیم متغیر محیطی برای nice_params
if ! grep -q "X8_WORDLIST_PATH" ~/.bashrc 2>/dev/null; then
    echo 'export X8_WORDLIST_PATH="$HOME/wordlist/param.txt"' >> ~/.bashrc
    echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
fi

print_success "متغیرهای محیطی تنظیم شدند ✓"

# ============================================================
# مرحله ۸: نصب nice_params (ابزار خودت)
# ============================================================
print_sep
print_step "مرحله ۸: نصب nice_params..."
print_sep

if [ ! -f /usr/local/bin/nice_params ] && [ ! -f ~/go/bin/nice_params ]; then
    print_warning "nice_params پیدا نشد! لطفاً فایل main.go رو کامپایل کن:"
    echo "    go build -o nice_params main.go"
    echo "    sudo cp nice_params /usr/local/bin/"
else
    print_success "nice_params از قبل نصب است ✓"
fi

# ============================================================
# جمع‌بندی
# ============================================================
print_sep
print_success "✨ همه ابزارها با موفقیت نصب شدند! ✨"
print_sep
echo ""
echo "📋 خلاصه ابزارهای نصب شده:"
echo "   ✓ x8         → $(which x8 2>/dev/null || echo '/usr/local/bin/x8')"
echo "   ✓ fallparams → $(which fallparams 2>/dev/null || echo '/usr/local/bin/fallparams')"
echo "   ✓ ffuf       → $(which ffuf 2>/dev/null || echo '/usr/local/bin/ffuf')"
echo "   ✓ dirsearch  → ~/.venvs/dirsearch/bin/dirsearch"
echo "   ✓ wordlist   → $HOME/wordlist/param.txt"
echo ""
echo "💡 نکات:"
echo "   1. برای استفاده از nice_params:"
echo "      go build -o nice_params main.go"
echo "      sudo cp nice_params /usr/local/bin/"
echo ""
echo "   2. متغیر محیطی تنظیم شد:"
echo "      export X8_WORDLIST_PATH=\"$HOME/wordlist/param.txt\""
echo ""
echo "   3. ری‌لود شل یا اجرا کن: source ~/.bashrc"
echo ""

# سورس کردن خودکار
source ~/.bashrc 2>/dev/null || true
