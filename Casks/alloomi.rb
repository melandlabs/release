cask "alloomi" do
  version "0.3.5"
  sha256 "ad0862b09b69096f88cb2cf5de9da7f4d723d55907116a4b80909733c59992ec"

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
