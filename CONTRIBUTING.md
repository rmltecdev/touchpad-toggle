# Contributing to Touchpad Toggle

Thank you for your interest in improving Touchpad Toggle. This document outlines the process for submitting changes.

## Prerequisites

* GNOME desktop environment with Wayland
* Bash 4.0+
* `gsettings`, `realpath`
* An audio player (`pw-play`, `paplay`, or `aplay`)

## Development Setup

1. Clone the repository
2. Make the script executable: `chmod +x touchpad-toggle`
3. Run the smoke tests: `./tests/test.sh`
4. All tests must pass before submitting changes

## Guidelines

### Code Style

* Use 4-space indentation inside functions
* Comment in English above the code block being described
* Keep functions focused — one responsibility per function
* Use `local` variables inside functions

### Localization

* English (`.en`) is the fallback language and source of truth
* All message keys in `.en` must exist in `.de` and `.th`
* Run `./tests/test.sh` to verify localization key parity

### Commits

* Use conventional commit messages:
  * `feat:` new feature
  * `fix:` bug fix
  * `docs:` documentation only
  * `refactor:` code restructuring
  * `test:` test additions or changes
* Reference issues where applicable: `fix: toggle race condition (#12)`

### Testing

* Run `./tests/test.sh` before every commit
* Manual testing required for GNOME-dependent functions (toggle, shortcut, reset)
* Document any new manual test cases in your PR description

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes
4. Ensure smoke tests pass
5. Open a pull request with a clear description of changes and test results

## Reporting Issues

* Use GitHub Issues
* Include your distribution, GNOME version, and Bash version
* Attach relevant log entries from `~/.local/state/touchpad-toggle/touchpad-toggle.log`
