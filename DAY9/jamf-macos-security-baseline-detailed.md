# macOS Security Baseline — JAMF Configuration Profile Mapping (Detailed)
**Target fleet:** Design team — 25 macOS devices  
**Date:** 2026-08-13  
**Compliance framework:** Internal DWP security baseline  
**Baseline version:** 2.0 (detailed reference version)  
**Reference version:** Based on JAMF Admin API v2 and macOS 13–15 configurations  

---

## How to Apply Compliance Grace Period

In JAMF, compliance is managed via **Mobile Device Compliance Policies** and enforced through **Conditional Access** (if SSO/identity integration is active) or **Smart Groups** (for manual enforcement actions).

**Recommended grace period:** 7 days from policy deployment.

**Implementation method:**
1. Create the configuration profile (see requirements below)
2. Scope to **Smart Group:** "Design Team — macOS" (25 devices)
3. Set deployment **enforcement** level to "Enforce" (not advisory)
4. Deploy to **pilot group** (2 devices) first
5. Monitor compliance report for 7 days; address false positives
6. Expand to full 25-device fleet

---

## Pre-deployment verification

Before deploying any JAMF profile, confirm:

- [ ] Your JAMF Server version (Settings → Software Server → Server Version)
- [ ] Your macOS minimum version in scope (must be 13.0 Ventura or later for full feature support)
- [ ] Your JAMF account has `Create Configuration Profiles` permission
- [ ] A test device running the minimum target macOS version is available for pilot testing
- [ ] JAMF MDM enrollment certificate is valid and not expiring within 90 days

---

## Requirement 1 — FileVault Disk Encryption Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Enable FileVault` |
| **Payload type** | `Security & Privacy` → `Encryption` |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Security & Privacy** pane → **Encryption** section |
| **Setting value** | Set toggle to **Enabled**. Optional sub-options: enable `Redirect FileVault key to JAMF` (Enterprise Key Storage) if available in your version |
| **Enforcement level** | **Enforce** (not "Check") |

**Effect:**

FileVault 2 is macOS's full-disk encryption system that encrypts the entire OS and user data at rest. When enabled via JAMF, the device begins encryption immediately (if not already encrypted) and maintains encryption status going forward. The encryption key is either stored locally on the Mac's secure enclave (Secure Boot enabled) or stored in JAMF's Enterprise Key Storage if your JAMF license includes that feature.

At the file-system level, all data written to the SSD is cryptographically protected. An attacker who physically removes the drive cannot access user files, Keychain credentials, or system configuration without the FileVault recovery key. Transparent to the user — encryption/decryption happens at the OS level without user perceivable performance impact.

**False-Positive Risk:**

- **Pre-encrypted devices reported as non-compliant:** If a device was provisioned with FileVault already enabled before the JAMF profile was deployed, the profile must be set to **Enforce** (not "Check" or "Advisory"). Setting to "Check" merely reads status; "Enforce" ensures compliance. Additionally, if you accidentally create a *separate* encryption profile without matching the existing encryption status, JAMF may report the device as failing to comply. **Remediation:** verify the existing device has FileVault on, then create the JAMF profile in "Enforce" mode to match the current state.

- **M1/M2/M3 Mac Secure Enclave encryption state confusion:** Newer Apple Silicon Macs have hardware-level encryption built into the Secure Enclave and may not require traditional FileVault if Secure Boot is enabled. JAMF might report these as "encrypted via Secure Enclave" rather than "FileVault enabled." The device is actually secure, but may show a compliance mismatch. **Remediation:** update the JAMF profile payload for Apple Silicon Macs to accept Secure Enclave encryption as equivalent, or verify JAMF version supports the newer encryption state reporting.

- **APFS hardware encryption vs. FileVault:** Modern SSDs (NVMe) and external drives formatted as APFS include hardware-level encryption. This is not the same as FileVault. A device with APFS hardware encryption but without FileVault enabled will report as non-compliant. **Remediation:** FileVault must be enabled explicitly; APFS encryption alone is insufficient.

- **Recovery key escrow delays:** If using Enterprise Key Storage (JAMF recovers the FileVault key for IT recovery), the first sync after enrollment may delay escrow by several minutes. Devices checked for compliance too quickly after enrollment may appear non-compliant. **Remediation:** allow a 15-minute grace period after first MDM enrollment before enforcing FileVault compliance.

