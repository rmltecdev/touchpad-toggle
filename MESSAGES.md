# Message Keys Reference

Localization key catalog for `touchpad-toggle`. Each entry documents
the key, its purpose, context of use, and visibility.

## Visibility Codes

| Code | Meaning |
|------|---------|
| **CLI** | Printed to terminal stdout/stderr |
| **GUI** | Sent via `notify-send` (GNOME notification) |
| **Internal** | Used internally (logging, config values) |

---

## Key Catalog

### Header & Branding

| Key | Visibility | Description |
|-----|-----------|-------------|
| `header` | CLI | ASCII banner displayed at script start |

### Help System

| Key | Visibility | Description |
|-----|-----------|-------------|
| `help_open` | CLI | Text printed before help content pipes to `less` |
| `help_text` | CLI | Full man-page-style documentation body |
| `help_close` | CLI | Text printed after `less` exits |

### Notifications (Toggle Feedback)

| Key | Visibility | Description |
|-----|-----------|-------------|
| `notif_title` | GUI | Notification title for toggle events |
| `notif_disabled` | GUI | Notification body when touchpad is disabled |
| `notif_enabled` | GUI | Notification body when touchpad is enabled |

### Status Display

| Key | Visibility | Description |
|-----|-----------|-------------|
| `info_status_label` | CLI | Label preceding touchpad state in status output |
| `info_enabled` | CLI | Text shown when touchpad is enabled |
| `info_disabled` | CLI | Text shown when touchpad is disabled |
| `info_invoke` | CLI | Instructional header listing available CLI options |
| `info_desc_assign` | CLI | Description for `--assign` option |
| `info_desc_help` | CLI | Description for `--help` option |
| `info_desc_reset` | CLI | Description for `--reset` option |
| `info_desc_toggle` | CLI | Description for `--toggle` option |
| `info_desc_remove` | CLI | Description for `--unassign` option |
| `info_desc_version` | CLI | Description for `--version` option |
| `info_opt_watch` | CLI | Description for `--watch` option |
| `info_path` | CLI | Label for script path display |
| `info_version` | CLI | Label for version display |
| `info_build_date` | CLI | Label for build date display |

### Keyboard Shortcut Assignment

| Key | Visibility | Description |
|-----|-----------|-------------|
| `keyb_manager` | CLI | Section title for shortcut management |
| `assign_preparing` | CLI | Status message before assignment begins |
| `assign_success` | CLI | Confirmation message after successful assignment |
| `assign_instructions` | CLI | Post-assignment usage guidance |
| `assign_abort_title` | CLI | Warning title when shortcut already exists |
| `assign_abort_msg` | CLI | Warning body when shortcut already exists |

### Keyboard Shortcut Removal

| Key | Visibility | Description |
|-----|-----------|-------------|
| `rem_preparing` | CLI | Status message before removal begins |
| `rem_found` | CLI | Message confirming existing shortcut was located |
| `rem_not_found` | CLI | Warning when no shortcut to remove |
| `rem_nothing` | CLI | Confirmation that nothing was changed |
| `rem_success` | CLI | Confirmation message after successful removal |

### Shortcut Status Check

| Key | Visibility | Description |
|-----|-----------|-------------|
| `check_status_label` | CLI | Label preceding shortcut status |
| `check_assign` | CLI | Text shown when shortcut is assigned |
| `check_not_detected` | CLI | Text shown when no shortcut is found |
| `check_invoke_hint` | CLI | Instructional hint when shortcut is missing |

### Reset Input Subsystem

| Key | Visibility | Description |
|-----|-----------|-------------|
| `reset_confirm_warning` | CLI | Warning before destructive reset action |
| `reset_confirm_prompt` | CLI | Y/N prompt text |
| `reset_aborted` | CLI | Message when user cancels reset |
| `sudo_required` | CLI | Warning when elevated privileges unavailable |
| `reset_preparing` | CLI | Status message before reset executes |
| `reset_success` | CLI | Confirmation after successful reset |
| `reset_fail` | CLI | Error message if reset fails |

### Audio System

| Key | Visibility | Description |
|-----|-----------|-------------|
| `error_no_audio` | CLI/stderr | Error when no audio player is detected |
| `warn_no_sound` | CLI | Warning when system sound files not found |
| `warn_no_sound_hint` | CLI | Guidance for configuring custom sound paths |
| `install_hint` | CLI/stderr | Generic hint for installing missing dependencies |

### Dependencies

| Key | Visibility | Description |
|-----|-----------|-------------|
| `error_tool` | CLI/stderr | Error message template for missing tool |

### Watch Mode

| Key | Visibility | Description |
|-----|-----------|-------------|
| `watch_start` | CLI | Message before entering watch mode |
| `watch_stop` | CLI | Message after exiting watch mode |

---

## Maintenance Notes

* Update this file whenever a `MSG[]` key is added, removed, or repurposed.
* The test suite (sections 6a–6c) enforces bidirectional key alignment.
* New translations must mirror all keys defined in the `.en` fallback file.
