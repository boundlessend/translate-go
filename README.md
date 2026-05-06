# translate&go

`translate&go` is a small macOS utility for translating selected text through a local Ollama model.

The app works from the Dock or menu bar, listens for a global hotkey, copies the current selection, sends it to Ollama, and writes the translated result back to the system pasteboard.

## Features

- Swift 5.9+, SwiftUI, AppKit, Swift Concurrency.
- Global hotkey support through `HotKey`.
- Ollama `/api/generate` integration.
- Configurable model, target language, hotkey, Dock visibility, and menu bar visibility.
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

## Build

Build the SwiftPM executable:

```bash
swift build
```

Build a signed `.app` bundle:

```bash
./scripts/build_app.sh
```

Build a DMG:

```bash
./scripts/build_dmg.sh
```

Install and run the app locally:

```bash
./run_app.command
```

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

On launch, it checks the local Ollama server and starts `ollama serve` if needed. On quit, it stops the configured model and the Ollama processes it started.

## Distribution Notes

The local build script signs the app ad-hoc:

```bash
codesign --force --deep --sign -
```

For public distribution without Gatekeeper warnings, use an Apple Developer ID certificate and notarize the app through Apple.

## License

MIT License. See `LICENSE`.
