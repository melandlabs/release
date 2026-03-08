cask "lumis" do
  version "0.3.0"
  sha256 "c7cbead4bc04726e3297479d7b0a42fed40299ef1a3965cd6f7daa122786b797"

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
