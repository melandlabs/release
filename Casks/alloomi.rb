cask "alloomi" do
  version "0.3.0"
  sha256 "c1141fe2b48977ee740ffdf781c20965a04e1164bd118e484260245c3e685444"

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
