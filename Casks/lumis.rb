cask "lumis" do
  version "0.3.0"
  sha256 "ae3b5713b3cc3c1035f138403aabbfa6ad7aa2e3053e1a2be3bdac8aca27fa80"

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
