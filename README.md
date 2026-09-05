# Your Laptop's Touchpad Toggle

```bash
≡ Touchpad Toggle ≡
 
Touchpad        ▲ Conditional
Mouse           ● Detected
Mouse mode      ● Enabled
Shortcut        ● Assigned → '<Super>q'
 
Invoke touchpad-toggle with one of these options:
├ --assign      Assign permanent keyboard shortcut; default: <Super>q
├ --help        Show description, usage and license
├ --reset       Hard reset input sub-system; elevated privileges required
├ --toggle      Toggle touchpad enable/disable
├ --mouse-mode  Toggle mouse mode enable/disable
├ --unassign    Remove permanent keyboard shortcut
├ --version     Show version information
╰ --watch       Watch touchpad-toggle; updated every 2 seconds, quit with Ctrl+C
 
  Script path   /home/martin/.local/bin/touchpad-toggle
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

*Touchpad Toggle* solves a common usability issue on laptops: accidental cursor movement or clicks while typing, which can displace the cursor and cause unintended text deletion or overwriting.  
While many Desktop Environments offer touchpad toggle switches in settings, accessing them is cumbersome and slow. Touchpad Toggle provides instant mechanisms: a keyboard shortcut for quick enable/disable, and an intelligent "mouse mode" that automatically manages the touchpad based on whether an external mouse is connected or disconnected.  
All accompanied by seamless audible and visual feedback.  

### Unique features include

#### Self-managing Keyboard Shortcut

Install and remove global GNOME shortcut without manual GUI configuration.  

#### Intelligent Mouse Mode

Toggle automatic touchpad management: disables only when external mouse connected, re-enables on disconnect. Perfect for docking stations.  

#### GNOME Shell Extension

Optional top bar indicator showing real-time state (enabled, disabled, or mouse-conditional) with left/right-click actions.  

#### Hard Reset Fallback

If the touchpad stops responding due to hardware-layer freezes, recover via `--reset` with elevated privileges.  

#### System Sounds Auto-detect

Auto-detects audio players and sound themes across distributions.  

#### Zero Bloat

Free, ad-free, and open source.  

### User Benefits

#### Accidental Input Prevention

Eliminates cursor displacement while typing long documents.  

#### Audible and Visual Feedback

Distinct sound cues confirm enabled vs. disabled state changes.  

#### Visual Indicator (Optional)

GNOME top bar indicator icon shows current state of touchpad and mouse mode without transient notifications.  
The visual indicator can be displayed in color or monochrome via the GNOME extension settings.  

##### Known Limitations

* **External Mouse Detection Delay**  
  Bluetooth devices may require 5 – 15 seconds to fully enumerate after connection due to pairing handshake timing. USB devices connect instantly.  

* **Wayland Only**  
  X11 support is experimental; external mouse detection relies on Wayland's seat API.

#### CLI Management

Status checks and shortcut configuration without navigating system settings.  

## Prerequisites

To function correctly, the host system requires the following:  

### Operating System  

* Any  [Linux](https://www.linux.org) distribution, based on [Debian](https://www.Debian.org/) or [Ubuntu](https://www.ubuntu.com/) with Bourne-again shell (v4.0 or higher recommended for associative array support) or compatible, such as [ZORIN OS](https://www.zorin.com/).  
* [GNOME](https://www.gnome.org/) desktop environment and [Wayland](https://wayland.freedesktop.org/) display driver installed and in use.  
* *Note:* X11 is supported for legacy purposes but not officially tested.  

### Dependencies  

* `gsettings` (GLib command line interface glib2.0, from `gsettings-desktop-schemas`); GNOME configuration interface  
* `realpath` (GNU coreutils) for path resolution  
* **Sound feedback (auto-detected)**  
  No configuration required; the script auto-detects the available audio player at runtime.  
  * **PipeWire:**  
    `pw-play` (from `pipewire-audio`)  
  * **PulseAudio:**  
    `paplay` (from `pulseaudio-utils`)  
  * **ALSA:**  
    `aplay` (from `alsa-utils`)  

## Functionality

The script operates on four main functional axes:  

**1. State Management**  
     Reads and writes the `send-events` key in the `org.gnome.desktop.peripherals.touchpad` schema.  

**2. Keyboard Shortcut**  
     Self-installs by programmatically parsing and modifying the complex `custom-keybindings` array in GNOME settings to add or remove itself as a global shortcut (default: `<Super>q`).  

**3. Feedback Loop**  
     Provides immediate confirmation via distinct audible cues for "Enabled" vs "Disabled" states.  

**4. Localization**  
     Automatically detects the system language (`$LANG`) and serves interface text; currently in generic English, generic German, or Thai.  

**5. Intelligent Mouse Mode**  
     Activates conditional state management: touchpad disabled-on-external-mouse with automatic re-enablement on device disconnect. The optional GNOME extension provides audio- visual status indicators and click-through interaction for all three modes. All functions operate with USB and Bluetooth devices likewise.  

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

### Automatic Installation

The `install.sh` script automates the installation procedure:  

1.  Clone or download the repository  

```bash
   git clone https://github.com/rmltecdev/touchpad-toggle
   cd touchpad-toggle
