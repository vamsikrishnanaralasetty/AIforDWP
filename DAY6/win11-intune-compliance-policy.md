# Windows 11 Intune Compliance Policy — DWP Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-10  
**Policy Scope:** Windows 11 Managed Devices (Intune MDM)  
**Grace Period:** 7 days applied to all settings  

---

## How to Apply Grace Period

In the Intune compliance policy creation wizard, under **Actions for noncompliance**, set:
- Action: **Mark device noncompliant**
- Schedule (days after noncompliance): **7**

This applies universally to all requirements below.

---

## Requirement 1 — BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | `Require BitLocker` |
| **Value** | `Require` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **Device Health** → BitLocker |

**Effect:**  
Intune queries the Windows Health Attestation Service (HAS) to confirm the OS drive is protected by BitLocker. A device without BitLocker enabled will be marked non-compliant after the grace period.

**False-Positive Risk:**  
- Device has BitLocker enabled but the HAS report has not yet synced — common on newly enrolled devices or after an OS update.  
- Virtual machines (Hyper-V, AVD session hosts) that do not support TPM-backed BitLocker will always fail unless a software-based encryptor is configured.  
- Devices where the TPM was cleared or re-provisioned; HAS attestation can lag by several hours.

**Recommendation:**  
Allow the 7-day grace period to absorb HAS sync delays. For AVD session host VMs, scope this policy to physical device groups only using an AAD dynamic group filter (`deviceTrustType -eq "AzureAD"` for hybrid or `model -ne "Virtual Machine"`). Do not weaken the setting itself.

---

## Requirement 2 — Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Require Secure Boot to be enabled on the device` |
| **Value** | `Require` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **Device Health** → Secure Boot |

**Effect:**  
Intune verifies via HAS that the device firmware boots only with software trusted by the OEM. Prevents boot-level rootkits and unsigned bootloaders from loading.

**False-Positive Risk:**  
- Older hardware (pre-2013) that does not support Secure Boot in UEFI firmware will always fail.  
- Devices where a technician disabled Secure Boot to run a diagnostic tool and did not re-enable it.  
- Dual-boot Linux configurations where Secure Boot was turned off to load an unsigned kernel.

**Recommendation:**  
Audit your hardware estate before enabling. Create a separate compliance policy without this requirement for any legacy hardware groups, and document exceptions in the Known Error register. Re-enable Secure Boot on any device where it was manually disabled by IT.

---

## Requirement 3 — Minimum OS Build (N-1 Rule)

