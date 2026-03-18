cask "alloomi" do
  version "0.3.0"
  sha256 "b83de2969ec99069cae95c133a1dd055fd3bc4c9fbd4679332f68dc3b6c2bfac"

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