```
 
2. Run the installer  

```bash
   ./install.sh
```

**Installer features**

1. Auto-detects installation target `~/.local/bin or ~/bin`.  
2. Checks dependencies and warns about missing audio players.  
3. Copies main script and localization files.  
4. Updates your shell profile if the target isn't in $PATH.  
5. Offers GNOME Shell extension installation interactively.  
   If you chose not to install the extension initially, you can run `./install.sh` again and accept the prompt to install it.  
Then **log out and log back in** for the extension to load.  

### Manual installation

**1. Make script executable**  
     `chmod +x touchpad-toggle`
 
**2. Copy script and localization files to target directory**  
     `cp touchpad-toggle* ~/.local/bin/`
 
**3. Assign keyboard shortcut**  
     `touchpad-toggle --assign`

### Post-Installation

**1. Audio Feedback**  

   The script and GNOME extension automatically detect sound files using a priority hierarchy:  

   1. `~/.local/share/sounds/stereo/` — User-specific override  
   2. Distribution themes (`linuxmint`, `elementary`, `oxygen`, `zorin`, `ubuntu`, `opensuse`)  
   3. `/usr/share/sounds/freedesktop/stereo/` — Universal fallback  

   No configuration required. Replace files in your local directory to customize.  

**2. Custom Sound Files**  

  To use custom sound files, place them here:  

```bash
   mkdir -p ~/.local/share/sounds/stereo/
   cp /path/to/custom-added.oga ~/.local/share/sounds/stereo/device-added.oga
   cp /path/to/custom-removed.oga ~/.local/share/sounds/stereo/device-removed.oga
```
Both the script and extension will automatically detect and prioritize these.  

Supported formats: `.oga`, `.ogg`, `.wav` (depending on audio player).  

## Usage

### Command Line Interface (CLI)

The script is designed to run autonomously. Manual invocation provides status readouts and management options.  

**Command** `./touchpad-toggle [OPTION]`

#### Options

* Invalid or no option  
  Displays the current status of the touchpad, mouse mode, if a mouse (USB/Bluetooth) is detected, and checks if the keyboard shortcut is assigned.  

* `./touchpad-toggle --assign`  
  Assigns a permanent keyboard shortcut (Default: `<Super>q`).  

* `./touchpad-toggle --help`  
  Opens the manual page.  
  
* `./touchpad-toggle --mouse-mode`  
  Toggles the mouse mode.

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

#### Example Workflow

1. **Install shortcut**  
   Invoke `./touchpad-toggle --assign` to assign the keyboard shortcut.  

2. **Toggle with keyboard**  
   Press `SuperKey+Q` (`WindowsKey+Q` or `MetaKey+Q`) to toggle the touchpad on/off.  

3. **Check touchpad status anytime**  

```bash
   touchpad-toggle
