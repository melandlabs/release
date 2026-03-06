cask "lumis" do
  version "0.3.0-alpha.1"
  sha256 "aabbccdd"

  url "https://github.com/melandlabs/release/releases/download/v#{version}/Lumis-#{version}-aarch64.dmg",
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
