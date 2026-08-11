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

const SCRIPT_PATH = '__SCRIPT_PATH__';

// ─── Icons ───────────────────────────────────────────────────────

const ICON_ENABLED        = 'input-touchpad-symbolic';
const ICON_DISABLED       = 'touchpad-disabled-symbolic';
const ICON_EXTERNAL_MOUSE = 'input-mouse-symbolic';

// ─── Colors ───────────────────────────────────────────────────────

const COLORS = {
    disabled:           '#FF3A3F',  // red  — touchpad deliberately disabled
    enabled:            '#0780DA',  // blue — touchpad enabled
    external_active:    '#0780DA',  // blue — mouse detected, touchpad disabled
    external_standby:   '#0CA5A5',  // teal — mouse mode standby, no mouse detected
};

// ─── Panel Button ────────────────────────────────────────────────

const TouchpadIndicator = GObject.registerClass(
class TouchpadIndicator extends PanelMenu.Button {

    _init(extSettings) {
        super._init(0.0, 'Touchpad Toggle', true);

        this._settings = new Gio.Settings({
            schema_id: TOUCHPAD_SCHEMA,
        });

        this._ext_settings = extSettings;

        this._icon = new St.Icon({
            icon_name:   ICON_ENABLED,
            style_class: 'system-status-icon',
        });
        this.add_child(this._icon);

        this._externalMousePresent = false;

        this._settingsId = this._settings.connect(
            `changed::${TOUCHPAD_KEY}`,
            () => this._updateIcon(),
        );

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

        this._clickId = this.connect(
            'button-press-event',
            this._onButtonPress.bind(this),
        );

        this._refreshExternalMouse();
        this._updateIcon();
    }

    // ── State helpers ───────────────────────────────────────────

    _getState() {
        if (!this._settings) return 'disabled';
        return this._settings.get_string(TOUCHPAD_KEY);
    }

    // ── External mouse detection ─────────────────────────────────

    _detectExternalMouse() {
        if (!this._seat) return false;

        let externalVendors = new Set();

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

                        if ((bus === '0003' || bus === '0005') && handlers.includes('mouse')) {
                            externalVendors.add(vendor);
                        }
                    }
                }
            }
        } catch (e) {
            return false;
        }

        try {
            const devices = this._seat.list_devices();
            if (!devices || devices.length === 0) return false;

            for (let i = 0; i < devices.length; i++) {
                if (devices[i].get_device_type() === Clutter.InputDeviceType.POINTER_DEVICE) {
                    const vendor = (devices[i].get_vendor_id?.() ?? '').toLowerCase();
                    if (vendor && vendor !== '0' && vendor !== '' && externalVendors.has(vendor)) {
                        return true;
                    }
                }
            }
        } catch (e) {
            return false;
        }

        return false;
    }

    _refreshExternalMouse() {
        const wasPresent = this._externalMousePresent;
        this._externalMousePresent = this._detectExternalMouse();

        if (wasPresent !== this._externalMousePresent &&
            this._getState() === 'disabled-on-external-mouse') {
            this._updateIcon();
        }
    }

    _onDeviceChanged() {
        this._refreshExternalMouse();
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

    // ── Click handler ──────────────────────────────────────────

    _onButtonPress(_actor, event) {
        const button = event.get_button();

        if (button === Clutter.BUTTON_PRIMARY) {
            try {
                GLib.spawn_command_line_async(`'${SCRIPT_PATH}' --toggle`);
            } catch (e) {
                log(`Touchpad Toggle: failed to launch script: ${e}`);
            }
        } else if (button === Clutter.BUTTON_SECONDARY) {
            const current = this._getState();

            if (current === 'disabled-on-external-mouse') {
                this._settings.set_string(TOUCHPAD_KEY, 'disabled');
            } else {
                this._settings.set_string(TOUCHPAD_KEY, 'disabled-on-external-mouse');
            }
        }

        return Clutter.EVENT_STOP;
    }

    // ── Cleanup ─────────────────────────────────────────────────

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
