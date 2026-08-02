# Changelog

All notable changes to `touchpad-toggle` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
