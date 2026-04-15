cask "alloomi" do
  if Hardware::CPU.intel?
    version "0.4.0"
    sha256 "e1a50b3c9968fe7a223cdac8bb395a3a80382acfeab4592d51abe42b8e9cc027"
    url "https://github.com/melandlabs/release/releases/download/v0.4.0/Alloomi_0.4.0_macOS_amd64.dmg"
  else
    version "0.4.0"
    sha256 "a85ce9d48757a1877eafee0bba70636fda94e14c0f8a76f6cfafa2c0b90570e1"
    url "https://github.com/melandlabs/release/releases/download/v0.4.0/Alloomi_0.4.0_macOS_aarch64.dmg"
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
