# macOS Security Baseline — JAMF Configuration Profile Mapping
**Target fleet:** Design team — 25 macOS devices  
**Date:** 2026-08-13  
**Compliance framework:** Internal DWP security baseline  
**Baseline version:** 1.0  

---

## Overview

This document maps 6 macOS security requirements to JAMF configuration profile payloads. Each row specifies the exact setting, expected value, operational effect, and common false-positive causes.

> **⚠️ CRITICAL NOTICE:**  
> JAMF payload names, UI labels, and options have changed between macOS versions (Monterey → Ventura → Sonoma → Sequoia) and JAMF server versions. **Do not copy the exact "Payload type" or "Value" labels from this document without first verifying them against your own JAMF instance.** JAMF UI strings are subject to change without notice. The **effect** and **false-positive risk** sections describe the *goal* and should be stable; the *path* to that goal may differ in your version.

---

## Requirement 1 — FileVault disk encryption must be enabled

| Field | Value |
|---|---|
| **Payload type** | `Security & Privacy` → `Encryption` (or `Full Disk Encryption` on newer JAMF versions) |
| **JAMF UI label to verify** | Look for "Enable FileVault" or "FileVault 2 Encryption" toggle |
| **Setting value** | **Enabled** (or `true` in XML/CLI) |
| **Effect** | All data on the device is encrypted at rest. Unauthorised physical access to the drive cannot read user files without the FileVault recovery key. Encryption is transparent to the user. |
| **False-positive risk** | • Pre-encrypted drives (devices provisioned with FileVault already on) may incorrectly report as non-compliant if the profile is set to "Enable" rather than "Enforce"; verify the setting is `Enforce` not just `Check`. • M1/M2/M3 Macs with Secure Enclave storage may show different encryption status; JAMF may report "encrypted via Secure Enclave" vs. "FileVault" as distinct states. • APFS hardware-level encryption (on newer drives) is not the same as FileVault; ensure the profile specifically requires FileVault, not just "encrypted". |

---

## Requirement 2 — Gatekeeper must be enabled (identified developers only)

