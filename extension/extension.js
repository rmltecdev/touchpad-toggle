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

const TOUCHPAD_SCHEMA = 'org.gnome.desktop.peripherals.touchpad';
const TOUCHPAD_KEY    = 'send-events';
const EXTENSION_SCHEMA = 'org.gnome.shell.extensions.touchpad-toggle';

const SCRIPT_PATH = '__SCRIPT_PATH__';

// ─── Icons ───────────────────────────────────────────────────────

const ICON_ENABLED        = 'input-touchpad-symbolic';
const ICON_DISABLED       = 'touchpad-disabled-symbolic';
const ICON_EXTERNAL_MOUSE = 'input-mouse-symbolic';

// ─── Colors ───────────────────────────────────────────────────────

const COLORS = {
    enabled:         '#009900',  // green
    disabled:        '#FF3A3F',  // red
    external_mouse:  '#FBB716',  // yellow
};

// ─── Panel Button ────────────────────────────────────────────────

const TouchpadIndicator = GObject.registerClass(
class TouchpadIndicator extends PanelMenu.Button {

    _init(extSettings) {
        super._init(0.0, 'Touchpad Toggle', true);

        this._settings = new Gio.Settings({
            schema_id: TOUCHPAD_SCHEMA,
        });

        // Extension preferences — passed from Extension class
        this._ext_settings = extSettings;

        this._icon = new St.Icon({
            icon_name:    ICON_ENABLED,
            style_class:  'system-status-icon',
        });
        this.add_child(this._icon);

        this._settingsId = this._settings.connect(
            `changed::${TOUCHPAD_KEY}`,
            () => this._updateIcon(),
        );

        this._extSettingsId = this._ext_settings.connect(
            'changed::colored-icons',
            () => this._updateIcon(),
        );

        this._clickId = this.connect(
            'button-press-event',
            this._onButtonPress.bind(this),
        );

        this._updateIcon();
    }

    // ── State helpers ───────────────────────────────────────────

    _getState() {
        return this._settings.get_string(TOUCHPAD_KEY);
    }

    // ── Icon update ──────────────────────────────────────────────

    _updateIcon() {
        const state = this._getState();
        const useColors = this._ext_settings.get_boolean('colored-icons');

        let iconName;
        let color   = null;

        switch (state) {

            case 'enabled':
                iconName = ICON_ENABLED;
                color    = COLORS.enabled;
                break;

            case 'disabled-on-external-mouse':
                iconName = ICON_EXTERNAL_MOUSE;
                color    = COLORS.external_mouse;
                break;

            default:  // 'disabled'
                iconName = ICON_DISABLED;
                color    = COLORS.disabled;
                break;
        }

        this._icon.icon_name = iconName;
        this._icon.set_style(useColors && color ? `color: ${color} !important;` : '');
    }

    // ── Click handler ──────────────────────────────────────────

    _onButtonPress(_actor, event) {
        const button = event.get_button();

        if (button === Clutter.BUTTON_PRIMARY) {

            // Left-click → delegate to the bash script.
            // This preserves the full feedback loop: audio cue + notification.
            //
            // The script toggles enabled ↔ disabled only (not the external-mouse
            // state), which is the expected behaviour for a quick toggle.
            try {
                GLib.spawn_command_line_async(`'${SCRIPT_PATH}' --toggle`);
            } catch (e) {
                log(`Touchpad Toggle: failed to launch script: ${e}`);
            }

        } else if (button === Clutter.BUTTON_SECONDARY) {

            // Right-click → cycle to/from 'disabled-on-external-mouse'.
            // Managed directly via GSettings (the script does not handle
            // this third state).  The icon change is the visual feedback.
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
        if (this._clickId) {
            this.disconnect(this._clickId);
            this._clickId = null;
        }
        this._settings = null;
        this._ext_settings = null;
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
