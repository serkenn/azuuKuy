# AzuuKuy

[azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop)（macOS向け日本語IME）に[MoZuku](https://github.com/t3tra-dev/MoZuku)の文法チェック機能を統合したプロジェクトです。

ニューラルかな漢字変換エンジン「Zenzai」による高精度な変換に加え、**変換確定後にリアルタイムで文法エラーを検出・警告**します。

**現在アルファ版のため、動作は一切保証できません**。

## 追加機能（MoZuku統合）

変換を確定すると、カーソル付近に文法警告がトースト表示されます。

対応する文法ルール：

- **ら抜き言葉**（例：「食べれる」→「食べられる」）
- **同じ助詞の重複**（例：「〜がが〜」）
- **不正な助詞の連続**
- **読点の使いすぎ**（1文中に4つ以上）
- **接続詞の繰り返し**

## 動作環境

- macOS 13.0以上
- MeCab + mecab-ipadic（文法チェックに必要）

## インストール

### 方法1: Homebrew Cask（推奨・Xcode不要）

```bash
brew tap serkenn/azuukuy https://github.com/serkenn/azuuKuy
brew install --cask azuukuy
```

インストール後、`brew info --cask azuukuy` に表示される手順（モデルファイルの配置・IMEの有効化）を実行してください。

### 方法2: ソースからビルド（Xcode必要）

#### MeCabのインストール（必須）

```bash
brew install mecab mecab-ipadic
```

#### MoZukuGrammarライブラリのビルド

```bash
HOST_ARCH=$(uname -m)
cmake -B MoZukuGrammar/build -S MoZukuGrammar \
   -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_OSX_ARCHITECTURES="$HOST_ARCH" \
   -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
cmake --build MoZukuGrammar/build
```

#### azooKeyMacのビルド・インストール

```bash
./install.sh
```

その後、以下の手順で利用できます：

1. macOSからログアウトし、再ログイン
2. 「設定」→「キーボード」→「入力ソース」を編集 → 「+」→「日本語」→ azooKey を追加

## 開発ガイド

### リポジトリ構造

```
AzuuKuy/
├── azooKeyMac/              IMEメインコード
│   ├── GrammarChecker/      MoZuku統合コード（文法チェックSwiftラッパー・警告UI）
│   ├── InputController/     キー入力・変換ロジック
│   └── ...
├── azooKeyMac.xcodeproj/    Xcodeプロジェクト
├── Core/                    Swift Package（変換エンジン・設定）
├── MoZukuGrammar/           文法チェッカーC++ライブラリ
│   ├── include/             ヘッダー（mozuku_bridge.h含む）
│   ├── src/                 ソース（MeCabのみ依存）
│   └── CMakeLists.txt
└── .github/workflows/       CI設定
```

### 推奨環境

- macOS 15+
- Xcode 16.3+
- MeCab（`brew install mecab mecab-ipadic`）

### ビルド手順

```bash
# 1. MoZukuGrammarライブラリをビルド
HOST_ARCH=$(uname -m)
cmake -B MoZukuGrammar/build -S MoZukuGrammar \
   -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_OSX_ARCHITECTURES="$HOST_ARCH" \
   -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
cmake --build MoZukuGrammar/build

# 2. Xcodeでazooキーをビルド
open azooKeyMac.xcodeproj
# または
./install.sh
```

### モデルファイルについて

変換精度に関わる重みファイル（`*.gguf`, `*.marisa`）はサイズが大きいためリポジトリに含まれていません。

元リポジトリ [azooKey/azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop) からGit LFSでダウンロードしてください：

```bash
# 元リポジトリからファイルを取得する例
git clone https://github.com/azooKey/azooKey-Desktop --recursive
cp azooKey-Desktop/azooKeyMac/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf \
   azooKeyMac/Resources/zenz-v3.1-small-gguf/
cp azooKey-Desktop/azooKeyMac/Resources/base_n5_lm/*.marisa \
   azooKeyMac/Resources/base_n5_lm/
```

### トラブルシューティング

**文法チェックが動作しない場合**

- MeCabがインストールされているか確認：`mecab --version`
- `MoZukuGrammar/build/libmozuku_grammar.a` が存在するか確認

**ビルドが失敗する場合**

- XcodeのGUI上で「Team ID」を Personal Team に変更してください
- `azooKeyMac.xcodeproj` → Signing & Capabilities → Team を変更

**変換精度が低い場合**

- `azooKeyMac/Resources/zenz-v3.1-small-gguf/ggml-model-Q5_K_M.gguf` が70MB程度のファイルか確認してください（Git LFSが必要）

## ライセンス

- azooKey-Desktop: [MIT License](https://github.com/azooKey/azooKey-Desktop/blob/main/LICENSE)
- MoZuku: [AGPL-3.0 License](https://github.com/t3tra-dev/MoZuku/blob/main/LICENSE)

このリポジトリはAGPL-3.0に従います。

## 元プロジェクト

- [azooKey/azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop) — macOS日本語IME
- [t3tra-dev/MoZuku](https://github.com/t3tra-dev/MoZuku) — 日本語文法チェッカー（LSP）
