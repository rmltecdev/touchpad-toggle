# Frequently Asked Questions (FAQ) — Touchpad Toggle

This document addresses friction points, technical boundaries, and known failure modes of the *Touchpad Toggle* utility. It is not a marketing brochure; it is a defensive guide designed to prevent user frustration by setting clear expectations upfront.  
Read it carefully before reporting problems or modifying the script.
If your workflow deviates from the strict requirements listed below, this script is likely not suitable for your system.  

## Table of Contents
[General & Philosophy](#general--philosophy)  
[Hard Requirements & Compatibility](#requirements--compatibility)  
[External Mouse Detection & Bluetooth Latency](#mouse--bluetooth)  
[Hibernation, Sleep, and System Freeze](#hibernation--freezw)  
[Keyboard Shortcuts & Conflicts](#keyboard)  
[Audio Feedback & Localization](#audio--localization)  
[Security & Privacy](security--privacy)  
[Troubleshooting](troubleshooting)  

## General & Philosophy

### Why does this script exist?

**Because the built-in solutions are insufficient.**

Every major Desktop Environment offers a touchpad toggle somewhere in its settings hierarchy. The problem is not the *existence* of the feature — it is the *access* to it. Navigating through `Settings → Mouse & Touchpad → Touchpad` while mid-paragraph is a context-destroying interruption. By the time you've disabled the touchpad via GUI, the damage (displaced cursor, overwritten text, lost selection) is already done.  

*Touchpad Toggle* exists to close that gap: a single keystroke, instant feedback, zero cognitive overhead. No menus, no clicks, no context switching.  

**What this script is *not*:**

- It is **not** a general-purpose input device manager. If you need per-device granularity (e.g., disabling only the touchpad's tap-to-click while keeping scrolling active), use `gnome-tweaks` or `dconf-editor` directly.  
- It is **not** a replacement for palm detection. Kernel-level palm rejection (`libinput`) should be your first line of defense. This script is a *manual override* for when palm detection fails or is insufficient — which it regularly is on thinner laptops with reduced key-travel distance.  
- It is **not** a power-saving tool. Disabling the touchpad does not meaningfully reduce power consumption. The device remains electrically active; only the event stream is severed at the software layer.  

**The underlying assumption:** You are a laptop user who types extensively, values low-latency control over input devices, and prefers keyboard-driven workflows over mouse-driven configuration panels. If that does not describe you, the built-in GNOME settings toggle is perfectly adequate.  

### Does this script support Windows or macOS?

**No, and it never will.**

This is a hard architectural boundary, not a matter of missing features or future roadmap items.

**Why it cannot work:**

* **Windows** manages input devices through a completely different stack (HID class drivers, Device Manager, Registry-based configuration). There is no `gsettings`, no `dconf`, no `org.gnome.desktop.peripherals.touchpad` schema. The script's core mechanism — reading and writing the `send-events` GSettings key — has no equivalent on Windows. Porting would mean rewriting the entire backend, at which point it would be a different project.  

* **macOS** is similarly incompatible. Touchpad state on macOS is managed via `IOKit` and private frameworks (`MultitouchSupport.framework`). Additionally, Apple's Force Touch trackpads operate at a firmware level that does not expose a simple enable/disable toggle comparable to GNOME's `send-events` key.

**Why we don't recommend workarounds:**

Running this script via WSL (Windows Subsystem for Linux) or a Linux VM on Windows/macOS will **not** affect the host system's touchpad. The script operates on the D-Bus/GSettings layer of *its own* operating environment. Changes are confined to the Linux session and cannot propagate to the host's input subsystem.  

**What to use instead:**

* **Windows:** Use `devcon.exe` (from Windows Driver Kit) to disable the HID-compliant touchpad device, or assign a custom shortcut via AutoHotkey that toggles the device state via PowerShell. Third-party tools like TouchpadBlocker also exist.  

* **macOS:** No native toggle exists. Third-party utilities such as [Touchpad Blocker](https://apps.apple.com/us/app/touchpad-blocker) or Karabiner-Elements (for remapping) are the closest equivalents. Alternatively, System Settings → Trackpad → "Ignore trackpad when mouse is present" covers the automatic-switching use case.  

Do not open issues requesting Windows or macOS support. They will be closed as `wontfix`.  

## Hard Requirements & Compatibility

### Why does the script fail or report missing dependencies on my system?

#### The Cause

*Touchpad Toggle* is engineered exclusively for **GNOME** running on **Wayland**. It relies on specific D-Bus interfaces (`gsettings`, `org.gnome.desktop.peripherals.touchpad`) and Wayland seat APIs that do not exist in other environments.  

#### The Reality

* **Desktop Environment**  
  KDE Plasma, XFCE, MATE, Cinnamon, and i3 are **not supported**. The script will not function because the underlying GSettings schemas are absent or named differently.  

* **Display Server**  
  X11 support is **experimental and unofficial**. While the core toggle might work via legacy XInput commands, features like automatic external mouse detection (which relies on `seat` enumeration) will fail silently or behave unpredictably.  

* **Shell**  
  Requires Bash 4.0+ for associative arrays. Older distributions (e.g., Debian 9, Ubuntu 16.04) are incompatible.  

**Solution**  

* Verify your session: Run `echo $XDG_SESSION_TYPE`. It must return `wayland`.  
* Verify your DE: Run `echo $XDG_CURRENT_DESKTOP`. It must contain `GNOME`.  
* If you use X11 or a different DE, fork the code and rewrite the backend logic. We do not provide patches for unsupported environments.  

### Can I use this on a Chromebook or a tablet?

**No.** The script assumes a standard laptop architecture with a discrete touchpad device node. ChromeOS manages input devices via a completely different kernel stack (CrosEC), and tablets often lack the specific `send-events` GSettings key. Attempting to force the script may destabilize the input subsystem.  

## External Mouse Detection & Bluetooth Latency

### Why does the touchpad stay disabled even after I plug in a USB mouse?

#### The Cause

This is a hardware enumeration delay, not a bug in the script.  

**The Technical Detail**

* **USB Devices**  
  Usually detected instantly. If there is a lag, it is often due to the USB power management state (suspend/resume) of the port.  

* **Bluetooth Devices**  
  This is a known limitation. Bluetooth pairing handshakes and HID profile negotiation can take **5–15 seconds**. During this window, the script’s listener loop has not yet received the "device added" event from the kernel.  

**The Risk**  
  Users expecting instant switching upon plugging in a Bluetooth mouse will perceive the tool as broken.  

**Mitigation**  

* Wait at least 10 seconds after connecting a Bluetooth mouse before assuming the script failed.  

* If the issue persists beyond 15 seconds, check your system logs (`journalctl -f`) for Bluetooth HID errors. The script cannot compensate for a broken Bluetooth stack.  

### Why does the touchpad re-enable automatically when I disconnect my mouse?

#### By Design

The script implements a "Mouse Mode" logic:  

1. External mouse connected → Touchpad disabled (to prevent palm strikes).  

2. External mouse disconnected → Touchpad enabled (to restore control).  

#### The Friction Point

Some users find this behavior annoying if they frequently switch between mouse and touchpad manually.  

#### Workaround

* Use the GNOME Shell extension (if installed) to manually toggle "Mouse Mode" off.  

* Alternatively, disable the automatic detection logic in the source code by commenting out the `/proc/bus/input/devices` polling section.  

## Hibernation, Sleep, and System Freeze

### My touchpad stopped working after waking from sleep/hibernate. What happened?

#### The Cause

This is a kernel-level driver state mismatch, not a script failure.  

#### The Technical Detail

When a system suspends, the kernel driver for the touchpad is unloaded or put into a low-power state. Upon resume, the driver sometimes fails to re-initialize correctly, leaving the device node in a "zombie" state. The script’s standard `gsettings` toggle only changes the *software* preference, not the *hardware* driver state.  

#### The Solution

Execute the hard reset command: `sudo touchpad-toggle --reset`.  

**Warning:** This triggers `udevadm trigger -s`, which forces the kernel to replay device events. This may cause a brief flicker of all input devices (mouse, keyboard) but is necessary to recover from a frozen driver state.  

**Is it safe to run `--reset`?**  

**Generally, yes.** It does not wipe data or modify firmware. However, it forcibly re-enumerates all input devices. If you are in the middle of a critical task (e.g., a long text selection), your cursor may jump or inputs may be momentarily lost.  
**Use only when the touchpad is unresponsive.**  

## Keyboard Shortcuts & Conflicts

### I assigned `<Super>q`, but nothing happens when I press it.

#### The Cause

Global shortcut conflicts are the most common point of failure.  

#### The Analysis

GNOME allows only one action per keybinding. If another application (e.g., a screenshot tool, a terminal launcher, or a system utility) has already claimed `<Super>q`, your assignment is silently ignored or overridden.  

#### How to Diagnose

1. Open **Settings → Keyboard → View and Customize Shortcuts**.  
2. Search for `q` or `super`.  
3. Check if any other entry uses `<Super>q`.  

#### Solution

* Reassign the shortcut to a less common combination (e.g., `<Super><Shift>q` or `<Ctrl><Alt>t`).  
* Update the `KEY_BINDING` variable in the script source and re-run `--assign`.  

### Why did the script say "Shortcut assigned" but it still doesn't work?

#### The Cause

The script successfully wrote to `gsettings`, but the GNOME Shell process has not reloaded the configuration cache.  

#### Fix: Restart GNOME Shell
* On Wayland, a full logout is required to restart GNOME Shell.
* On X11, press `Alt+F2`, type `r`, hit Enter. 

## Audio Feedback & Localization

### No sound plays when I toggle the touchpad. Is the script broken?

#### Not necessarily

The script auto-detects audio players (`pipewire`, `pulseaudio`, `alsa`) but does not guarantee sound file availability.  

#### Common Pitfalls

* Your distribution removed the standard freedesktop sound theme (`freedesktop-sound-theme`).  
* The sound files (`.oga`, `.wav`) were deleted during a system cleanup.  

#### Verification

* Check the script’s internal variables `TOUCHPAD_ENABLED` and `TOUCHPAD_DISABLED`.  
* Manually test playback: `pw-play /usr/share/sounds/freedesktop/stereo/service-login.oga` (or equivalent path).  

#### Action

* If the system sounds are missing, you must either install the `sound-theme-freedesktop` package or point the script to custom sound files by editing the script header.  

### Localization error

The script cannot find a language file.  

* **Requirement**  
  The files `<scriptname>.en`, `<scriptname>.de`, or `<scriptname>.th` must reside in the **same directory** as the main script.  

* **Failure mode**  
  If no file is found, the script aborts with exit code 1. It does not start with empty messages.

#### Does the script support languages other than English, German, and Thai?

**Out of the box, no.** The current distribution includes only English (generic), German (generic), and Thai. The localization architecture loads language files based on `$LANG`. If your system language is French (`fr_FR.UTF-8`) and no `touchpad-toggle.fr` file exists, the script falls back to English *only if* the fallback file is present in the same directory.  

**However, additional localizations can be added with minimal effort.**  
The architecture is designed for extensibility:  

1. **Create a locale file**  
   Copy `touchpad-toggle.en` to `touchpad-toggle.[lang]` (e.g., `touchpad-toggle.fr` for French).  

2. **Translate the MSG array**  
   Replace all English string values in the associative array while preserving the exact key names.  

3. **Place alongside the script**  
   Ensure the new file resides in the same directory as the main script.

The script automatically detects the system language and loads the corresponding file if available. No code modifications or recompilation are required.  

**Friction points**  

* Key names in the `MSG` array must match exactly — typos will cause silent failures.  
* Special characters must be properly UTF-8 encoded.  
* The fallback file (`touchpad-toggle.en`) must remain intact for graceful degradation.  

If you contribute a new translation, please submit it via the issue tracker or email so it can be included in future releases.  

**Warning:** If the fallback file is missing or corrupted, the script may abort with a cryptic error.  

## Security & Privacy

### Does this script send data to the internet?

**No.** The script operates entirely locally. It reads/writes to `gsettings`, `/proc/bus/input/devices`, and local log files (`~/.local/state/touchpad-toggle.log`). No network connections are initiated.  

### Does this script log my keystrokes?

**No.** The log file records *state changes* (e.g., "Touchpad disabled at 14:02"), not the content of your typing or the keys you pressed.  

### Why does `--reset` require `sudo`?

**Kernel Access.** Resetting the input subsystem involves triggering `udevadm`, which modifies kernel device state. This is a privileged operation. The script does not escalate privileges for any other function (toggling, assigning shortcuts). If you refuse to grant `sudo`, you cannot use the hard-reset recovery feature.  

## Troubleshooting

### The script crashes or exits silently. How do I debug?
**Do not guess.** Use the built-in tracing.  

**1. Enable Verbose Mode**  

```bash
   bash -x ./touchpad-toggle --toggle
```
   
This prints every command executed. Look for the first line that returns a non-zero exit code.  

**2. Check Logs**  

```bash
   tail -f ~/.local/state/touchpad-toggle.log
```

Look for "failed" or "error" tags.  

**3. Strict Mode**  

If developing, uncomment set `-euo pipefail` in the script header. This forces the script to abort immediately on any error, making the failure point obvious. Warning: This may break the script in production if a temporary resource (like an audio file) is missing.  

**4. "It worked yesterday, but not today."**  
System Updates. GNOME updates frequently change internal API versions (e.g., GNOME 45 → 46). If you updated your OS recently, the script may need a patch to match the new Clutter or GSettings API. Check the [CHANGELOG.md](CHANGELOG.md) for compatibility notes regarding your current GNOME version.  

### Who is liable for data loss?

**You are.** This script is provided "as is" under the [MIT License](LICENSE) with **no warranty whatsoever**. As a user, you are solely responsible for your own data and, where applicable, for any customer or third-party data stored on the system this script manages.  
If your system handles critical or regulated data, implement your own backup and redundancy strategy. See [LICENSE](LICENSE) and the `DISCLAIMER` section in [README.md](README.md) for the full legal text.  

### Can I modify the script?

Yes, under the terms of the [MIT License](LICENSE). If you do, keep version numbers and build dates consistent across all files (see [README.md](README.md) — Version Metadata) to avoid breaking the test suite (`test.sh`).  

---

*Last updated: 22 August 2026*
*Author: RML Tec Dev*
