# Alloomi

Alloomi is your proactive AI workspace. Senses signals, orchestrates tasks, tracks results.

## Installation

### macOS

#### DMG (Recommended for macOS)

Download the latest release from [GitHub Releases](https://github.com/melandlabs/release/releases).

#### Homebrew

```bash
# If you have a manual installation, remove it first:
# rm -rf /Applications/Alloomi.app

# Add tap (using this repository)
brew tap melandlabs/alloomi https://github.com/melandlabs/release

# Install
brew install --cask alloomi

# Upgrade
brew upgrade --cask alloomi

# If install or upgrade fails with "App source is not there", clear cache and reinstall:
# rm -rf ~/Library/Caches/Homebrew/alloomi
# brew uninstall --cask alloomi
# brew install --cask alloomi
```

### Linux

#### Debian/Ubuntu

```bash
# Download .deb package from releases
sudo dpkg -i alloomi_*.deb
sudo apt-get install -f  # Install dependencies
```

### Windows

Coming Soon

## Installation Troubleshooting

MacOS prompts that 'Alloomi' cannot be opened because Apple cannot check if it contains malicious software. This issue is due to the Gatekeeper security feature in the macOS system preventing the application from running. To solve this issue, follow these steps:

Open 'System Preferences' and click 'Security and Privacy'. In the "General" tab, you will see a message: '"Alloomi" cannot be opened'. Click 'Open still'. Alternatively, you can click 'Open any method' to open your application. (You may need to use administrator privileges to open the application.)

If you don't want to perform these steps every time you open an application, you can add the application to the whitelist to run without being blocked. To add your application to the whitelist:

Open the terminal and run the following command:

```shell
xattr -d com.apple.quarantine /Applications/Alloomi.app/
```

## Development

This repository contains the CI/CD configuration for building and releasing Alloomi. The source code is in the [alloomi](https://github.com/melandlabs/alloomi) repository.
