# Your Laptop's Touchpad Toggle

```bash
≡ Touchpad Toggle ≡
 
Touchpad status   ● Enabled
Shortcut status   ● Assigned → '<Super>q'
 
Invoke touchpad-toggle with one of these options:
├ --assign        Assign permanent keyboard shortcut; default: <Super>q
├ --help          Show description, usage and license
├ --reset         Hard reset input sub-system; elevated privileges required
├ --toggle        Toggle touchpad enable/disable
├ --unassign      Remove permanent keyboard shortcut
├ --version       Show version metadata
╰ --watch         Watch touchpad-toggle; updated every 2 seconds, quit with Ctrl+C
 
  Script path     /home/martin/bin/touchpad-toggle
```

#### Table of Contents
* [Purpose](#purpose)
* [Prerequisites](#prerequisites)
* [Functionality](#functionality)
* [Code](#code)
* [Installation](#installation)
* [Usage](#usage)
* [Troubleshooting](#troubleshooting)
* [Help](#help)
* [Appendix](#appendix)

## Purpose

*Touchpad Toggle* is a utility designed to solve a common usability issue on laptops: accidental cursor movement or clicks while typing, potentially overwriting already written and edited text.  
While many Desktop Environments offer a toggle switch in settings, accessing it is cumbersome and slow, *Touchpad Toggle* provides an instant mechanism to enable or disable the touchpad via a keyboard shortcut, accompanied by seamlessly integrated audible and visual feedback.  
Uniquely, *Touchpad Toggle* includes self-management features, allowing the script to install and remove its own global keyboard shortcut within the GNOME environment without requiring manual GUI configuration.  
If the touchpad stops responding because hardware layer freezes, the user may hard reset the input sub-system, invoking the script with the appropriate option `--reset` and elevated privileges.  
*Touchpad Toggle* is free of charge, ad-free and open source.  

### User Benefits

* **Accidental Input Prevention**  
*Touchpad Toggle* addresses the issue of accidental pointer movement while typing long documents, which can lead to cursor displacement and probable unintended text deletion.  

* **Feedback**  
*Touchpad Toggle* provides immediate audible and visual (notification) feedback upon state change with seamless GNOME desktop environment integration.

* **Ease of Management**  
*Touchpad Toggle* includes a Command Line Interface (CLI) for installation and status checks, removing the need for manual configuration of system files or navigating the depths of the system settings.  

## Prerequisites

To function correctly, the host system requires the following:  

### Operating System  

* Any  [Linux](https://www.linux.org) distribution, based on [Debian](https://www.Debian.org/) or [Ubuntu](https://www.ubuntu.com/) with Bourne-again shell (v4.0 or higher recommended for associative array support) or compatible, such as [ZORIN OS](https://www.zorin.com/).  
* [GNOME](https://www.gnome.org/) desktop environment and [Wayland](https://wayland.freedesktop.org/) display driver installed and in use.  

### Dependencies  

* `gsettings` (GLib command line interface, from `gsettings-desktop-schemas`)  
* `notify-send` (libnotify)  
* `realpath` (GNU coreutils)  
* **Audio player**  
   No configuration required — the script auto-detects what's available on your system at runtime.
  * PipeWire: `pw-play`  
  * PulseAudio: `paplay`  
  * ALSA: `aplay`  

## Functionality

The script operates on four main functional axes:  

1. **State Management**  
Reads and writes the `send-events` key in the `org.gnome.desktop.peripherals.touchpad` schema.  

2. **Keyboard Shortcut**  
Self-installs by programmatically parsing and modifying the complex `custom-keybindings` array in GNOME settings to add or remove itself as a global shortcut (default: `<Super>q`).  

3. **Feedback Loop**  
Provides immediate confirmation via system notifications and distinct audible cues for "Enabled" vs "Disabled" states.  

4. **Localization**  
Automatically detects the system language (`$LANG`) and serves interface text; currently in generic English, generic German, or Thai.  

## Code  

The script utilizes Bash scripting to interface with GNOME's `gsettings` and `dconf`. Below are key sections detailing the logic.  

### Toggle Logic  

This function handles the core purpose of the script. It uses `gsettings` to read the current state and flips it to deactivate and activate the touchpad.  

### Shortcut Assignment  

This is the most complex logic: GNOME stores custom keybindings as a list of paths. The script must safely append a new path without breaking existing ones.  

### Localization Architecture  

The external localization files use an associative array `MSG` to map keys to localized strings, ensuring easy translation updates. The logic probes presence of the fallback localization file and aborts if it is missing, prompting the user to ensure that language files are in same directory as the script.  

The default fallback language is generic English `[en]`.  

## Installation  

1. **Download**  
Save the script file (e.g., to `~/bin/touchpad-toggle`).

2. **Permissions**  
Make the script executable:

```bash
chmod +x ~/bin/touchpad-toggle
```

3. **Dependencies**  
Ensure required tools are installed (example for Debian/Ubuntu):  

```bash
sudo apt update
sudo apt install libnotify-bin pulseaudio-utils
``` 

4. **Audio Configuration (Advanced)**  

By default, the script auto-detects available sound files from standard Linux locations:  

* `/usr/share/sounds/freedesktop/stereo/`
* `/usr/share/sounds/ubuntu/stereo/`
* `/usr/share/sounds/zorin/stereo/`

  **Custom Sound Files**  
  To use custom sound files, uncomment and edit these variables near the top of the script:  

```bash
TOUCHPAD_DISABLED="/path/to/custom-disabled.oga"  
TOUCHPAD_ENABLED="/path/to/custom-enabled.oga"
```

Supported formats: `.oga`, `.ogg`, `.wav` (depending on your audio player).

## Usage

The script is designed to run autonomously. Manual invocation provides status readouts and management options.  

**Command** `./touchpad-toggle [OPTION]`

* Invalid or no option  
  Displays the current status of the touchpad and checks if the keyboard shortcut is active.  

* `./touchpad-toggle --assign`  
  Assigns a permanent keyboard shortcut (Default: `<Super>q`).  

* `./touchpad-toggle --help`  
  Opens the manual page.  

* `./touchpad-toggle --reset`  
  Hard reset input sub-system (requires elevated privileges)  

* `./touchpad-toggle --toggle`  
  Immediately toggles the touchpad state. This is the command used by the keyboard shortcut.  

* `./touchpad-toggle --unassign`  
  Removes the permanent keyboard shortcut associated with Touchpad Toggle.  

* `./touchpad-toggle --version`  
  Shows the version metadata: version number and build date.  

* `./touchpad-toggle --watch`  
  Loads `touchpad-toggle` with the `watch` command to allow monitoring the touchpad status. Updated every 2 seconds; quit with Ctrl+C.  

**Example Workflow**

1. Invoke `./touchpad-toggle --assign` to assign the keyboard shortcut.

2. Press `Super+Q` (`Windows Key + Q` or `Meta Key + Q`) to toggle the touchpad.

## Troubleshooting  

### Common Errors  

1. **Required system component is not installed**  
The script checks for `gsettings`, `notify-send`, and the audio player. Install the missing package shown in the error message.  
Alternatively, change the value of the variable `AUDIO_PLAYER="/usr/bin/paplay"` to the audio player already installed on your system.

2. **Audio does not play**  
Check the `AUDIO_PLAYER` variable path and ensure the sound files defined in `TOUCHPAD_ENABLED`/`DISABLED` actually exist.  

3. **Shortcut doesn't work**  
Invoke `./touchpad-toggle --assign` again. If it says "Assigned," check if another application is overriding `<Super>q`.  
Alternatively, change the value of the variable `KEY_BINDING="<Super>q"` to the vacant keyboard shortcut of your liking – after making sure, that another application is not overriding it as well.  

4. **Touchpad does no longer respond to toggle command**  
Invoking `./touchpad-toggle --reset` provides a critical fallback layer. While the standard toggle handles software states (GNOME settings), the reset option handles the kernel-level driver state, ensuring the user isn't stuck if the hardware layer freezes.  
To reset the input sub-system hard reset, elevated privileges are required.  
  *A Quick Technical Note*  
  Executing `udevadm trigger -s` essentially forces the kernel to "replay" the device addition events for all input devices. This causes the display server (Wayland/X11) to re-initialize the touchpad driver stack without requiring a full system reboot – a much more efficient way to handle hardware hiccups.  

### Debugging  

If the script fails to execute or notifications do not appear, utilize these debugging techniques:  

* **Execution Tracing (`set -x`)**  
Insert `set -x` at the top of the bash script (below the shebang) or invoke it via bash with the `-x` flag:  

```bash
bash -x ./touchpad-toggle --toggle
```

This forces the shell to print every command and its expanded arguments to standard output before execution, allowing you to trace exactly where a logic gate fails.  

* **Error Handling Modes (`set -euo pipefail`)**  

  * *Graceful Handling (Default)*  
    The script currently allows non-zero exit codes (like a failed `cat` command if a sysfs node is temporarily busy) to pass quietly without terminating the script.  

  * *Strict Handling*  
    Uncommenting `set -euo pipefail` forces the script to abort immediately if any command fails (`-e`), if an undefined variable is referenced (`-u`), or if a command within a pipeline fails (`-o pipefail`). Use this strictly for debugging syntax or pathing errors.  

    *Note*  
    Enabling this is useful for development but may cause the script to crash if an audio file is missing or a `gsettings` key is temporarily unavailable.  
    
## Logging

Following XDG Base Directory Specification, relevant script actions are logged to `~/.local/state/touchpad-toggle.log`. This includes:

* Touchpad toggle events (enable/disable)
* Keyboard shortcut assignments and removals
* Input subsystem resets
* Audio player detection failures
* Dependency check failures

### Log Entry Format

Touchpad-Toggle events are logged in this format:

```bash
[YYYY-MM-DD HH:MM:SS] [touchpad-toggle, vX.Y.Z] Message
```

**Example:**

```bash
[2026-08-01 17:45:33] [touchpad-toggle, v1.0.0-alpha] Keyboard shortcut <Super>q assigned.
[2026-08-01 17:45:32] [touchpad-toggle, v1.0.0-alpha] Touchpad disabled.
```

### Useful Commands

* View recent entries:*  

```bash
tail -f ~/.local/state/touchpad-toggle.log
```

* Search for errors:

```bash
grep "failed\|error" ~/.local/state/touchpad-toggle.log
```

* Rotate/clear logs (optional):

```bash
> ~/.local/state/touchpad-toggle/touchpad-toggle.log
```

### Privacy Note

Logs contain only script actions and state changes. No personal data, file contents, or keystroke patterns are recorded.

## Help  

The script includes a built-in "Man Page" style help viewer.

* Invoked via: `./touchpad-toggle --help`  
* It pipes localized documentation into the `less` pager, allowing for scrolling and searching within the help text.  
* If the script is invoked with an invalid option, it defaults to `display_info`, showing a concise usage summary.  

**Currently Implemented Localizations**  

* English, generic (default fallback)  
* German, generic  
* Thai  

## Appendix  

### Disclaimer  

Use at your own risk. Test thoroughly; your laptop's touchpad may unexpectedly stop responding due to variations and limitations in hardware and operating system.  
This script is provided “as is”; there is NO WARRANTY at all. This is free software: you are free to modify it to your needs and redistribute it (see MIT License).  
Due to ongoing development, this documentation might not reflect latest minor code changes.  
  
### Author  

Copyright (c) 2026 RML Tec Dev  
Contributions and feedback are welcome via [rmltecdev@pm.me](mailto:rmltecdev@pm.me?subject=Touchpad-Toggle)  

### License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.  
