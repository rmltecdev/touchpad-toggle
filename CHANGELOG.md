# Changelog

All notable changes to `touchpad-toggle` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-04

### Added
* **GNOME Shell Extension** — Optional top bar status indicator with three-state visual representation (enabled/disabled/external-mouse)
* **Extension Settings** — User-configurable colored/monochrome icon toggle via GNOME Extensions app preferences
* **Automated Installer** — `install.sh` with dependency checking, PATH handling, and optional extension deployment
* **Build Date Metadata** — `BUILD_DATE` variable in script header for release tracking
* **Schema Isolation** — Local GSettings schema compilation per GNOME extension best practices (no global registry pollution)

### Changed
* **Visual Feedback** — Removed `notify-send` calls from `toggle_touchpad()`; extension icon now provides persistent status
* **Extension Architecture** — Refactored to use `this.getSettings()` for proper local schema access (fixes loading errors)
* **Color Scheme** — Adjusted icon colors for improved contrast: green (enabled), red (disabled), yellow (external-mouse)
* **Installer Logic** — Schema compilation moved from global to local extension directory
* **Documentation** — README updated with installation guide and extension features
* **Dependency Table** — Removed `libnotify-bin` requirement; audio player remains optional

### Fixed
* **Extension Loading** — GSettings schema not found errors due to improper `Gio.Settings` instantiation
* **Global Schema Pollution** — Unnecessary registration in system-wide schema registry
* **Color Visibility** — Icon colors invisible on light themes (added mono/color toggle as fallback)
* **Installer Reliability** — `gschemas.compiled` generation failing due to wrong schema path
* **Test Suite** — Schema XML detection using unreliable glob patterns

### Deprecated
* **`--install_indicator`** — CLI option from main script (extension installation now handled exclusively by `install.sh`)

### Security
* No privilege escalation beyond required `sudo` for input subsystem reset (`--reset`)
* Extensions remain isolated without global schema registration
* No automatic PATH manipulation without explicit user consent

---

## [1.0.1] - 2026-08-02

### Fixed
* **Localization coverage** — Added 4 previously missing MSG[] keys to all locale files:
  - `error_no_audio` — Audio player detection error
  - `warn_no_sound` — System sound file warning
  - `warn_no_sound_hint` — Custom sound path configuration hint
* **Code cleanup** — Removed orphan keys (`assign_gnome_name`, `reset_sudo_hint`) that no longer existed in script

### Improved
* **Testing** — Implemented bidirectional localization validation (sections 6a–6c):
  - Script→Locale alignment verification
  - Fallback→Translation coverage check
  - Orphan/detritus key detection
* **User guidance** — Enhanced `warn_no_sound_hint` with actionable customization info

### Changed
* Replaced `${MSG[set_gnome_name]}` with `${SCRIPT_NAME^}` (hardcoded GNOME settings label)

### Documentation
* Added `MESSAGES.md` — Localization key reference catalog
* Added `.git/hooks/pre-commit` template for local CI enforcement

### Other
* Bumped version metadata from 1.0.0 → 1.0.1

---

## [1.0.0] - 2026-08-02

### Added
* Initial release of touchpad-toggle utility
* GNOME/Wayland touchpad enable/disable via keyboard shortcut
* CLI management (`--assign`, `--toggle`, `--unassign`, `--reset`, `--watch`, `--version`)
* Audible and visual notification feedback
* Localization support (EN, DE, TH)
* Input subsystem reset functionality (`udevadm trigger`)
* Comprehensive smoke test suite (`tests/test.sh`)
* Pre-commit hook template for local CI

### License
* MIT License — Copyright (c) 2026 RML Tec Dev
