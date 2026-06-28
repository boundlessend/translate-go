<p align="center">
  <img src="Assets/translate_go_readme_icon.png" alt="translate&go app icon" width="128">
</p>

<h1 align="center">translate&go</h1>

<p align="center">
  <strong>Language:</strong> EN | <a href="README.ru.md">RU</a> | <a href="README.fr.md">FR</a>
</p>

<p align="center">
  <strong>local text translation in one hotkey</strong>
</p>

<p align="center">
  <img alt="CI" src="https://github.com/boundlessend/translate-go/actions/workflows/ci.yml/badge.svg">
  <img alt="Release" src="https://github.com/boundlessend/translate-go/actions/workflows/release.yml/badge.svg">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-13%2B-111827">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-f05138">
  <img alt="license" src="https://img.shields.io/badge/license-BSD--3--Clause-2563eb">
</p>

`translate&go` is a small macOS app that translates selected text with a local Ollama model. Select text in any app, press your hotkey, and paste the translated result from the clipboard.

## Features

- Global hotkey for translating selected text (default `⌃⌥C`).
- Local Ollama translation.
- Automatic start, model preload, and shutdown of the local Ollama server.
- Model, target language, interface language, Dock, and menu bar settings.
- English interface by default, with Russian available in Settings.
- Settings and Q&A windows.

## Installation

1. Download and open `translate-go.dmg`.
2. Drag `translate&go.app` to `Applications`.
3. Open the app from `Applications`.
4. If macOS blocks the app because it is not notarized, run:

```bash
sudo xattr -rd com.apple.quarantine "/Applications/translate&go.app"
```

5. Open the app again and allow Accessibility access when prompted.
6. Optional: install Homebrew if you do not already have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

7. Install Ollama. If you already have Ollama, skip this step:

```bash
brew install ollama
```

8. Download a translation model:

```bash
ollama pull translategemma:12b
```

9. Open Settings, choose the model, target language, interface language, and hotkey.

## Permissions

Enable `translate&go` in:

```text
System Settings -> Privacy & Security -> Accessibility
```

The app needs this permission to copy selected text with `Command-C`.

## Usage

1. Select text in any macOS app.
2. Press the configured hotkey.
3. Wait until the translated text is written to the clipboard.
4. Paste the result with `Command-V`.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