| Field | Detail |
|---|---|
| **Setting Name** | `Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **Device Properties** → Operating System Version → Minimum OS version |

**Effect:**  
Devices running a build older than 22621.2861 (one cumulative update behind the latest known-good build 22621.3155) are marked non-compliant. Ensures all devices carry at minimum the N-1 security patch level.

**False-Positive Risk:**  
- Devices with Windows Update paused or deferred via GPO/WUfB policy will fall behind quickly and trigger this.  
- Devices that failed to apply a cumulative update due to low disk space or a Windows Update error.  
- Feature update holdback rings may keep devices at an older build intentionally — the minimum build must be reviewed whenever DWP advances its update rings.

**Recommendation:**  
Pair this compliance policy with a Windows Update for Business ring policy to enforce monthly CU delivery within the grace period window. Review and update this minimum build value at least monthly. Consider using the **Windows 11 22H2** build format `10.0.22621.XXXX` and document the review cadence in the runbook.

> **⚠ UI PATH NOTE:** The exact label "Minimum OS version" has been consistent in Intune across recent releases, but Microsoft periodically reorganises the **Device Properties** blade. If this field is not visible, check that the policy platform is set to **Windows 10 and later** (not Windows 10/11 split profiles). Verify in the current Intune admin centre at: `intune.microsoft.com` → Devices → Compliance policies.

---

## Requirement 4 — Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting Name** | `Require real-time protection` |
| **Value** | `Require` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **System Security** → Defender → Require real-time protection |

**Effect:**  
Confirms that Microsoft Defender Antivirus real-time protection is active. Devices with RTP disabled — either manually or by a conflicting third-party AV — are marked non-compliant.

**False-Positive Risk:**  
- Third-party antivirus products (e.g., CrowdStrike, Trend Micro) that register with Windows Security Centre as the active AV will cause Defender to enter passive mode, which Intune may read as RTP being off.  
- Tamper Protection policy conflicts can temporarily disable RTP during an update cycle.  
- Devices mid-way through AV signature update where the engine briefly restarts.

**Recommendation:**  
If a third-party EDR is deployed estate-wide, validate whether Intune correctly reads its security state via the Windows Security Centre API. If the third-party AV registers correctly, this setting should pass. If not, consider using **Microsoft Defender for Endpoint** (MDE) integration in Intune instead — the MDE connector provides a richer compliance signal. Document the AV product in scope.

---

## Requirement 5 — Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | `Microsoft Defender Firewall` |
| **Value** | `Require` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **System Security** → Windows Defender Firewall → Microsoft Defender Firewall |

**Effect:**  
Verifies that Windows Defender Firewall is enabled across Domain, Private, and Public network profiles. A device with firewall disabled on any profile is marked non-compliant.

**False-Positive Risk:**  
- Legacy line-of-business applications that disable the Windows firewall during install (common with older enterprise software) will fail this check.  
- Third-party firewall products (e.g., Cisco AnyConnect embedded firewall) do not always register with the Windows Security Centre, leaving Intune blind to their presence.  
- GPO conflicts where a domain GPO sets firewall state differently from the Intune profile can produce inconsistent readings.

**Recommendation:**  
Audit LOB application install scripts for firewall disable commands and remediate. Where a third-party firewall is intentionally used, confirm it registers with Windows Security Centre. Avoid disabling Windows Firewall via GPO — use firewall rules to create exceptions instead of disabling the service entirely.

---

## Requirement 6 — A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting Name** | `Require a password to unlock mobile devices` |
| **Value** | `Require` |
| **Supporting Settings** | Minimum password length: `8`; Password type: `Alphanumeric` (or `Numeric` for PIN-only estates) |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **System Security** → Password → Require a password to unlock mobile devices |

**Effect:**  
Enforces that a local PIN or password is set on the device. Devices with no screen lock configured are non-compliant. Supports Windows Hello for Business PIN as a compliant credential.

**False-Positive Risk:**  
- Shared/kiosk devices configured with auto-logon have no interactive PIN/password and will always fail.  
- Devices where Windows Hello enrollment failed (e.g., missing TPM) and the user has not set a fallback password.  
- The label "mobile devices" in the setting name is misleading — on Windows 10/11 it controls the device password requirement, not just mobile.

**Recommendation:**  
Exclude kiosk and shared device groups from this compliance policy and apply a separate dedicated kiosk compliance policy. Ensure Windows Hello for Business is deployed via an Intune configuration profile so users have a compliant credential path before the grace period expires.

> **⚠ UI PATH NOTE:** The label "Require a password to unlock mobile devices" is known to be confusing and Microsoft has discussed renaming it. As of early 2024 training data it remains unchanged, but verify the current label in the Intune admin centre. The functional behaviour on Windows 11 PCs is correct regardless of the label text.

---

## Requirement 7 — Device Must Not Be Jailbroken or Rooted

| Field | Detail |
|---|---|
| **Setting Name** | `Device must not be jail broken or rooted` |
| **Value** | `Block` |
| **Intune UI Path** | Devices → Compliance policies → Create policy → Windows 10 and later → **Device Health** → Windows Health Attestation Service evaluation rules → Require the device to be at or under the machine risk score → `Clear` |

**Effect:**  
On Windows, "jailbroken/rooted" maps to the HAS integrity check. Setting this to `Block` (or requiring a `Clear` risk score from MDE/HAS) prevents devices with compromised boot integrity, disabled code signing, or tampered system files from being marked compliant.

**False-Positive Risk:**  
- Test/dev machines running unsigned drivers or custom kernels (e.g., kernel debugging enabled) will fail integrity checks.  
- Devices where Secure Boot was recently re-enabled but HAS has not yet re-attested.  
- Misconfigured Credential Guard rollout can temporarily alter the HAS attestation state.

**Recommendation:**  
Pair this with Microsoft Defender for Endpoint's device risk score integration for a richer signal. Set the MDE risk score threshold to **Medium** at minimum, rather than relying solely on HAS, to reduce false positives from HAS sync delays while still blocking high-risk devices.

> **⚠ UI PATH NOTE:** Windows 11 does not have a concept of "jailbreak" in the mobile sense. The Intune UI inherited this label from iOS/Android policies. On Windows, the closest native control is via **HAS Device Health** combined with **MDE risk score**. If your tenant has MDE integration enabled, use: Devices → Compliance policies → **Microsoft Defender for Endpoint** section → `Require the device to be at or under the machine risk score`. This provides a more accurate and up-to-date signal than HAS alone.

---

## Summary Table

| # | Requirement | Setting Name | Value | Grace Period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require | 7 days |
| 2 | Secure Boot enabled | Require Secure Boot | Require | 7 days |
| 3 | Minimum OS build (N-1) | Minimum OS version | 10.0.22621.2861 | 7 days |
| 4 | Defender RTP on | Require real-time protection | Require | 7 days |
| 5 | Firewall all profiles | Microsoft Defender Firewall | Require | 7 days |
| 6 | PIN or password set | Require a password to unlock mobile devices | Require | 7 days |
| 7 | Not jailbroken/rooted | Device not jail broken or rooted / MDE risk score | Block / Clear | 7 days |

---

## UI Path Change Flags

The following settings carry a risk of UI path change since training data (knowledge cutoff early 2024). Verify each in the live Intune admin centre before deployment:

| Flag | Setting | Reason |
|---|---|---|
| ⚠ | Minimum OS version | Microsoft periodically restructures Device Properties; confirm field exists under the Windows 10 and later platform |
| ⚠ | Require a password to unlock mobile devices | Label is under review by Microsoft; functional behaviour is correct but the display name may differ |
| ⚠ | Jailbroken/rooted (Windows) | This is iOS/Android terminology carried into Windows policies; the preferred Windows path is now via MDE integration — verify current UI location |
| ⚠ | HAS evaluation rules | Microsoft has been migrating some HAS settings into the MDE connector blade; confirm whether standalone HAS settings are still surfaced in your tenant |

---

## Recommended Next Steps

1. **Create a pilot ring** — assign the policy to a small test group first to surface false positives before broad rollout.  
2. **Enable MDE integration** — connect Defender for Endpoint to Intune (`Tenant admin → Connectors → Microsoft Defender for Endpoint`) to strengthen requirements 4 and 7.  
3. **Review minimum build monthly** — update Requirement 3's build number after each Patch Tuesday validation cycle.  
4. **Document exclusions** — any device group excluded from a requirement must be logged in the Known Error register with an owner and review date.  
5. **Test grace period** — confirm the 7-day action is configured under Actions for noncompliance, not as a setting-level grace period (the two behave differently in Intune).