- **Failed encryption mid-process:** If a device was set to encrypt but the process was interrupted (power loss, user shutdown), encryption may be paused. JAMF reports this as non-compliant even though encryption will resume. **Remediation:** restart the device to resume encryption, or check the encryption progress in System Settings → Privacy & Security → FileVault.

**Recommendation:**

Enable FileVault via JAMF profile set to **Enforce**. Use **Enterprise Key Storage** if your JAMF licence supports it — this ensures that even if a device is lost, IT can recover the encryption key and access the data. For Apple Silicon Macs (M-series), test the profile on at least one M1/M2 device before fleet rollout to confirm JAMF correctly reports encryption status.

Monitor the JAMF compliance report daily for the first week. Any device showing "non-compliant — FileVault disabled" after 7 days likely has an issue (encryption paused, key escrow failed, or unsupported hardware).

> **⚠️ UI PATH NOTE:** The "Encryption" pane under Security & Privacy was introduced in JAMF 10.35 and renamed from "Full Disk Encryption" in JAMF 11.0. Verify your JAMF version displays the **Security & Privacy → Encryption** section. If you see "Full Disk Encryption" instead, you are on an older JAMF version; consult your JAMF admin to upgrade the profile schema or version.

---

## Requirement 2 — Gatekeeper Must Be Enabled (Identified Developers Only)

| Field | Detail |
|---|---|
| **Setting Name** | `Allow applications downloaded from:` |
| **Payload type** | `Restrictions` → `System Security` (or `Security & Privacy` → `Gatekeeper` on newer versions) |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Restrictions** pane → **System Security** section → find "Allow apps downloaded from" dropdown |
| **Setting value** | Select **"App Store and identified developers"** from dropdown. *Do not select "Anywhere"* (that disables Gatekeeper entirely). |
| **Enforcement level** | **Enforce** |

**Effect:**

Gatekeeper is macOS's code-signing and app verification system. When set to "App Store and identified developers," only two types of applications are allowed to run:

1. Applications downloaded from the Mac App Store (all have been reviewed and signed by Apple)
2. Applications signed with a valid Apple Developer certificate (registered developers)

At launch, the kernel checks the app's code signature. If the signature is missing, invalid, or from an untrusted developer, the app is blocked and a system dialog warns the user. The user can override by right-clicking and selecting "Open," but this requires administrator credentials.

This prevents malware and sideloaded unsigned binaries from running without explicit user approval and admin authentication.

**False-Positive Risk:**

- **Legacy in-house applications unsigned:** Many organizations have proprietary tools, scripts, or applications that were built before code-signing requirements existed. These will be blocked by Gatekeeper and trigger non-compliance even if they are trusted internal tools. **Remediation:** sign the app with your organization's Apple Developer certificate, or distribute via JAMF App Catalog (which can auto-grant code-signing exceptions). This is the only secure fix; disabling Gatekeeper defeats the purpose.

- **Expired developer certificate:** If the developer certificate used to sign an app has expired, Gatekeeper validation fails. The app is blocked even if it was previously trusted. **Remediation:** re-sign the app with a current developer certificate. Monitor certificate expiry dates and establish a renewal cadence (annually, before expiry).

- **Missing notarization:** Starting with macOS 10.15 Catalina, Apple requires apps to be **notarized** in addition to signed. Notarization is Apple's post-signature malware scan. Apps lacking notarization are blocked by Gatekeeper on Catalina and later. Older Gatekeeper policies that only check signatures will incorrectly report these as compliant (they are not). **Remediation:** developers must submit apps to Apple's Notarization Service. JAMF can assist by distributing pre-notarized apps via its App Catalog.

- **Cached approval from before policy enforcement:** If an app was installed and run before Gatekeeper enforcement was applied, the OS may have cached approval. After the policy is enforced, the same app may still run without triggering Gatekeeper if the cache has not cleared. **Remediation:** restart the device to clear approval cache and force Gatekeeper re-evaluation, or manually check System Preferences → Security & Privacy → General to verify Gatekeeper status.

- **Bundle integrity changes:** If an app is updated (new version installed in-place), and the new version is unsigned or signed with a different certificate, Gatekeeper re-evaluates the app on next launch. If the new certificate is not trusted, the app is blocked even if the old version was allowed. **Remediation:** update the app via the App Store or a JAMF-distributed package to ensure signatures remain valid.

- **Third-party security software conflicts:** Some enterprise security agents (e.g., CrowdStrike, SentinelOne) inject code into app binaries during launch, which can break app code signatures. This causes Gatekeeper to block the app. **Remediation:** coordinate with your security team to whitelist the app or use endpoint protection that preserves code signatures.

