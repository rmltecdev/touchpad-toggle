# Touchpad Toggle Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |
| 1.1.x   | ✅        |

## Reporting a Vulnerability

If you discover a security vulnerability in Touchpad Toggle, please report it responsibly:

1. Email: rmltecdev@pm.me
2. Subject: `[SECURITY] Touchpad Toggle — <brief description>`
3. Include:
   - Affected version (`./touchpad-toggle --version`)
   - Steps to reproduce
   - Potential impact

Please **do not** open a public GitHub issue for security vulnerabilities.

## Response Time

* Acknowledgement: within 72 hours
* Assessment: within 7 days
* Fix or mitigation: depends on severity

## Scope

Touchpad Toggle runs with user-level privileges for most operations.
The `--reset` option requires `sudo` and executes `udevadm trigger -s input`,
which affects all input devices on the system.