| Field | Value |
|---|---|
| **Payload type** | `Security & Privacy` → `System Security` (some versions: `Gatekeeper`) |
| **JAMF UI label to verify** | Look for "Allow applications downloaded from:" dropdown or "Gatekeeper" section |
| **Setting value** | **"App Store and identified developers"** (or equivalent). *Do not set to "Anywhere"*; that disables Gatekeeper. |
| **Effect** | Only applications signed by Apple-registered developers or distributed via the Mac App Store can run. Unsigned or revoked-certificate apps are blocked at launch. Users cannot override this without administrator approval (depending on JAMF enforcement level). Protects against malware and sideloaded unsigned binaries. |
| **False-positive risk** | • Legacy in-house applications not signed with an Apple developer certificate will be blocked and flag as non-compliant even if they are trusted. Remediation: sign the app or distribute via MDM app catalog. • Developer certificates that have expired will fail Gatekeeper validation. Monitor certificate expiry. • Notarization (Apple's post-signature malware scan) is now required; apps lacking notarization may be blocked on recent macOS versions (Catalina+). Older Gatekeeper profiles that only check signatures may miss this requirement. • Apps installed before the policy was enforced may have cached approval; reboot may be required to re-evaluate. |

---

## Requirement 3 — Minimum macOS version: current stable minus one point release

| Field | Value |
|---|---|
| **Payload type** | `Restrictions` → `System Updates` (or `Software Update` in newer JAMF versions) |
| **JAMF UI label to verify** | Look for "Minimum OS Version", "Require minimum macOS version", or "OS Version Restriction" |
| **Setting value** | Set to the prior major.minor release. *Example:* If macOS 15 (Sequoia) is current stable, set minimum to **14.7** (latest Sonoma). Adjust as new releases ship. |
| **Effect** | Devices running older OS versions are flagged as non-compliant and denied access to company resources (if enrollment enforcement is active). Encourages timely OS upgrades and ensures device vulnerability patch levels are consistent. |
| **False-positive risk** | • Devices in active OS upgrade cycle (downloading or installing the next version) may temporarily report as running the old version until restart. Grace period recommended (48–72 hours). • Hardware incompatibility: older Macs cannot upgrade to the latest macOS (e.g., 2017 MacBook Air cannot run Sonoma). These devices will be perpetually non-compliant; design an exception process or retirement plan. • Beta/developer builds show version numbers like `15.0 Beta 3`, which may not parse correctly as "newer than" the minimum threshold. Test the exact version string in your JAMF instance. • Time skew on device or JAMF server can cause version-check failures; ensure NTP sync. |

---

## Requirement 4 — Firewall must be enabled

| Field | Value |
|---|---|
| **Payload type** | `Security & Privacy` → `Firewall` (or `System Security` in newer versions) |
| **JAMF UI label to verify** | Look for "Enable firewall", "Firewall Status", or toggle under "Firewall" section |
| **Setting value** | **Enabled** (or `true`). Some profiles offer sub-options: `Enable stealth mode` (block ICMP ping) is optional but recommended. |
| **Effect** | macOS firewall becomes active. Inbound connections are blocked by default unless explicitly allowed. Outbound connections are permitted. Stealth mode (if enabled) prevents the device from responding to network discovery probes, reducing attack surface. |
| **False-positive risk** | • Software that requires listening on a local port without explicit firewall allowlist entry will fail. Examples: development servers (Node.js, Django), network printers needing inbound discovery, VPN clients with incoming connection handlers. Test your fleet's common applications before rolling out. • JAMF configuration does not prevent the *user* from manually disabling the firewall via System Settings (unless additional restrictions are applied). Verify your JAMF version applies restrictions to prevent user override. • Some apps require firewall exemptions that are only granted after first launch/install; devices checked for compliance before first-run may fail. First-run grace period recommended. • Firewall rules persist across reboots; once enabled, reverting requires manual disable or JAMF re-profile push. Test in a pilot group first. |

---

## Requirement 5 — Login password required after sleep or screen saver

| Field | Value |
|---|---|
| **Payload type** | `Login Window` (or `Security & Privacy` → `Session Lock` in newer JAMF versions) |
| **JAMF UI label to verify** | Look for "Require password immediately after sleep/screen saver", "Login required", or "Automatic login" settings |
| **Setting value** | • Disable automatic login (`Automatic login` = `Disabled` or unchecked). • Set screen saver timeout to **5–15 minutes** (e.g., 10 minutes is common). • Set "Require password after" to **Immediately** or a very short delay (**0 seconds** is strictest). Some profiles call this "Ask for password after X seconds of inactivity". |
| **Effect** | If a user walks away from an unlocked Mac, the screen saver activates after the timeout. Reopening or moving the mouse requires the user to re-authenticate with their password. Protects against session hijacking and data theft during unattended moments. |
| **False-positive risk** | • Screen saver timeout is distinct from display sleep timeout; these are controlled by separate OS settings. Misconfiguration: a device may sleep before the screensaver activates, or screensaver may activate but display remains on (if power settings are misaligned). Verify *both* settings are in place. • Some users have accessibility needs (muscle disorders) that require longer timeouts or no screensaver; plan exception process. • Screensaver login requirement can interfere with automation tools or remote desktop clients that expect to resume without re-auth; test with RDP/VNC if your fleet uses these. • Clock skew on device can cause timeout calculations to misfire; ensure NTP is accurate. • Fast-waking displays (M1/M2 Macs) may wake from sleep so quickly the screensaver doesn't activate; layer a display-sleep *and* screensaver requirement. |

---

## Requirement 6 — Automatic security updates enabled

| Field | Value |
|---|---|
| **Payload type** | `Software Update` (or `System Updates` → `Automatic Updates` in newer versions) |
| **JAMF UI label to verify** | Look for "Automatic Security Updates", "Install system software updates", or "Software Update" settings. Ensure you are configuring *security* updates, not *all* updates. |
| **Setting value** | • Set `Automatic macOS security updates` = **Enabled** (or `true`). • Set `Install updates automatically` = **Enabled** (or scope to "Critical Updates" / "Security Updates" only, depending on JAMF version). • Consider: `Restart required` = set to automatic restart timing or off-hours (e.g., 2 AM) to avoid disrupting users. |
| **Effect** | Critical security patches (OS, firmware, bundled apps) are downloaded and installed without user interaction. Devices are not left vulnerable due to patch procrastination. Restarts (if required by the update) can be scheduled during off-hours. |
| **False-positive risk** | • Automatic updates may reboot the device during business hours if the user does not delay/defer the restart. Coordinate with IT policy: set restart timing to after-hours to minimize disruption. • Updates that are incompatible with legacy in-house software may break workflow. Test in a pilot group; maintain a "hold" list if certain updates must be deferred. • Enterprise deployments often require staged rollouts (install on 10% of fleet, wait 1 week, then 50%, then 100%) rather than all devices at once. JAMF staged deployment features should be used; do not use the "automatic update" setting as a substitute for controlled rollout. • Beta versions of macOS may be installed if a device is in a beta seed program; JAMF automatic update setting may not distinguish between stable and beta. Ensure only stable updates are targeted. • Update downloads consume bandwidth; if your site has bandwidth constraints, configure updates to download only on Wi-Fi or during off-hours. • Some updates require user authentication (sign-in with Apple ID for security patches to Apple system components); these will not fully automate even if the setting is enabled. Verify that account delegation is in place. |

---

## JAMF Configuration Profile Assembly Checklist

- [ ] All 6 payloads created and added to a single configuration profile (or separate profiles if your organization requires granular control)
- [ ] Profile is scoped to the **Design team group** (25 devices)
- [ ] Profile deployment level set to **Enforce** (not advisory)
- [ ] Test deployment to a **pilot group** (2–3 devices) before fleet-wide rollout
- [ ] Monitor **compliance reports** in JAMF for 7 days post-deployment to identify false positives
- [ ] For each false positive, document the cause and adjust the profile or create an exception
- [ ] Document all exceptions (devices or users that cannot meet a requirement) and obtain security approval
- [ ] Schedule regular compliance reviews (monthly) to detect drift or new exceptions
- [ ] Set up **alerts** in JAMF to notify admins of non-compliant devices within 24 hours
- [ ] Create a **remediation runbook** for users/admins when compliance drifts (e.g., if firewall is manually disabled)

---

## Version-sensitive settings — mandatory verification steps

Before deploying, verify these settings in your JAMF Admin console against your current server version and macOS target versions:

1. **FileVault payload:** Check if labeled "Encryption", "Full Disk Encryption", or "FileVault 2". Verify the toggle is `Enforce`, not just `Check`.
2. **Gatekeeper options:** Confirm the dropdown includes "App Store and identified developers" (exact label may be "Allow App Store and identified developers"). Do not use "Anywhere".
3. **Minimum OS version:** Test by creating a test profile with an arbitrary version (e.g., 99.0) and verify JAMF rejects devices below that threshold correctly.
4. **Firewall sub-options:** Check if "Stealth Mode" is available as a separate toggle; if absent in your version, standard firewall enablement is sufficient.
5. **Login Window / Session Lock:** Verify the payload type name in your JAMF version. Older versions may use "Login Window"; Sonoma+ may use "Session Lock".
6. **Software Update / Automatic Updates:** Distinguish between "Automatic security updates" and "Automatic major OS version updates" — configure only the former to avoid surprise major version upgrades.

---

## Post-deployment validation

After 7 days:

```
JAMF Admin Console → Compliance → Noncompliance Reports

For each requirement:
  - Expected non-compliant count: <= 2 (acceptable: devices in update cycle)
  - If > 5 non-compliant: likely false positive or configuration error; review
  
Example output:
  FileVault:        23/25 compliant (1 device mid-upgrade, 1 hardware incompatible) ✓
  Gatekeeper:       25/25 compliant ✓
  Minimum OS:       24/25 compliant (1 device mid-update) ✓
  Firewall:         22/25 compliant (3 devices with legacy software exception) ⚠
  Password after sleep: 25/25 compliant ✓
  Auto updates:     25/25 compliant ✓
```

If any category shows non-compliance > 3, pause and investigate before proceeding to the next batch of devices.