**Recommendation:**

Deploy Gatekeeper set to "App Store and identified developers" and enforce it. Before deployment, inventory your fleet's applications. For any unsigned in-house tools, immediately plan to either:

1. Code-sign and notarize them (preferred)
2. Distribute via JAMF App Catalog with exception rules
3. Retire them if they're legacy/no longer needed

Communicate to the Design team that they may be prompted to re-authenticate when launching a previously unsigned tool for the first time after this policy takes effect. Plan an exception process for any specialized software (CAD tools, design suites, video editing) that may not support notarization yet.

> **⚠️ UI PATH NOTE:** The "System Security" section was renamed to "Gatekeeper" in JAMF 10.40+. If you do not see "System Security," you are on an older JAMF version. Additionally, the "Allow apps downloaded from" dropdown label has been changed to "Gatekeeper" on recent macOS and JAMF versions (Sonoma+). Verify in your JAMF instance that the setting is clearly labeled and the dropdown includes "App Store and identified developers" option.

---

## Requirement 3 — Minimum macOS Version (N-1 Release)

| Field | Detail |
|---|---|
| **Setting Name** | `Minimum OS Version` |
| **Payload type** | `Restrictions` → `OS Updates` (or `Restrictions` → `System Updates` in older versions) |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Restrictions** pane → **OS Updates** section → "Minimum OS version" field |
| **Setting value** | Enter version in format `14.7` (for Sonoma 14.7) or `15.1` (for Sequoia 15.1). *Current example:* If macOS 15.2 is the latest stable release, set minimum to `14.7` or the latest Sonoma point release. Update quarterly as new releases ship. |
| **Enforcement level** | **Enforce** |

**Effect:**

JAMF queries the device's current macOS version at compliance check time. If the version is older than the specified minimum, the device is marked non-compliant. The goal is to enforce the N-1 release rule: all devices run either the current stable release or the immediately prior major release.

This ensures consistent patch levels and reduces support burden. A device running macOS 13.6 when the minimum is 14.7 will be flagged, preventing that older version from becoming orphaned.

**False-Positive Risk:**

- **Devices mid-upgrade:** A device that has started downloading or installing a new macOS version will temporarily report the old version until the upgrade completes and restarts. JAMF compliance checked before the upgrade is complete will show non-compliance. **Remediation:** apply a 48–72 hour grace period after announcing OS upgrade requirements. Some organizations allow users to schedule the upgrade for a specific weekend; monitor compliance after that date.

- **Hardware incompatibility — older Macs cannot upgrade:** Macs manufactured before ~2015 cannot upgrade to the latest macOS. For example:
  - 2013 MacBook Air: maximum macOS is High Sierra (10.13)
  - 2015 MacBook Pro: maximum macOS is Big Sur (11.x)
  - 2017 MacBook Air: maximum macOS is Sonoma (14.x), NOT Sequoia (15.x)
  
  These devices will be perpetually non-compliant if the minimum version requirement exceeds their hardware capability. **Remediation:** perform a hardware audit before setting the minimum version. Create separate compliance policies for older vs. new hardware, or establish a device retirement plan for hardware that cannot meet the N-1 minimum.

- **Beta and developer builds:** Macs enrolled in the macOS Beta program report version strings like `15.0 Beta 3` or `15.0 Developer Preview 5`. JAMF's version comparison logic may not correctly parse these as "newer than" or "older than" the minimum threshold (e.g., is `15.0 Beta 3` considered 15.0 or older/newer than 14.7?). **Remediation:** exclude beta/developer builds from the N-1 compliance policy. Create a separate Smart Group for beta testers and apply a different (or no) OS version requirement to them.

- **System clock skew:** If a device's system clock is incorrectly set (e.g., 1 year in the future or past), JAMF version checks may misinterpret certificate validity or version numbers. **Remediation:** ensure all devices have NTP time sync enabled (usually automatic; verify in System Settings → Time & Date).

- **macOS point release fragmentation:** macOS releases security patches as point releases (e.g., 14.6.1, 14.7, 14.8). If you set the minimum to `14.7` but some devices stay at `14.6.1` due to delayed updates, they will be non-compliant even though they received security patches. **Remediation:** use JAMF's Software Update policy to automatically deliver point releases within 7 days of release, or set the minimum version one point release behind the latest (e.g., if latest is 14.8, set minimum to 14.7).

