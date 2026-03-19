cask "alloomi" do
  version "0.3.1"
  sha256 "d6aab2124df9aed7e7104198da1b796268854f5c081da77e38005cdc30fe79d7"

  url "https://github.com/melandlabs/release/releases/download/v0.3.1/Alloomi_0.3.1_macOS_aarch64.dmg",
      verified: "github.com/melandlabs/release"

  name "Alloomi"
  desc "AI-powered IM router and chat agent"
  homepage "https://github.com/melandlabs/release"

  auto_updates true

  app "Alloomi.app"

  zap trash: [
    "~/Library/Application Support/com.alloomi.app",
    "~/Library/Logs/alloomi",
  ]
end
