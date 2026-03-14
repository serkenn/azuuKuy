# typed: false
# frozen_string_literal: true

cask "azuukuy" do
  version "0.2.4"
  sha256 "265853ef69268c439301bf13ff9073d44e3d4248268b4e07b53d155faf517e02"

  url "https://github.com/serkenn/azuuKuy/releases/download/v#{version}/AzuuKuy.zip"
  name "AzuuKuy"
  desc "Japanese IME with real-time grammar checking (azooKey + MoZuku)"
  homepage "https://github.com/serkenn/azuuKuy"

  depends_on macos: ">= :ventura"
  depends_on formula: "mecab"
  depends_on formula: "mecab-ipadic"
  depends_on formula: "git-lfs"

  # Install to user-level Input Methods directory (no sudo required)
  artifact "AzuuKuy.app", target: "#{Dir.home}/Library/Input Methods/AzuuKuy.app"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/Library/Input Methods"
  end

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-rd", "com.apple.quarantine",
                          "#{Dir.home}/Library/Input Methods/AzuuKuy.app"],
                   sudo: false

    gguf_dest = "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf"
    unless File.exist?(gguf_dest) && File.size(gguf_dest) > 1_000_000
      system_command "/bin/bash",
                     args: ["-c", <<~SH],
                       set -e
                       export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
                       TMPDIR=$(mktemp -d)
                       git lfs install
                       git clone --depth 1 https://github.com/azooKey/azooKey-Desktop "$TMPDIR/azooKey-Desktop"
                       mkdir -p "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf"
                       mkdir -p "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/base_n5_lm"
                       cp "$TMPDIR/azooKey-Desktop/azooKeyMac/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf" \
                          "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf/"
                       cp "$TMPDIR/azooKey-Desktop/azooKeyMac/Resources/base_n5_lm/"*.marisa \
                          "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/base_n5_lm/"
                       rm -rf "$TMPDIR"
                     SH
                     sudo: false
    end
  end

  uninstall delete: "#{Dir.home}/Library/Input Methods/AzuuKuy.app"

  caveats <<~EOS
    AzuuKuy was installed to:
      ~/Library/Input Methods/AzuuKuy.app

    ---------------------------------------------------------------
    Register the IME
    ---------------------------------------------------------------
      1. Log out and log back in to macOS
      2. System Settings → Keyboard → Input Sources → Edit
      3. Click "+" → Japanese → select "azooKey" → Add
  EOS
end
