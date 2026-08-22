/*
 * Touchpad Toggle — GNOME Shell Extension
 *
 * Non-self-contained panel indicator for the touchpad-toggle bash utility.
 * Reads and writes the same GSettings key as the script, delegates toggle
 * actions to the script to preserve its audio + notification feedback loop.
 *
 * Requires the touchpad-toggle script by rmltecdev to be installed.
 *
 * SPDX-License-Identifier: MIT
 */

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

// ─── Configuration ───────────────────────────────────────────────

const TOUCHPAD_SCHEMA  = 'org.gnome.desktop.peripherals.touchpad';
const TOUCHPAD_KEY     = 'send-events';
const EXTENSION_SCHEMA = 'org.gnome.shell.extensions.touchpad-toggle';

// Placeholder — replaced by installer with actual script path
const SCRIPT_PATH = '__SCRIPT_PATH__';

// ─── Icons ───────────────────────────────────────────────────────

const ICON_ENABLED        = 'input-touchpad-symbolic';
const ICON_DISABLED       = 'touchpad-disabled-symbolic';
const ICON_EXTERNAL_MOUSE = 'input-mouse-symbolic';

// ─── Colors ───────────────────────────────────────────────────────

const COLORS = {
    enabled:         '#0780DA',  // blue   — touchpad active
    disabled:        '#FF3A3F',  // red    — deliberately disabled
    external_standby:'#0CA5A5',  // teal   — mouse mode standby, no mouse detected
    external_active: '#0780DA',  // blue   — mouse detected, auto-managed
};

// ─── Panel Button ────────────────────────────────────────────────

