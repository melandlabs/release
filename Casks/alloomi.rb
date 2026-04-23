cask "alloomi" do
  if Hardware::CPU.intel?
    version "0.4.2"
    sha256 "0853688234adba60f8039692b46143d1e1be8c50554db0e0967308d6b40bc7b5"
    url "https://github.com/melandlabs/release/releases/download/v0.4.2/Alloomi_0.4.2_macOS_amd64.dmg"
  else
    version "0.4.2"
    sha256 "342795209e2c21f784bd80ee281f44d3b92ded99979fcd4905912d59a555b44f"
    url "https://github.com/melandlabs/release/releases/download/v0.4.2/Alloomi_0.4.2_macOS_aarch64.dmg"
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
