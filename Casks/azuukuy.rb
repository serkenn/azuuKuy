# typed: false
# frozen_string_literal: true

cask "azuukuy" do
  version "0.2.1"
  sha256 "8274ec86dedc6b3982e82e622e04f84899179690bb58ac838265d08c25bc9dfc"

  url "https://github.com/serkenn/azuuKuy/releases/download/v#{version}/AzuuKuy.zip"
  name "AzuuKuy"
  desc "Japanese IME with real-time grammar checking (azooKey + MoZuku)"
  homepage "https://github.com/serkenn/azuuKuy"

  depends_on macos: ">= :ventura"

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
  end

  uninstall delete: "#{Dir.home}/Library/Input Methods/AzuuKuy.app"

  caveats <<~EOS
    AzuuKuy was installed to:
      ~/Library/Input Methods/AzuuKuy.app

    ---------------------------------------------------------------
    STEP 1: Download required model files (one-time, ~115 MB)
    ---------------------------------------------------------------
      git clone --depth 1 https://github.com/azooKey/azooKey-Desktop /tmp/azooKey-Desktop
      cp /tmp/azooKey-Desktop/azooKeyMac/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf \
         ~/Library/Input\ Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf/
      cp /tmp/azooKey-Desktop/azooKeyMac/Resources/base_n5_lm/*.marisa \
         ~/Library/Input\ Methods/AzuuKuy.app/Contents/Resources/base_n5_lm/

    ---------------------------------------------------------------
    STEP 2: Enable MeCab (grammar checking)
    ---------------------------------------------------------------
      brew install mecab mecab-ipadic   # if not already installed

    ---------------------------------------------------------------
    STEP 3: Register the IME
    ---------------------------------------------------------------
      1. Log out and log back in to macOS
      2. System Settings → Keyboard → Input Sources → Edit
      3. Click "+" → Japanese → select "azooKey" → Add
  EOS
end