- **Devices in update hold-back programs:** Some organizations intentionally hold devices back from the latest macOS release (e.g., waiting for a third-party vendor to certify compatibility). These devices will be non-compliant and need exceptions. **Recommendation:** maintain a "macOS Update Holdback" Smart Group for devices with documented compatibility issues and apply a different OS version requirement to them.

**Recommendation:**

Set the minimum OS version to the latest point release of the N-1 major release. *Current example (as of early 2026):* If macOS 15.2 (Sequoia) is current stable, set minimum to `14.7` (Sonoma 14.7).

Review and update this setting **quarterly** after each macOS major release (usually in fall). Create a calendar reminder in your IT process to review this requirement every September, December, March, and June.

Perform a hardware audit before enabling this requirement:
- Count devices by macOS capability (which major versions they can run)
- Identify any devices that cannot meet the N-1 minimum
- Create a separate Smart Group and exception policy for older hardware
- Plan device retirement for hardware that cannot upgrade

Monitor compliance reports closely during the first 30 days. Devices showing "non-compliant — below minimum OS version" after 30 days indicate either:
- Failed OS update (low disk space, update errors)
- Hardware incompatible with newer macOS (requires exception or retirement)
- User intentionally avoiding the update (requires communication or enforcement)

> **⚠️ UI PATH NOTE:** The "OS Updates" vs. "System Updates" naming changed in JAMF 10.38. Older versions use "System Updates"; newer versions use "OS Updates". The field name "Minimum OS version" is consistent. If you cannot find this setting, verify you are in the **Restrictions** pane (not Device Updates pane) and check your JAMF version under Settings → Software Server → Server Version.

---

## Requirement 4 — Firewall Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Enable Firewall` |
| **Payload type** | `Security & Privacy` → `Firewall` (or `System Security` in some versions) |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Security & Privacy** pane → **Firewall** section |
| **Setting value** | Set toggle to **Enabled** (`true`). Sub-options: "Enable Stealth Mode" (optional but recommended) and "Allow built-in software" (usually enabled by default) |
| **Enforcement level** | **Enforce** |

**Effect:**

The macOS firewall (built on PF — Packet Filter) blocks all inbound network connections by default. Outbound connections are permitted. When enabled, the firewall monitors listening ports and prevents unauthorized services from accepting external connections.

With Stealth Mode enabled, the device does not respond to network discovery probes (e.g., ping, port scans) and becomes "invisible" on the network, reducing attack surface.

This is a network-layer control that prevents remote exploitation of listening services on the device.

**False-Positive Risk:**

- **Applications requiring inbound ports:** Software that requires the device to listen on a local port or accept inbound connections will fail without explicit firewall exceptions. Examples:
  - Development servers (Node.js on port 3000, Django on port 8000)
  - Network printers or device discovery services
  - VPN clients or remote desktop services that accept incoming connections
  - Collaboration tools that use P2P or mesh networks
  
  **Remediation:** create a firewall exception for each application that requires inbound connectivity. JAMF can include firewall rules in the profile, or document the exceptions in a team runbook.

- **User-level firewall bypass:** macOS allows users (without admin credentials, depending on configuration) to disable the firewall via System Settings → Network → Firewall. JAMF configuration ensures the *policy* is applied, but does not prevent *future* manual disable. If users have admin credentials, they can circumvent this setting. **Remediation:** pair this compliance policy with a **Restrictions** policy that removes users' ability to modify Security & Privacy settings, or use JAMF's conditional access to revoke access if firewall is manually disabled.

- **Third-party firewall conflicts:** If a device has installed third-party security software (e.g., Cisco AnyConnect, ZoneAlarm), that software may conflict with macOS firewall or replace it. JAMF may report the Apple firewall as off while the third-party firewall is on. **Remediation:** verify your security stack's firewall component and confirm it does not disable the Apple firewall; coordinate with your security team. Alternatively, create a Smart Group for devices with third-party firewalls and apply a different policy.

- **Kernel extension and System Extension delays:** Some security software installs kernel or system extensions that hook into the firewall. Installation and activation may take several minutes. JAMF compliance checked immediately after installation may report the firewall as not responding or disabled. **Remediation:** defer compliance enforcement for 15 minutes after a security software update, or restart the device.

- **Firewall rules not syncing on first enrollment:** When a device is first enrolled and the JAMF profile is pushed, the firewall may enable but custom rules may not apply immediately. Re-enrollment or a second sync may be needed. **Remediation:** allow 10 minutes between profile deployment and compliance check, or manually sync the device from the JAMF console.

