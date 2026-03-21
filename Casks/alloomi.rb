cask "alloomi" do
  version "Alloomi_v0.3.2_macOS_aarch64.dmg"
  sha256 "f14687869fa5c3df4825fd0a3bef2e1b532265f1668eacf81c6550a67ffdbabf"

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
