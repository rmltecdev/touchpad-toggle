# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `--version` flag displaying version, build date, and script path
- Audio player auto-detection (PipeWire, PulseAudio, ALSA)
- Sound file auto-detection from standard freedesktop paths
- Runtime logging to `~/.local/state/touchpad-toggle/touchpad-toggle.log`
- User confirmation prompt for `--reset` before executing
- Smoke test suite (`tests/test.sh`)

### Changed
- `--reset` now accepts `j`/`J` for German "ja" confirmation
- Log directory moved to XDG-compliant `~/.local/state/`
- Dependency check skips audio player when auto-detection disables it

## [1.0.0-alpha] - 2026-08-01

### Added
- Toggle touchpad enable/disable via `gsettings` on GNOME/Wayland
- Self-managing keyboard shortcut assignment and removal
- Audible feedback using system sound files
- Visual feedback via GNOME notifications
- Input subsystem hard reset (`--reset`) with `udevadm`
- Multilingual support: English, German, Thai
- Man-page style help viewer via `--help`
- MIT License