**Recommendation:**

Enable the firewall via JAMF profile set to **Enforce**. Before deployment, survey the Design team's applications:

- Do they run local development servers? (If yes, document required ports: e.g., 3000, 8000, 8080)
- Do they use VoIP or video conferencing that requires P2P connections? (May need UDP outbound rules)
- Do they print to network printers via mDNS or Bonjour? (May need port 5353 inbound)

Create a firewall exception list and include it in the JAMF profile, or document it in a runbook: "If you develop locally on port 3000, IT will provide an exception via JAMF."

Enable **Stealth Mode** if your threat model prioritizes hiding devices from network scanning. Stealth Mode has minimal performance impact but makes the device "invisible" on the network (no ICMP/ping responses, no open port advertisement).

Monitor the JAMF compliance report for any "Firewall disabled" entries after 3 days. If more than 2 devices show this, investigate whether a third-party security tool is conflicting or users are manually disabling it.

> **⚠️ UI PATH NOTE:** The Firewall section was reorganised in JAMF 10.36 from "System Security" to its own "Firewall" subsection under Security & Privacy. Verify your JAMF version has the **Firewall** section visible. If you only see "System Security," you are on JAMF 10.35 or earlier; consult your JAMF admin about upgrading the profile schema.

---

## Requirement 5 — Login Password Required After Sleep or Screen Saver

