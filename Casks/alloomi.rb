cask "alloomi" do
  if Hardware::CPU.intel?
    version "0.3.6"
    sha256 "1329587690a0c41515ded1a1f1a7c6dae0c79eb65c9c2d6ecf61a4a09e2a05bc"
    url "https://github.com/melandlabs/release/releases/download/v0.3.6/Alloomi_0.3.6_macOS_amd64.dmg"
  else
    version "0.3.6"
    sha256 "26c093e52dfdbce2a6b57866d1383ff0470378c0b4e5d521c3d099df29083054"
    url "https://github.com/melandlabs/release/releases/download/v0.3.6/Alloomi_0.3.6_macOS_aarch64.dmg"
  end

  name "Alloomi"
  desc "Your proactive AI workspace. Nothing falls through the cracks."
  homepage "https://github.com/melandlabs/release"

  auto_updates true

  app "Alloomi.app"

  zap trash: [
    "~/Library/Application Support/com.alloomi.app",
    "~/Library/Logs/alloomi",
  ]
end
