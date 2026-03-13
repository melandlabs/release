# Alloomi

Alloomi is an AI-powered IM router and chat agent with multi-platform integration.

## Installation

### macOS

#### DMG (Recommended for macOS)

Download the latest release from [GitHub Releases](https://github.com/melandlabs/release/releases).

#### Homebrew

```bash
# Add tap (using this repository)
brew tap melandlabs/alloomi https://github.com/melandlabs/release

# Install
brew install --cask alloomi

# If you have a manual installation, remove it first:
# rm -rf /Applications/Alloomi.app
```

### Linux

#### Debian/Ubuntu

```bash
# Download .deb package from releases
sudo dpkg -i alloomi_*.deb
sudo apt-get install -f  # Install dependencies
```

## Development

This repository contains the CI/CD configuration for building and releasing Alloomi. The source code is in the [alloomi](https://github.com/melandlabs/alloomi) repository.
