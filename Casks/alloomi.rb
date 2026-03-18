cask "alloomi" do
  version "0.3.0"
  sha256 "e86d709a358660c53731c04e6b8172e67888226c8e808f4bc321e5dabc7ce955"

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