```

### GNOME Shell Extension
Touchpad Toggle includes an optional GNOME Shell extension providing a persistent visual indicator in the top bar.

#### Features

* **Left-click**  
  Delegates to script → toggles touchpad with audible feedback.  

* **Right-click**  
  Cycles to/from conditional "disabled-on-external-mouse" mode.  

* **Icon States**  
  * Red touchpad icon: touchpad disabled;  
  * Blue touchpad icon: touchpad enabled;  
  * Blue mouse icon: mouse mode active; touchpad disabled while external device (USB/Bluetooth) detected;  
  * Teal mouse icon: mouse mode stand-by; touchpad enabled while external device not detected.  
  
* **Auto-update**  
  Reflects touchpad state changes made externally (keyboard shortcut, system settings, TUI).  

#### Extension Removal
Via GNOME Extension Manager:  
1. Open "Extensions" application.  
2. Find "Touchpad Toggle".  
3. Toggle off and click "Uninstall" (or remove manually from `~/.local/share/gnome-shell/extensions/`).  

## Troubleshooting  

### Common Errors  

#### Required system component is not installed
The script checks for `gsettings`, `realpath`, and an audio player (optional). Install the missing package shown in the error message.  
Alternatively, change the value of the variable `AUDIO_PLAYER="/usr/bin/paplay"` to the audio player already installed on your system.  

#### Audio does not play
Check the `AUDIO_PLAYER` variable path and ensure the sound files in the specified directories actually exist.  

#### Shortcut doesn't work
Invoke `./touchpad-toggle --assign` again. If it says "Assigned," check if another application is overriding `<Super>q`.  
Alternatively, change the value of the variable `KEY_BINDING="<Super>q"` to the vacant keyboard shortcut of your liking – after making sure, that another application is not overriding it as well.  

#### Touchpad does no longer respond to toggle command
Invoking `./touchpad-toggle --reset` provides a critical fallback layer. While the standard toggle handles software states (GNOME settings), the reset option handles the kernel-level driver state, ensuring the user isn't stuck if the hardware layer freezes.  
To reset the input sub-system hard reset, elevated privileges are required.  

*A Quick Technical Note*  
Executing `udevadm trigger -s` essentially forces the kernel to "replay" the device addition events for all input devices. This causes the Wayland display server to re-initialize the touchpad driver stack without requiring a full system reboot – a much more efficient way to handle hardware hiccups.  

### Debugging  

If the script fails to execute or notifications do not appear, utilize these debugging techniques:  

#### Execution Tracing (`set -x`)
Insert `set -x` at the top of the bash script (below the shebang) or invoke it via bash with the `-x` flag:  

```bash
   bash -x ./touchpad-toggle --toggle
```

This forces the shell to print every command and its expanded arguments to standard output before execution, allowing you to trace exactly where a logic gate fails.  

#### Error Handling Modes (`set -euo pipefail`)

* **Graceful Handling (Default)**  
    The script currently allows non-zero exit codes (like a failed `cat` command if a sysfs node is temporarily busy) to pass quietly without terminating the script.  

* **Strict Handling**  
    Uncommenting `set -euo pipefail` forces the script to abort immediately if any command fails (`-e`), if an undefined variable is referenced (`-u`), or if a command within a pipeline fails (`-o pipefail`). Use this strictly for debugging syntax or pathing errors.  

    *Note*  
    Enabling this is useful for development but may cause the script to crash if an audio file is missing or a `gsettings` key is temporarily unavailable.  
    
### Logging

Following XDG Base Directory Specification, relevant script actions are logged to `~/.local/state/touchpad-toggle.log`. This includes:  

* Touchpad toggle events (enable/disable)  
* Mouse mode toggle events (enable/disable)  
* Keyboard shortcut assignments and removals  
* Input subsystem resets  
* Audio player detection failures  
* Dependency check failures  

#### Log Entry Format

Touchpad-Toggle events are logged in this format:  

```bash
   [YYYY-MM-DD HH:MM:SS] [touchpad-toggle, vX.Y.Z] Message
```

**Example**

```bash
   [2026-08-22 23:02:09] [touchpad-toggle, v1.2.0] ● Keyboard shortcut assigned.
   [2026-08-22 23:13:53] [touchpad-toggle, v1.2.0] ● Touchpad enabled.
   [2026-08-22 23:24:04] [touchpad-toggle, v1.2.0] ● Mouse mode toggle requested. Current state: 'disabled-on-external-mouse'
```

#### Useful Commands

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
   ~/.local/state/touchpad-toggle.log
```

#### Privacy Note

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
This script is provided “as is”; there is NO WARRANTY at all. This is free software: you are free to modify it to your needs and redistribute it under the MIT License.  
  
### Author  

Copyright (c) 2026 RML Tec Dev  
Contributions and feedback are welcome via [rmltecdev@pm.me](mailto:rmltecdev@pm.me?subject=Touchpad-Toggle)  

### License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.  

### Version

Version: 1.2.0  
Build Date: 2026-08-22  
