cask "lumis" do
  version "0.3.0"
  sha256 "95c6a094acea8066c6bc7195a3e1f70ed834b9d80f2ed2f7112796155f05f377"

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
