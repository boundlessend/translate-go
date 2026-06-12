<p align="center">
  <img src="Assets/translate_go_readme_icon.png" alt="иконка translate&go" width="128">
</p>

<h1 align="center">translate&go</h1>

<p align="center">
  <strong>Язык:</strong> <a href="README.md">EN</a> | RU | <a href="README.fr.md">FR</a>
</p>

<p align="center">
  <strong>локальный перевод текста по одному хоткею</strong>
</p>

<p align="center">
  <img alt="CI" src="https://github.com/boundlessend/translate-go/actions/workflows/ci.yml/badge.svg">
  <img alt="Release" src="https://github.com/boundlessend/translate-go/actions/workflows/release.yml/badge.svg">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-13%2B-111827">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-f05138">
  <img alt="license" src="https://img.shields.io/badge/license-BSD--3--Clause-2563eb">
</p>

`translate&go` — небольшое приложение для macOS, которое переводит выделенный текст через локальную модель Ollama. Выделите текст в любом приложении, нажмите хоткей и вставьте готовый перевод из буфера обмена.

## Возможности

- глобальный хоткей для перевода выделенного текста
- локальный перевод через Ollama
- настройки модели, языка перевода, языка интерфейса, Dock и menu bar
- английский интерфейс по умолчанию, русский доступен в настройках
- окна настроек и Q&A

## Установка

1. Скачайте и откройте `translate-go.dmg`.
2. Перетащите `translate&go.app` в `Applications`.
3. Откройте приложение из `Applications`.
4. Если macOS блокирует приложение, потому что оно не заверено Apple, выполните:

```bash
sudo xattr -rd com.apple.quarantine "/Applications/translate&go.app"
```

5. Откройте приложение снова и разрешите Accessibility, когда появится запрос.
6. Необязательно: установите Homebrew, если он ещё не установлен:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

7. Установите Ollama. Если она уже установлена, пропустите этот шаг:

```bash
brew install ollama
```

8. Скачайте модель для перевода:

```bash
ollama pull translategemma:12b
```

9. Откройте настройки, выберите модель, язык перевода, язык интерфейса и хоткей.

## Разрешения

Включите `translate&go` здесь:

```text
System Settings -> Privacy & Security -> Accessibility
```

Это разрешение нужно приложению, чтобы копировать выделенный текст через `Command-C`.

## Использование

1. Выделите текст в любом приложении macOS.
2. Нажмите настроенный хоткей.
3. Дождитесь, пока перевод появится в буфере обмена.
4. Вставьте результат через `Command-V`.

## Лицензия

BSD 3-Clause. См. [LICENSE](LICENSE).
