# translate&go

[![CI](https://github.com/boundlessend/translate-go/actions/workflows/ci.yml/badge.svg)](https://github.com/boundlessend/translate-go/actions/workflows/ci.yml)
[![Release DMG](https://github.com/boundlessend/translate-go/actions/workflows/release.yml/badge.svg)](https://github.com/boundlessend/translate-go/actions/workflows/release.yml)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Ollama](https://img.shields.io/badge/Ollama-local-lightgrey)

`translate&go` is a small macOS utility for translating selected text through a local Ollama model.

The app works from the Dock or menu bar, listens for a global hotkey, copies the current selection, sends it to Ollama, and writes the translated result back to the system pasteboard.

## Features

- Swift 5.9+, SwiftUI, AppKit, Swift Concurrency.
- Global hotkey support through `HotKey`.
- Ollama `/api/generate` integration.
- Configurable model, target language, hotkey, Dock visibility, and menu bar visibility.
- English interface by default, with Russian available in Settings.
- Settings window and Q&A window.
- Local logging to `~/Library/Logs/translate-go/translator.log`.

## Requirements

- macOS 13 or newer.
- Xcode Command Line Tools or Xcode.
- Ollama installed locally.
- A downloaded Ollama model, for example:

```bash
ollama pull translategemma:12b
```

## Install

1. Open `translate-go.dmg`.
2. Drag `translate&go.app` to `Applications`.
3. Try to open the app from `Applications`.
4. If macOS blocks the app because it is unsigned, remove the quarantine attribute:

```bash
sudo xattr -rd com.apple.quarantine "/Applications/translate&go.app"
```

5. Open the app again.
6. Allow Accessibility access when prompted.
7. Install Ollama and download a translation model if you have not done that yet:

```bash
ollama pull translategemma:12b
```

8. Open Settings, choose the model, target language, interface language, and hotkey.

For a custom install path, replace `/Applications/translate&go.app` in the `xattr` command with the real `.app` path.

## Permissions

The app needs Accessibility permission to send `Command-C` and read the selected text flow.

Open:

```text
System Settings -> Privacy & Security -> Accessibility
```

Enable:

```text
/Applications/translate&go.app
```

If an old entry exists, remove it and add the app again from `/Applications`.

## Ollama

The app expects Ollama at:

```text
/usr/local/bin/ollama
```

On launch, it checks the local Ollama server and starts `ollama serve` if needed. On quit, it attempts to stop the configured model and local Ollama processes.

The default model name is:

```text
translategemma:12b
```

You can choose any installed Ollama model in Settings.

## Usage

1. Select text in any macOS app.
2. Press the configured global hotkey.
3. Wait until the translated text is written to the system pasteboard.
4. Paste the result with `Command-V`.

If the hotkey does nothing, check Accessibility permission and make sure the active app has selected text.


## Build

Build the SwiftPM executable:

```bash
swift build
```

Build a signed `.app` bundle:

```bash
./scripts/build_app.sh
```

The app bundle is written to:

```text
.build/translate&go.app
```

Build a DMG:

```bash
./scripts/build_dmg.sh
```

The DMG is written to:

```text
.build/translate-go.dmg
```

Install and run the app locally:

```bash
./run_app.command
```

## License

MIT License. See `LICENSE`.