const TouchpadIndicator = GObject.registerClass(
class TouchpadIndicator extends PanelMenu.Button {

    _init(extSettings) {
        super._init(0.0, 'Touchpad Toggle', true);

        // 1. GSettings initialisieren
        this._settings = new Gio.Settings({
            schema_id: TOUCHPAD_SCHEMA,
        });

        // Extension preferences — passed from Extension class
        this._ext_settings = extSettings;

        this._icon = new St.Icon({
            icon_name:   ICON_ENABLED,
            style_class: 'system-status-icon',
        });
        this.add_child(this._icon);

        this._externalMousePresent = false;

        // React to touchpad state changes (keyboard shortcut, settings, …)
        this._settingsId = this._settings.connect(
            `changed::${TOUCHPAD_KEY}`,
            () => this._updateIcon(),
        );

        // React to color preference changes
        this._extSettingsId = this._ext_settings.connect(
            'changed::colored-icons',
            () => this._updateIcon(),
        );

        // ── External mouse detection via Clutter Seat ──
        try {
            this._seat = Clutter.get_default_backend().get_default_seat();

            this._deviceAddedId = this._seat.connect(
                'device-added',
                (_seat, _device) => this._onDeviceChanged(),
            );
            this._deviceRemovedId = this._seat.connect(
                'device-removed',
                (_seat, _device) => this._onDeviceChanged(),
            );

            log('Touchpad Toggle: Extension loaded.');
        } catch (e) {
            log(`Touchpad Toggle: seat unavailable, mouse detection disabled: ${e}`);
            this._seat = null;
        }

        // Handle clicks
        this._clickId = this.connect(
            'button-press-event',
            this._onButtonPress.bind(this),
        );

        // ── Audio & Sound Initialization ──────────────────────────
        this._detectAudioPlayer();
        this._detectSoundFiles();

        // Initial state
        this._refreshExternalMouse();
        this._updateIcon();
    }

    // ── State helpers ───────────────────────────────────────────

    _getState() {
        if (!this._settings) return 'disabled';
        return this._settings.get_string(TOUCHPAD_KEY);
    }

    // ── Sound Discovery (mirrors bash detect_audio_system) ────────

    _detectSoundFiles() {
        const homeDir = GLib.get_home_dir();

        const soundDirs = [
            `${homeDir}/.local/share/sounds`,
            '/usr/share/sounds/linuxmint/stereo',
            '/usr/share/sounds/elementary/stereo',
            '/usr/share/sounds/oxygen/stereo',
            '/usr/share/sounds/zorin/stereo',
            '/usr/share/sounds/ubuntu/stereo',
            '/usr/share/sounds/opensuse/stereo', 
            '/usr/share/sounds/freedesktop/stereo',            
        ];

        for (const dir of soundDirs) {
            const disabledPath = GLib.build_filenamev([dir, 'device-removed.oga']);
            const enabledPath  = GLib.build_filenamev([dir, 'device-added.oga']);

            if (GLib.file_test(disabledPath, GLib.FileTest.EXISTS) &&
                GLib.file_test(enabledPath, GLib.FileTest.EXISTS)) {
                this._soundDisabled = disabledPath;
                this._soundEnabled   = enabledPath;
                log(`Touchpad Toggle: sounds found in ${dir}`);
                return true;
            }

            // Fallback: single "complete" sound
            const completePath = GLib.build_filenamev([dir, 'complete.oga']);
            if (GLib.file_test(completePath, GLib.FileTest.EXISTS)) {
                this._soundDisabled = completePath;
                this._soundEnabled   = completePath;
                log(`Touchpad Toggle: single sound file found: ${completePath}`);
                return true;
            }
        }

        log('Touchpad Toggle: no sound files found, audio feedback disabled');
        this._soundDisabled = null;
        this._soundEnabled   = null;
        return false;
    }

    // ── Audio Player Detection ────────────────────────────────────
    // FIX: Uint8Array → String Dekodierung hinzugefügt

    _detectAudioPlayer() {
        const players = ['pw-play', 'paplay', 'aplay'];
        const decoder = new TextDecoder();

        for (const player of players) {
            try {
                const [ok, stdout, _stderr, exitCode] = GLib.spawn_command_line_sync(
                    `which ${player}`
                );
                if (ok && exitCode === 0) {
                    // CRITICAL FIX: Uint8Array to String
                    const path = decoder.decode(stdout).trim();
                    if (path.length > 0) {
                        this._audioPlayer = path;
                        log(`Touchpad Toggle: audio player detected: ${path}`);
                        return true;
                    }
                }
            } catch (e) {
                // player not available, try next
            }
        }

        log('Touchpad Toggle: no audio player detected');
        this._audioPlayer = null;
        return false;
    }

    // ── Play Sound Helper ─────────────────────────────────────────

    _playSound(soundFile) {
        if (!this._audioPlayer || !soundFile) {
            log(`Touchpad Toggle DEBUG: _playSound() ABORTED — audioPlayer=${!!this._audioPlayer}, soundFile=${!!soundFile}`);
            return;
        }

        const cmd = `${this._audioPlayer} "${soundFile}"`;
        log(`Touchpad Toggle DEBUG: executing sound command: ${cmd}`);

        try {
            GLib.spawn_command_line_async(cmd);
            log(`Touchpad Toggle DEBUG: sound spawn successful`);
        } catch (e) {
            log(`Touchpad Toggle: sound playback failed: ${e}`);
        }
    }

    // ── External Mouse Detection ──────────────────────────────────

    _detectExternalMouse() {
        if (!this._seat) return false;

        let externalVendors = new Set();

        // 1. Parse /proc/bus/input/devices to identify external bus types
        try {
            const [ok, contents] = GLib.file_get_contents('/proc/bus/input/devices');
            if (ok) {
                const text = new TextDecoder().decode(contents);
                const blocks = text.split('\n\n');

                for (const block of blocks) {
                    const busMatch = block.match(/Bus=(\w+)/);
                    const vendorMatch = block.match(/Vendor=(\w+)/);
                    const handlersMatch = block.match(/Handlers=(.+)/);

                    if (busMatch && vendorMatch && handlersMatch) {
                        const bus = busMatch[1];
                        const vendor = vendorMatch[1].toLowerCase();
                        const handlers = handlersMatch[1];

                        // USB (0003) or Bluetooth (0005) with mouse handler
                        if ((bus === '0003' || bus === '0005') && handlers.includes('mouse')) {
                            externalVendors.add(vendor);
                        }
                    }
                }
            }
        } catch (e) {
            log(`Touchpad Toggle: /proc/bus/input/devices read failed: ${e}`);
        }

        // 2. Enumerate devices via Seat API and cross-reference vendors
        try {
            const devices = this._seat.list_devices();
            if (!devices || devices.length === 0) return false;

            for (let i = 0; i < devices.length; i++) {
                if (devices[i].get_device_type() === Clutter.InputDeviceType.POINTER_DEVICE) {
                    const vendor = (devices[i].get_vendor_id?.() ?? '').toLowerCase();
                    // Vendor '0' or empty means internal (touchpad companion pointer)
                    if (vendor && vendor !== '0' && vendor !== '' && externalVendors.has(vendor)) {
                        return true;
                    }
                }
            }
        } catch (e) {
            log(`Touchpad Toggle: device enumeration failed: ${e}`);
        }

        return false;
    }

    _refreshExternalMouse() {
        const wasPresent = this._externalMousePresent;
        this._externalMousePresent = this._detectExternalMouse();

        // Nur Icon aktualisieren, wenn sich der Zustand geändert hat
        // UND wir im "external-mouse"-Modus sind.
        if (wasPresent !== this._externalMousePresent &&
            this._getState() === 'disabled-on-external-mouse') {
            this._updateIcon();
        }
    }

    // ── Device Change Handler ─────────────────────────────────────
    // FIXED: Sound nur bei tatsächlicher Statusänderung

    _onDeviceChanged() {
        const wasPresent = this._externalMousePresent;
        this._refreshExternalMouse();

        // Only play sound when state ACTUALLY changed
        if (wasPresent !== this._externalMousePresent) {
            log(`Touchpad Toggle DEBUG: _onDeviceChanged() — mouse state changed: ${wasPresent} → ${this._externalMousePresent}`);
            
            if (this._externalMousePresent) {
                log(`Touchpad Toggle DEBUG: playing device-added sound`);
                this._playSound(this._soundEnabled);
            } else {
                log(`Touchpad Toggle DEBUG: playing device-removed sound`);
                this._playSound(this._soundDisabled);
            }
        } else {
            log(`Touchpad Toggle DEBUG: _onDeviceChanged() — no state change, ignoring`);
        }
    }

    // ── Icon update ──────────────────────────────────────────────

    _updateIcon() {
        const state = this._getState();
        const useColors = this._ext_settings.get_boolean('colored-icons');

        let iconName;
        let color = null;

        switch (state) {
            case 'enabled':
                iconName = ICON_ENABLED;
                color = COLORS.enabled;
                break;

            case 'disabled-on-external-mouse':
                iconName = ICON_EXTERNAL_MOUSE;
                color = this._externalMousePresent
                    ? COLORS.external_active
                    : COLORS.external_standby;
                break;

            default:
                iconName = ICON_DISABLED;
                color = COLORS.disabled;
                break;
        }

        this._icon.icon_name = iconName;
        this._icon.set_style(useColors && color ? `color: ${color} !important;` : '');
    }

    // ── Click handler ────────────────────────────────────────────

    _onButtonPress(_actor, event) {
        const button = event.get_button();

        if (button === Clutter.BUTTON_PRIMARY) {
            // Left-click → toggle touchpad
            try {
                GLib.spawn_command_line_async(`'${SCRIPT_PATH}' --toggle`);
            } catch (e) {
                log(`Touchpad Toggle: failed to launch script: ${e}`);
            }
        } else if (button === Clutter.BUTTON_SECONDARY) {
            // Right-click → delegate to script --mouse-mode
            try {
                GLib.spawn_command_line_async(`'${SCRIPT_PATH}' --mouse-mode`);
            } catch (e) {
                log(`Touchpad Toggle: failed to launch script: ${e}`);
            }
        }

        return Clutter.EVENT_STOP;
    }

    // ── Cleanup ──────────────────────────────────────────────────

    destroy() {
        if (this._settingsId) {
            this._settings.disconnect(this._settingsId);
            this._settingsId = null;
        }
        if (this._extSettingsId) {
            this._ext_settings.disconnect(this._extSettingsId);
            this._extSettingsId = null;
        }
        if (this._seat && this._deviceAddedId) {
            this._seat.disconnect(this._deviceAddedId);
            this._deviceAddedId = null;
        }
        if (this._seat && this._deviceRemovedId) {
            this._seat.disconnect(this._deviceRemovedId);
            this._deviceRemovedId = null;
        }
        if (this._clickId) {
            this.disconnect(this._clickId);
            this._clickId = null;
        }

        this._settings = null;
        this._ext_settings = null;
        this._seat = null;
        this._audioPlayer = null;
        this._soundDisabled = null;
        this._soundEnabled = null;

        super.destroy();
    }
});

// ─── Extension Entry Point ───────────────────────────────────────

export default class TouchpadToggleExtension extends Extension {

    enable() {
        this._indicator = new TouchpadIndicator(this.getSettings());
        Main.panel.addToStatusArea('touchpad-toggle', this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}
