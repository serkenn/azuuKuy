# typed: false
# frozen_string_literal: true

class Azuukuy < Formula
  desc "Japanese IME (azooKey) with real-time grammar checking via MoZuku"
  homepage "https://github.com/serkenn/azuuKuy"
  license "AGPL-3.0"

  url "https://github.com/serkenn/azuuKuy/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "11694d46d03ca26323cf3ccd73f829dfc2267c16678129fdbba40632640b956c"
  version "0.1.0"

  head "https://github.com/serkenn/azuuKuy.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "mecab"
  depends_on "mecab-ipadic"
  depends_on :macos => :ventura
  depends_on :xcode => ["16.3", :build]

  def install
    # Build the MoZukuGrammar static library
    system "cmake", "-B", "MoZukuGrammar/build",
                    "-S", "MoZukuGrammar",
                    "-DCMAKE_BUILD_TYPE=Release"
    system "cmake", "--build", "MoZukuGrammar/build"

    # Build azooKeyMac app via xcodebuild
    system "xcodebuild",
           "-project", "azooKeyMac.xcodeproj",
           "-scheme", "azooKeyMac",
           "-configuration", "Release",
           "-archivePath", "#{buildpath}/build/archive.xcarchive",
           "archive",
           "CODE_SIGNING_ALLOWED=NO",
           "CODE_SIGNING_REQUIRED=NO",
           "CODE_SIGN_IDENTITY="

    # Install the built app into the Homebrew prefix
    app = buildpath/"build/archive.xcarchive/Products/Applications/azooKeyMac.app"
    prefix.install app
  end

  def caveats
    <<~EOS
      AzuuKuy (azooKeyMac.app) has been built and placed in:
        #{opt_prefix}/azooKeyMac.app

      ---------------------------------------------------------------
      STEP 1: Install to Input Methods (requires admin privileges)
      ---------------------------------------------------------------
        sudo cp -r #{opt_prefix}/azooKeyMac.app "/Library/Input Methods/"
        sudo chmod -R 755 "/Library/Input Methods/azooKeyMac.app"

      ---------------------------------------------------------------
      STEP 2: Download required model files (one-time setup)
      ---------------------------------------------------------------
      The neural conversion model files are not included due to their
      size (~70 MB). Download them from azooKey-Desktop:

        git clone https://github.com/azooKey/azooKey-Desktop --recursive /tmp/azooKey-Desktop
        cp /tmp/azooKey-Desktop/azooKeyMac/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf \
           "/Library/Input Methods/azooKeyMac.app/Contents/Resources/zenz-v3.1-small-gguf/"
        cp /tmp/azooKey-Desktop/azooKeyMac/Resources/base_n5_lm/*.marisa \
           "/Library/Input Methods/azooKeyMac.app/Contents/Resources/base_n5_lm/"

      ---------------------------------------------------------------
      STEP 3: Enable the IME
      ---------------------------------------------------------------
        1. Log out and log back in to macOS
        2. Open System Settings → Keyboard → Input Sources → Edit
        3. Click "+" → Japanese → select "azooKey" → Add

      ---------------------------------------------------------------
      NOTE: Grammar checking requires MeCab (already installed).
      If grammar check does not work, run: mecab --version
    EOS
  end

  test do
    assert_predicate opt_prefix/"azooKeyMac.app", :directory?
  end
end
