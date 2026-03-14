# typed: false
# frozen_string_literal: true

cask "azuukuy" do
  version "0.2.6"
  sha256 "baa4ad2c4448204793403250f39e595cfdff8e588028739a69b5e8189c6c891f"

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

                       GGUF_SRC="$TMPDIR/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf"
                       MARISA_DIR="$TMPDIR/base_n5_lm"

                       # Download models directly from Hugging Face (submodule sources)
                       MAX_RETRIES=10
                       for i in $(seq 1 $MAX_RETRIES); do
                         echo "[model-fetch] attempt $i / $MAX_RETRIES"

                         # Fetch GGUF model
                         if ! [ -f "$GGUF_SRC" ] || [ "$(stat -f%z "$GGUF_SRC")" -le 1000000 ]; then
                           rm -rf "$TMPDIR/zenz-v3.1-small-gguf"
                           git clone --depth 1 https://huggingface.co/Miwa-Keita/zenz-v3.1-small-gguf "$TMPDIR/zenz-v3.1-small-gguf" 2>&1 || true
                         fi

                         # Fetch marisa models
                         if ! ls "$MARISA_DIR"/*.marisa >/dev/null 2>&1; then
                           rm -rf "$MARISA_DIR"
                           git clone --depth 1 https://huggingface.co/Miwa-Keita/base_n5_lm "$MARISA_DIR" 2>&1 || true
                         fi

                         # Check both succeeded
                         if [ -f "$GGUF_SRC" ] && [ "$(stat -f%z "$GGUF_SRC")" -gt 1000000 ] && ls "$MARISA_DIR"/*.marisa >/dev/null 2>&1; then
                           echo "[model-fetch] success on attempt $i"
                           break
                         fi

                         if [ "$i" -eq "$MAX_RETRIES" ]; then
                           echo "[model-fetch] failed after $MAX_RETRIES attempts" >&2
                           rm -rf "$TMPDIR"
                           exit 1
                         fi
                         sleep 3
                       done

                       mkdir -p "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf"
                       mkdir -p "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/base_n5_lm"
                       cp "$GGUF_SRC" \
                          "#{Dir.home}/Library/Input Methods/AzuuKuy.app/Contents/Resources/zenz-v3.1-small-gguf/"
                       cp "$MARISA_DIR"/*.marisa \
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
