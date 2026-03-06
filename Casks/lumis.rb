# typed: false
# frozen_string_literal: true

cask "lumis" do
  arch arm: "aarch64", intel: "x64"

  version "0.3.0"
  sha256 arm:   "REPLACE_WITH_ARM64_SHA256",
         intel: "REPLACE_WITH_X64_SHA256"

  url "https://github.com/melandlabs/release/releases/download/v#{version}/Lumis_#{version}_#{arch}.dmg",
      verified: "github.com/melandlabs/release/"

  name "Lumis"
  desc "AI-powered IM router and chat agent with multi-platform integration"
  homepage "https://github.com/melandlabs/release"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :monterey"

  app "Lumis.app"

  postflight do
    # Remove quarantine attribute to prevent Gatekeeper issues
    system_command "/usr/bin/xattr",
                   args: ["-r", "-d", "com.apple.quarantine", "#{appdir}/Lumis.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/com.lumis.app",
    "~/Library/Caches/com.lumis.app",
    "~/Library/Logs/com.lumis.app",
    "~/Library/Preferences/com.lumis.app.plist",
    "~/Library/Saved Application State/com.lumis.app.savedState",
  ]
end
