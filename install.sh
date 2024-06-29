#!/bin/bash

# Set variables
REPO="filiptronicek/cf-go-releases"
INSTALL_DIR="/usr/local/bin"

# Determine the architecture
ARCH=$(uname -m)
OS=$(uname -s)

if [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        FILE_SUFFIX="darwin-amd64.tar.gz"
    else
        FILE_SUFFIX="darwin-arm64.tar.gz"
    fi
elif [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        FILE_SUFFIX="linux-amd64.tar.gz"
    else
        FILE_SUFFIX="linux-arm64.tar.gz"
    fi
elif [[ "$OS" == "MINGW"* ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        FILE_SUFFIX="windows-amd64.tar.gz"
    else
        FILE_SUFFIX="windows-arm64.tar.gz"
    fi
else
    echo "Unsupported OS/architecture: $OS/$ARCH"
    exit 1
fi

# Fetch the latest release URL
DOWNLOAD_URL=$(curl -ks "https://api.github.com/repos/$REPO/releases/latest" | \
    grep "browser_download_url.*$FILE_SUFFIX" | \
    cut -d : -f 2,3 | tr -d \" | xargs)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Failed to find the download URL for the latest release."
    exit 1
fi

# Download the file
echo "Downloading $DOWNLOAD_URL..."
wget --no-check-certificate -O /tmp/go.tar.gz "$DOWNLOAD_URL"

# Create a temporary directory for extraction
TEMP_DIR=$(mktemp -d)
echo "Extracting to $TEMP_DIR..."
tar -xzf /tmp/go.tar.gz -C $TEMP_DIR || { echo "Extraction failed"; exit 1; }

# Find the Go binary
GO_BINARY=$(find $TEMP_DIR -type f -name 'go' -print -quit)
if [[ -z "$GO_BINARY" ]]; then
    echo "Go binary not found after extraction."
    exit 1
fi

# Move binary to install directory
echo "Installing to $INSTALL_DIR..."
sudo mv "$GO_BINARY" $INSTALL_DIR || { echo "Installation failed"; exit 1; }

# Cleanup
rm /tmp/go.tar.gz
rm -rf $TEMP_DIR

echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "Go installed successfully!"