| Field | Detail |
|---|---|
| **Setting Name** | `Require password after sleep/screen saver` |
| **Payload type** | `Login Window` (or `Session Lock` on macOS 13+) |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Login Window** pane → find "Require password after wake or screen saver" setting |
| **Related settings** | Screen Saver timeout: set to `10` minutes (or your org's idle policy). Automatic login: set to `Disabled` or `Never`. |
| **Setting value** | Set "Require password" to **Immediately** (or `0` seconds delay). Screen saver timeout `10` minutes. |
| **Enforcement level** | **Enforce** |

**Effect:**

When a Mac is idle, two separate timers are active:

1. **Screen saver timeout** (default 5–20 minutes): after inactivity, the screensaver activates, blanking the display and optionally playing a slideshow.
2. **Display sleep timeout** (default 10–30 minutes): the display enters a low-power sleep state.

When the user moves the mouse, presses a key, or opens a display-sleeping Mac, the session must be re-authenticated with the user's password. This prevents unauthorized access if a user walks away from an unlocked Mac.

**False-Positive Risk:**

- **Display sleep vs. screen saver confusion:** These are controlled by separate settings. A device may have screen saver disabled but display sleep enabled (or vice versa). JAMF's "Require password after wake" checks the *display wake* condition, not the screensaver. If display sleep is configured but screensaver is not, the device may display the login screen only after display sleep, not after screensaver. **Remediation:** configure *both* settings in the JAMF profile: screen saver timeout AND display sleep timeout, both requiring re-authentication.

- **Accessibility accommodations for motor disabilities:** Users with motor impairments may require longer timeouts (30+ minutes) to avoid frequent re-authentication. The 10-minute default may be too aggressive. **Remediation:** maintain an exception process in your IT onboarding; create a separate Smart Group for accessibility exceptions and apply a lenient timeout policy to them.

- **Automation tools and screen-blanking:** Some development tools, build systems, or SSH sessions remain active but appear idle from the OS perspective. After 10 minutes of no mouse movement, the screensaver activates and the OS logs the session out, stopping the automation. **Remediation:** document tools that require exemption from the idle-lock policy, or use JAMF to exclude development machines from this requirement via a Smart Group.

- **Fast-wake displays on M1/M2 Macs:** Apple Silicon Macs with ProMotion displays can wake extremely quickly. The display may wake before the OS processes the keystroke, and the login prompt may not appear immediately. Timing conflicts can occur. **Remediation:** test on a representative M1 or M2 device in your fleet before full rollout.

- **Remote desktop and VNC interactions:** If users access the Mac via remote desktop or VNC, the session is authenticated remotely. The local display session may still have a screensaver; when the user takes control via RDP, the login prompt appears, blocking RDP session takeover until they authenticate again locally. **Remediation:** if your fleet uses remote desktop access, test the interaction; you may need to exempt RDP-enabled devices from this policy or accept the additional authentication step.

- **Clock skew:** If the Mac's system clock is incorrect, idle timer calculations can misfire (e.g., 10 minutes may be calculated as 5 minutes or 60 minutes). **Remediation:** ensure NTP time sync is enabled.

- **User manually disabling screensaver:** macOS allows users to disable the screensaver via System Settings → Screen Saver. JAMF configuration enforces the *policy*, but does not prevent manual override if the user has admin credentials. **Remediation:** pair this policy with a **Restrictions** policy that prevents users from modifying System Settings, or accept that admin users can override and include that in your threat model.

**Recommendation:**

Deploy this setting with the following parameters:

- **Screen saver timeout:** 10 minutes (industry standard for office environments)
- **Require password after wake:** Immediately (0 seconds delay)
- **Automatic login:** Disabled (never auto-login after logout/sleep)

Before deployment, communicate to the Design team: "After 10 minutes of inactivity, your Mac will lock. You will need to re-enter your password to resume work." This sets user expectations and reduces support tickets.

For teams with special needs (animators, developers, accessibility users), establish an exception process. Create a Smart Group called "Exempt from Session Lock" and apply a lenient timeout (30 minutes) to those devices.

Monitor compliance reports for "Session Lock not configured" entries. These may indicate older devices where the payload type changed between macOS versions; manually re-enroll those devices to the latest profile.

> **⚠️ UI PATH NOTE:** The "Login Window" pane in JAMF was reorganised in macOS 13 (Ventura). Older JAMF versions use "Login Window"; Ventura and later may use "Session Lock" as the payload type. Additionally, sub-settings like "Allow fingerprint for unlock" and "Require password after wake" may be in different panes depending on JAMF and macOS version. Verify your JAMF version and the exact UI path before deployment. Test on a Ventura device to confirm the setting is applied correctly.

---

## Requirement 6 — Automatic Security Updates Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Automatic Security Updates` |
| **Payload type** | `Software Update` (or `System Updates` in older JAMF versions) |
| **JAMF UI Path** | Profiles → Configuration Profiles → Create → select **macOS** → **Software Update** pane → "Check for updates" and "Install security updates" toggles |
| **Setting value** | • `Check for updates automatically`: **Enabled** • `Install security updates automatically`: **Enabled** • `Install macOS updates`: **Disabled** (optional; prevents surprise major OS upgrades). • `Restart required`: set to automatic restart at **2:00 AM** (or off-hours, org-dependent). |
| **Enforcement level** | **Enforce** |

**Effect:**

When enabled, JAMF instructs the Mac to:

1. **Check for updates automatically** — once per day (typically at 2:00 AM), query Apple's Software Update servers for available patches.
2. **Download security patches** — when available, download critical security updates in the background.
3. **Install automatically** — apply the patches without user interaction.
4. **Restart automatically** — if the patch requires a reboot, restart the device at the scheduled time (e.g., 2:00 AM).

This ensures devices are patched quickly against known vulnerabilities and are not left exposed due to user neglect or procrastination.

**False-Positive Risk:**

- **Update installation during business hours:** If automatic restart is set to "immediate" or "user can choose," a device may restart mid-afternoon, disrupting active work. JAMF compliance may show "auto-updates enabled" (compliant), but users experience unplanned downtime. **Remediation:** set restart timing to off-hours (2:00 AM–4:00 AM) via the JAMF profile, or coordinate with the organization's change management to schedule restarts for a specific weekend night.

- **Incompatible third-party software after updates:** Some enterprise software (security tools, CAD software, design suites) may have compatibility issues with new macOS security patches. Automatic installation may break critical workflows. **Remediation:** maintain a "patch hold" list in your IT process; for each incompatible vendor, delay automatic updates by 1–2 weeks to allow the vendor to certify the patch. Use JAMF staged rollout or hold-back groups to apply updates in phases.

- **Network bandwidth constraints:** Automatic update downloads consume 200 MB–2 GB per patch, multiplied across 25 devices. If your office has bandwidth constraints, 25 simultaneous updates may degrade network performance. **Remediation:** configure automatic updates to download only on Wi-Fi (preventing download on cellular), or schedule downloads during off-hours, or use JAMF's bandwidth throttling features if available.

- **Beta builds and developer seeds:** Macs in Apple's beta seed program receive automatic updates to beta versions. Beta updates may have instability and are not production-ready. JAMF's automatic update setting may not distinguish between stable and beta releases. **Remediation:** disable automatic updates on beta seed devices, or clarify that only stable releases are candidates for automatic installation in the JAMF profile.

- **User authentication required for certain patches:** Some macOS security updates (e.g., Secure Enclave firmware updates) require the user to be logged in and present to complete installation. Automatic installation may fail silently if the device is logged out or in screensaver. **Remediation:** document that certain critical patches may require manual user action; test your org's common patches to identify which require authentication.

- **Failed updates and silent errors:** If an update fails (low disk space, corrupted download, permission errors), automatic retry may not occur. JAMF reports "auto-updates enabled" (compliant), but the device is actually unpatched. **Remediation:** configure JAMF to log Software Update failures and alert IT; establish a weekly manual audit of actual patch status (not just policy status).

- **Staged rollout delays:** Enterprise patching best practices recommend rolling out updates in stages (10% of fleet first, then 50%, then 100%). If automatic updates are enabled org-wide, all devices update simultaneously, increasing risk if the patch has a critical flaw. **Remediation:** use JAMF's staged deployment features to stagger updates by device group or Smart Group, rather than allowing all-at-once automatic installation.

**Recommendation:**

Deploy automatic security updates with the following settings:

- **Check for updates:** Enabled
- **Install security updates:** Enabled
- **Install macOS version updates:** Disabled (prevents surprise major OS upgrades like 14 → 15)
- **Restart required:** Enabled, scheduled for **2:00 AM on weekdays** (minimizes business disruption)

*Important:* Do **not** enable "Install macOS version updates" — this can cause major OS upgrades without IT coordination, breaking line-of-business software or requiring new hardware certification.

Before deployment, conduct a pilot with 3 devices for 2 weeks. Monitor:

- Do patches install without errors?
- Are restarts occurring at the scheduled time?
- Are any applications broken after updates?
- Is there bandwidth congestion?

After the pilot, deploy to the full 25-device fleet with a 7-day grace period for compliance.

Establish a manual monthly audit process:
- Query each device for current patch level (via JAMF API or macOS CLI: `softwareupdate -l`)
- Compare to Apple's latest security release bulletin
- If any device is behind more than 2 patches, investigate (failed update, user override, beta status)

**Known incompatibilities to test:**

- CrowdStrike Falcon sensor: test that auto-updates don't conflict with endpoint protection
- Design software (Adobe Creative Cloud, Autodesk): test that patches don't break these suites
- VPN clients (Cisco AnyConnect, Palo Alto GlobalProtect): test that network connectivity is maintained after auto-update restart

> **⚠️ UI PATH NOTE:** The "Software Update" pane naming has remained consistent in JAMF, but sub-setting labels changed in JAMF 10.32+. Older versions call "Install security updates automatically" → "Automatic install of security updates"; newer versions use "Install security updates automatically". The functional behaviour is identical. Verify in your JAMF version that the exact settings listed above exist under **Software Update** pane.

---

## JAMF Configuration Profile Deployment Checklist

### Pre-deployment (1 week before)

- [ ] All 6 payload types created and verified in your JAMF instance
- [ ] UI path verified against your JAMF version (Settings → Software Server → Server Version documented)
- [ ] Test JAMF instance (or non-production environment) has the profile created and tested
- [ ] One pilot device (Design team member's Mac) identified and ready for testing
- [ ] Backup of pilot device created (Time Machine or third-party clone)
- [ ] IT support team briefed on the 6 requirements and common false positives

### Deployment to pilot (3 devices)

- [ ] Configuration profile scoped to **Pilot Smart Group** (3 Design team Macs)
- [ ] Deployment marked as **Enforce** (not Advisory)
- [ ] Pilot devices manually synced to JAMF or automatic check-in triggered
- [ ] Compliance status checked within 15 minutes of deployment
- [ ] IT team monitors pilot devices for 7 days

### Pilot monitoring (days 1–7)

- [ ] Day 1: Check pilot compliance report for each requirement (expect ~90% compliance or higher)
- [ ] Days 2–3: Identify any false positives and document root cause
- [ ] Days 4–7: Validate that false positives were either resolved or documented as acceptable exceptions
- [ ] Collect feedback from pilot users (any usability issues, blocked applications, unexpected prompts?)
- [ ] If false positives > 20%, pause full rollout and investigate before proceeding

### Full deployment (to all 25 Design team devices)

- [ ] Configuration profile scope updated to **Design Team — All macOS** Smart Group (25 devices)
- [ ] Deployment timing: typically Friday evening or Monday morning (allows users to work with it full week)
- [ ] IT sends communication to Design team: "New security policies deployed. See IT wiki for details."
- [ ] Monitor compliance report daily for first 7 days
- [ ] Log any non-compliance and reach out to affected users

### Post-deployment (ongoing)

- [ ] Compliance audit: every Monday morning, check JAMF report for devices below 90% compliance
- [ ] Exception handling: document any devices that cannot meet a requirement and seek manager approval for exception
- [ ] Quarterly review: as new macOS versions release, update Requirement 3 (minimum OS version)
- [ ] Annual refresh: review this entire checklist and baseline to ensure it still aligns with organizational security goals

---

## Exception Management

Devices that cannot meet all 6 requirements require documented exceptions.

**Common exception scenarios:**

1. **FileVault not supported (very old Mac):** Create exception, retire device within 12 months
2. **Gatekeeper blocks legacy in-house app:** Remediation: code-sign the app and test; no exception needed
3. **Hardware cannot upgrade to N-1 OS minimum:** Create exception, retire device within 12 months
4. **Firewall blocks critical development tool:** Remediation: add firewall exception in JAMF profile; no exception needed
5. **Session lock (Requirement 5) too aggressive for accessibility:** Create exception for affected user, apply lenient timeout
6. **Auto-updates incompatible with certified third-party software:** Create exception for that device group, manage updates via IT ticket

**Exception process:**

- Document the device serial number, user, requirement, and reason
- Obtain approval from IT Manager and Security Officer
- Create a Smart Group for exceptions (e.g., "Firewall Exception — Dev Tools")
- Apply a separate JAMF profile to that Smart Group with the relaxed setting
- Set a review date (typically 6–12 months) to re-evaluate the exception
- Communicate the exception to the user

---

## Troubleshooting — Compliance Failures

| Symptom | Likely Cause | Troubleshooting Steps |
|---|---|---|
| FileVault: 10 of 25 devices non-compliant | Pre-encrypted devices; profile set to "Check" instead of "Enforce" | Verify JAMF profile payload is set to `Enforce`, not `Check`. Re-sync devices. |
| Gatekeeper: 3 of 25 devices non-compliant | Unsigned in-house apps being used | Inventory the 3 devices' applications. Coordinate with developers to code-sign and notarize apps. |
| Minimum OS: 5 of 25 devices non-compliant after 30 days | Hardware incompatibility or failed OS updates | Check S.M.A.R.T. status of the 5 devices' drives. Inspect System Preferences → Software Update for stuck updates. Create hardware compatibility audit. |
| Firewall: 2 of 25 devices non-compliant | Third-party security software interfering | Verify third-party AV/firewall status. Check if it disabled macOS firewall. Coordinate with security team. |
| Session Lock: all 25 devices compliant but users report no lockscreen | Display sleep not configured (only screensaver) | Verify JAMF profile includes *both* screensaver timeout AND display sleep timeout settings. |
| Auto-updates: devices compliant but 1 device 2 patches behind | Failed automatic update; device still compliant | Check JAMF logs (Devices → <device> → Logs). Query `softwareupdate -l` on the device. Investigate network/disk space issues. Manually trigger update via JAMF. |

---

## Compliance Report Template

Use this table weekly to track compliance:

| Requirement | Target (25) | Compliant | Non-compliant | Drift | Approved exceptions | Status |
|---|---|---|---|---|---|---|
| 1. FileVault | 25 | 24 | 1 | -1 | 0 | 🟡 1 device mid-upgrade |
| 2. Gatekeeper | 25 | 22 | 3 | -3 | 0 | 🔴 Unsigned apps blocked |
| 3. Min OS | 25 | 24 | 1 | -1 | 1 | 🟡 1 exempt (hardware incompatible) |
| 4. Firewall | 25 | 25 | 0 | 0 | 0 | 🟢 OK |
| 5. Session Lock | 25 | 25 | 0 | 0 | 0 | 🟢 OK |
| 6. Auto-updates | 25 | 24 | 1 | -1 | 0 | 🟡 1 device failed update |
| **OVERALL** | **25** | **24** | **1** | **-1** | **1** | **🟡 96% compliant** |

**Status code:**
- 🟢 All compliant; no action needed
- 🟡 <5% non-compliant; investigate; may be acceptable
- 🔴 >5% non-compliant; remediation required

---

## Sign-off and Approval

| Role | Name | Date | Notes |
|---|---|---|---|
| DWP Analyst (author) | — | 2026-08-13 | Initial 6-requirement baseline documented |
| JAMF Admin (reviewer) | — | | Verify all UI paths in your JAMF version |
| Security Officer (approver) | — | | Confirm requirements align with org security policy |
| IT Manager (endorser) | — | | Ready for pilot deployment to Design team |
