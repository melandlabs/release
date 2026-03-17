cask "alloomi" do
  version "0.3.0"
  sha256 "e175e4cf4d6adc43b87c73e5d7436635f1c65b55f36b430da932668ea88932bd"

  url "https://github.com/melandlabs/release/releases/download/v0.3.0/Alloomi_0.3.0_macOS_aarch64.dmg",
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
