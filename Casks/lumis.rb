cask "lumis" do
  version "0.3.0"
  sha256 "9c9877a957cb0bebe2c5616d43260c643269faab8d588ddf0f4b253c70a2838f"

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
