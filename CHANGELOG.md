# Changelog

All notable changes to `touchpad-toggle` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-08-11

### Added
* **Robust External Mouse Detection** — USB/Bluetooth pointer identification via `/proc/bus/input/devices` bus filtering (portable across hardware configurations)
* **GNOME 46 Compatibility** — Migration to `Clutter.get_default_backend().get_default_seat()` API
* **Color Customization** — Extended icon color scheme options (enabled/disabled/external-mouse modes)

### Changed
* **Visual Feedback** — External-mouse standby color changed from amber to teal (`#0CA5T`) for reduced visual distraction
* **Icon States** — Blue indicates active state (both touchpad and external mouse), teal indicates standby (mouse mode without detected device)
* **Extension Architecture** — Hardcoded script path replaced with template placeholder for installer substitution
* **Logging** — Reduced debug verbosity for production release

### Fixed
* **GNOME 46 API Migration** — `global.backend.get_default_seat()` → `Clutter.get_default_backend().get_default_seat()`
* **Device Enumeration** — `get_devices()` → `list_devices()` method call correction
* **Virtual Pointer Filtering** — Internal touchpad companion pointers excluded from external mouse detection via vendor cross-referencing
* **Hardware-Specific False Positives** — Framework laptop wireless radio control module (`32ac:0006`) correctly distinguished from external mice

### Security
* No changes to security posture from v1.1.0

---

## [1.1.0] - 2026-08-04
[... unchanged ...]

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
