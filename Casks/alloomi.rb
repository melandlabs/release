cask "alloomi" do
  version "0.3.0"
  sha256 "b61673b8a7efaa5607fa3cc5a1e98ba1175f94d2231af8f7d8955c578fdd95f9"

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
