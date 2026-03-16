cask "alloomi" do
  version "0.3.0"
  sha256 "0030d9072b7edcfd2cc16486f781b5f595bc09e0ad7d367d144f824d6291aa05"

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
