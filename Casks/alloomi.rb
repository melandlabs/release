cask "alloomi" do
  if Hardware::CPU.intel?
    version "0.3.8"
    sha256 "759b6b51e929daacc84429ecc5ef43085c0878e79f4c71f0390556c1bc2e77fb"
    url "https://github.com/melandlabs/release/releases/download/v0.3.8/Alloomi_0.3.8_macOS_amd64.dmg"
  else
    version "0.3.8"
    sha256 "1aca8b338b58a3c85cccb6f0802f17481da0907a4c909c04aeb0a251fa793f20"
    url "https://github.com/melandlabs/release/releases/download/v0.3.8/Alloomi_0.3.8_macOS_aarch64.dmg"
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
