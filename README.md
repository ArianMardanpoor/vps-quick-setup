# VPS Quick Setup for Web Reconnaissance

This guide provides step-by-step instructions to manually configure a fresh VPS environment for automated web vulnerability discovery. It covers the installation of essential reconnaissance and fuzzing tools, custom parameter hunting utilities, and wordlist configurations.

## Tools Included
- **x8**: Hidden parameter discovery tool.
- **fallparams**: Fast parameter discovery.
- **ffuf**: Fast web fuzzer.
- **dirsearch**: Web path scanner.
- **nice_params**: Custom parameter analysis utility.
- **Custom Wordlists**: Specialized payloads and parameter lists.

---

## Step 1: System Update & Prerequisites
First, update your package lists and install the core dependencies needed for downloading and building the tools.

```bash
sudo apt-get update -qq
sudo apt-get install -y -qq git ca-certificates python3 python3-pip curl wget build-essential pkg-config libssl-dev golang-go
```

## Step 2: Configure Go Environment
Set up the Go workspace and configure the default proxy to ensure smooth module downloads without timeout issues.

```bash
# Set Go environment variables
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# Set default Go proxy
go env -w GOPROXY="https://proxy.golang.org,direct"

# Fix any old proxy configurations in bashrc
sed -i 's/mirror-go.runflare.com/proxy.golang.org/g' ~/.bashrc 2>/dev/null || true

# Persist configurations
echo 'export GOPROXY="https://proxy.golang.org,direct"' >> ~/.bashrc
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.bashrc

source ~/.bashrc
```

## Step 3: Install Rust & Cargo
Rust is required to compile `x8`. Install it via `rustup`.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

## Step 4: Install Recon Tools

### 4.1. Install x8
Compile `x8` from the source using Cargo.

```bash
git clone --depth 1 https://github.com/sh1yo/x8 /tmp/x8-build
cd /tmp/x8-build
cargo build --release
sudo cp ./target/release/x8 /usr/local/bin/
rm -rf /tmp/x8-build
x8 --version
```

### 4.2. Install fallparams
Use Go to install `fallparams` and move it to your system binaries.

```bash
go install github.com/ImAyrix/fallparams@latest
sudo cp $(find "$HOME/go/bin" -name "fallparams" 2>/dev/null | head -1) /usr/local/bin/
sudo chmod +x /usr/local/bin/fallparams
```

### 4.3. Install ffuf
Install the popular web fuzzer `ffuf` using Go.

```bash
go install github.com/ffuf/ffuf/v2@latest
sudo cp $(find "$HOME/go/bin" -name "ffuf" 2>/dev/null | head -1) /usr/local/bin/
sudo chmod +x /usr/local/bin/ffuf
```

### 4.4. Install dirsearch
Install `dirsearch` globally using `pip3`.

```bash
pip3 install git+https://github.com/maurosoria/dirsearch.git --break-system-packages --ignore-installed requests
```

## Step 5: Setup Wordlists & Environment Variables
Clone the custom wordlist repository and set up the required environment variables for `x8`.

```bash
git clone https://github.com/ArianMardanpoor/wordlist.git "$HOME/wordlist"

# Add the wordlist path to bashrc for persistence
echo 'export X8_WORDLIST_PATH="$HOME/wordlist/param.txt"' >> ~/.bashrc
source ~/.bashrc
```

## Step 6: Install nice_params
Finally, clone and build the custom `nice_params` tool.

```bash
git clone https://github.com/ArianMardanpoor/nice_params.git
cd nice_params
go build -o nice_params main.go
sudo cp nice_params /usr/local/bin/
cd ..
```

---
**Happy Hunting!** 🚀
