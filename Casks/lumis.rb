cask "lumis" do
  version "0.3.0"
  sha256 "f9b559ee9df9ef7067c5c57d2b097c9b09d55bff1450621bf1b5c0cb04aa7d1e"

  url "https://github.com/melandlabs/release/releases/download/0.0.0-test/Lumis_0.3.0_aarch64.dmg",
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
