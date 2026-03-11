cask "lumis" do
  version "0.3.0"
  sha256 "efe1c9f22aa4a33902624d52e8b02aa61d4cd86a36037f527ef17d71bec1820e"

  url "https://github.com/melandlabs/release/releases/download/0.0.0-test/Lumis_0.3.0_macOS_aarch64.dmg",
      verified: "github.com/melandlabs/release"

  name "Lumis"
  desc "AI-powered IM router and chat agent"
  homepage "https://github.com/melandlabs/release"

  auto_updates true

  app "Lumis.app"

  zap trash: [
    "~/Library/Application Support/com.lumis.lumis",
    "~/Library/Logs/lumis",
  ]
end
