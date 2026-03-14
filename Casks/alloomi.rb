cask "alloomi" do
  version "0.3.0"
  sha256 "4a470255e9f15425fffa232c2833c480a6aa1b30930e6dc8a4993d2c68c10b47"

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
