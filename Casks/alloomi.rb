cask "alloomi" do
  version "0.3.1"
  sha256 "13efc26f1bbf902c74116681074ad257c31c287d194dd3f9a240f6fa7b7d26ac"

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
