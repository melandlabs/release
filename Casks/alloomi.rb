cask "alloomi" do
  version "0.3.5"
  sha256 "3023d51d7396f18b35ce6e8e9bc25b32d140f1f99a1ab3a799c2b3882651f628"

  url "https://github.com/melandlabs/release/releases/download/v0.3.5/Alloomi_0.3.5_macOS_aarch64.dmg",
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
