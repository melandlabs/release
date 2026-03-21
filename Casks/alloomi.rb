cask "alloomi" do
  version "0.3.1"
  sha256 "8f41e5dab98bd9ebf08b43a29cb7e9964d08239eaa92fb4361a20b88c87e19da"

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
