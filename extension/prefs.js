/*
 * Touchpad Toggle — Extension Preferences
 * SPDX-License-Identifier: MIT
 */

import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class TouchpadTogglePreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const page = new Adw.PreferencesPage({
            title: 'Touchpad Toggle',
            icon_name: 'input-touchpad-symbolic',
        });

        const group = new Adw.PreferencesGroup({
            title: 'Appearance',
        });

        // Colored Icons Toggle
        const coloredIconsRow = new Adw.SwitchRow({
            title: 'Colored Icons',
            subtitle: 'Show colored status icons (disable for monochrome)',
        });

        const settings = this.getSettings();
        coloredIconsRow.set_active(settings.get_boolean('colored-icons'));

        coloredIconsRow.connect('notify::active', (row) => {
            settings.set_boolean('colored-icons', row.get_active());
        });

        group.add(coloredIconsRow);
        page.add(group);
        window.add(page);
    }
}
