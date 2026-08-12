# Step-by-Step Guide: Add a Windows App to the Intune App Catalog (Pre-Rollout)

| Field | Detail |
|---|---|
| Title | Intune App Catalog Onboarding Guide - Windows App (Pre-Phased Rollout) |
| Version | 1.0 |
| Date | 11/08/2026 |
| Audience | DWP Engineers (including first-time Intune app deployers) |
| Worked example | FinBridge Connect v3.1 (.intunewin) |

---

## 0. Before You Start

1. Confirm you have Intune admin permissions to create and assign applications.
2. Confirm you have the packaged installer file available:
   - FinBridge Connect v3.1 packaged as a .intunewin file.
3. Confirm install and uninstall commands for this package:
   - Install command: FinBridgeConnect_Setup.exe /silent
   - Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
4. Confirm detection requirement for this package:
   - Registry value must equal:
     - Path: HKLM\SOFTWARE\FinBridge\Connect
     - Value name: Version
     - Value data: 3.1

---

## 1. Add the App in Intune

1. Open the Microsoft Intune admin center in your browser.
2. Navigate to the apps area.
   - Common path in many tenants: Apps -> All apps -> Add
   - UI Label Variation Warning: exact navigation labels and left-menu grouping can vary by tenant version, licensing, and portal updates. Verify the live labels in your own tenant before proceeding.
3. Select an app type.
   - For a .intunewin package like FinBridge Connect v3.1, select Windows app (Win32).
   - For Microsoft Store applications, select Microsoft Store app (new).
   - For a URL shortcut, select Web link.
   - UI Label Variation Warning: some tenants may still show older naming patterns. Always confirm you are choosing the app type that matches your package source.
4. Click Select (or equivalent action button shown in your tenant) to begin app creation.

---

## 2. Enter Required Fields for a Windows LOB App (.intunewin / Win32)

Follow each section in the app creation wizard in order.

1. App package file
   - Upload the .intunewin file for FinBridge Connect v3.1.
   - Wait for metadata parsing to complete.
   - UI Label Variation Warning: upload section names can differ slightly by tenant.

2. App information
   - Name: FinBridge Connect v3.1
   - Description: Finance desktop client for FinBridge workflows.
   - Publisher: FinBridge
   - Version: 3.1
   - Recommended: add owner/contact and category fields if present.

3. Program
   - Install command:
     - FinBridgeConnect_Setup.exe /silent
   - Uninstall command:
     - FinBridgeConnect_Setup.exe /uninstall /silent
   - Install behavior:
     - Select System when app must install machine-wide or requires elevation.
     - Select User only when the app is truly per-user and does not require admin rights.
   - For this worked example, use System context unless packaging notes explicitly require User context.
   - UI Label Variation Warning: install behavior labels may appear as Install behavior, Device context, or User/System context depending on portal version.

4. Requirements
   - OS architecture:
     - Select supported architectures (for example 64-bit, and 32-bit only if truly supported).
   - Minimum operating system:
     - Set minimum Windows 11 version required by FinBridge Connect v3.1.
   - Keep requirements strict enough to prevent incompatible devices from receiving the app.

5. Detection rules
   - Purpose: this tells Intune how to determine whether installation succeeded.
   - Supported detection approaches commonly used:
     - Registry key/value
     - MSI product code
     - File/folder path or file version
   - Worked example (registry):
     - Rule type: Registry
     - Key path: HKLM\SOFTWARE\FinBridge\Connect
     - Value name: Version
     - Detection method: String comparison equals
     - Expected value: 3.1
   - UI Label Variation Warning: some tenants split registry detection into multiple mini-fields with slightly different captions. Verify each field maps to key path, value name, operator, and expected value.

6. Return codes
   - Purpose: defines which installer exit codes Intune treats as success, soft reboot, hard reboot, retry, or failure.
   - Ensure your return code table includes at least:
     - 0 as Success
     - 3010 as Soft reboot (common for installers)
     - 1641 as Hard reboot (if applicable)
   - Any code not explicitly mapped may be treated as failure, depending on configuration.
   - UI Label Variation Warning: return-code categories can vary slightly by tenant UI. Validate meanings before saving.

7. Review + create
   - Review all sections carefully.
   - Create the app entry.
   - Wait until the app object appears in All apps.

---

## 3. Assignment Basics (Do This Before Any Broad Rollout)

1. Open the newly created app, then go to Assignments.
2. Choose assignment type based on rollout intent:
   - Required:
     - Intune installs automatically for targeted users/devices.
   - Available for enrolled devices (or Available):
     - App is offered in Company Portal for self-service install.
   - Uninstall:
     - Intune removes the app from targeted users/devices.
   - UI Label Variation Warning: phrasing may differ slightly, especially around Available assignment wording.
3. Assign to a small pilot group first.
   - Do not target the full 10,000-device fleet directly.
   - Reason:
     - Confirms install command, detection rule, and requirements work in production conditions.
     - Limits blast radius if packaging, detection, or compatibility issues occur.
     - Allows rollback or configuration correction before broad deployment.
4. Worked example pilot scope:
   - Create a pilot group of around 50-100 test endpoints representing different hardware profiles.
   - Include a subset of lower-spec devices if they are expected in production.

---

## 4. Verification Steps

1. Confirm app appears in the catalog
   - Go to Apps -> All apps.
   - Search for FinBridge Connect v3.1.
   - Open it and verify:
     - Name, publisher, version
     - Commands
     - Detection rule
     - Assignments
   - UI Label Variation Warning: list filters and tabs vary by tenant; verify by app details rather than relying only on view layout.

2. Confirm install status on an assigned test device
   - In the app record, open Device install status (or equivalent status pane in your tenant).
   - Filter for a known pilot device.
   - Check reported deployment state.

3. Interpret common deployment statuses
   - Installed:
     - Intune detected installation success based on detection rules.
   - Failed:
     - Installation failed or detection did not pass after install attempt.
     - Action: review return code, command syntax, and device logs.
   - Not applicable:
     - Device does not meet assignment or requirements criteria (for example unsupported architecture or OS version).
     - Action: verify requirement rules and assignment targeting.

4. Validate detection specifically for this worked example
   - On one successful pilot endpoint, confirm registry value exists and equals expected:
     - HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1
   - If Intune shows Failed but registry is correct, review detection rule operator and data type.

5. Record pilot outcome before phased rollout
   - Document success rate, failure patterns, and corrective actions.
   - Proceed to phased rollout only after pilot results meet your release gate criteria.

---

## 5. Minimum Pre-Rollout Exit Criteria

1. App entry is visible and correctly configured in Intune catalog.
2. Pilot assignment is in place (not broad production scope).
3. At least one full install/uninstall cycle is validated on pilot devices.
4. Detection rule reliably identifies FinBridge Connect v3.1.
5. Deployment status review confirms acceptable success rate for next rollout phase.

---

## 6. Quick Troubleshooting Prompts for New Engineers

1. If every device shows Failed:
   - Re-check install command syntax and return code handling.
2. If app installs but Intune still shows Failed:
   - Re-check detection rule path, value name, data type, and expected value.
3. If many devices show Not applicable:
   - Re-check OS architecture and minimum OS requirement filters.
4. If nothing appears to install:
   - Re-check assignment target group membership and assignment type.

---

This guide should be used before any phased rollout starts. The key control is always the same: onboard the app correctly, assign to pilot first, verify status outcomes, then expand in controlled rings.
