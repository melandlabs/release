cask "lumis" do
  version "0.3.0"
  sha256 "f2d05cd0ea23b686f437ed1435349a75a93cf7c821f834593f6ec350cfed2812"

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
