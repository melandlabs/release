cask "alloomi" do
  version "0.3.0"
  sha256 "b6a90dd02ebbc4bc5b1c4ba5ce73eb0288a28206cdbe21ab076a9ae8cafebe5e"

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
