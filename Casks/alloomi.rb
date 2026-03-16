cask "alloomi" do
  version "0.3.0"
  sha256 "2c425257e17252e9d034cfafb7dd59f8f8021cc0cd7ad4cb9fe439186187166e"

  url "https://github.com/melandlabs/release/releases/download/0.0.0-test/Alloomi_0.3.0_macOS_aarch64.dmg",
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
