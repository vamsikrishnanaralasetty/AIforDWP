# KB Article: AVD Black Screen Post-Login — DWM / igdumd64.dll Crash

| Field | Detail |
|---|---|
| **Version** | v 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Audience** | L2 / L3 Desktop & AVD Engineers |
| **Related Runbook** | `avd-black-screen-dwm-runbook.md` |
| **Related RCA** | `avd-black-screen-incident-rca-2024-03-15.md` |
| **Known Error Record** | `known-error-avd-black-screen-pool-fin-01.md` |

---

## 1. Background

Azure Virtual Desktop (AVD) delivers Windows desktop sessions from centralised session hosts running in Azure. Each time a user signs in, Windows starts the **Desktop Window Manager** (dwm.exe) — the process responsible for compositing the visible desktop, rendering windows, and managing the graphics output of the session. DWM depends on a graphics rendering pipeline that includes hardware-acceleration modules loaded from the host's driver stack.

Session hosts are provisioned from **images** managed in Azure Compute Gallery. When an image update is promoted to a host pool, every host in that pool is re-imaged to the new version. If the new image introduces a regression anywhere in the graphics render stack, every session started on those hosts will encounter the fault at the exact moment DWM initialises — which is immediately after successful user authentication.

POOL-FIN-01 is the primary AVD host pool for the Finance department. POOL-FIN-02 is a secondary Finance pool and acts as the natural comparison reference in this failure pattern.

---

## 2. Symptoms

### What the engineer observes
- Multiple users from the same AVD host pool (e.g. POOL-FIN-01) raise tickets within a short window of each other, all with the same complaint
- Affected users are spread across different session hosts within the same pool — not isolated to one host
- Session hosts in the affected pool show normal `Available` status in the Azure Portal; no infrastructure-level alert fires
- On affected hosts, Event Viewer Application log shows a tight cluster of Event ID 1000 (Application Error) entries with `dwm.exe` faulting, followed immediately by Event ID 9009 (DWM exit) entries — see Section 4 for exact signatures
- On unaffected comparison hosts (POOL-FIN-02), Event ID 9011 (DWM started successfully) appears cleanly after logon; no matching Event 1000 exists in the incident window
- A preceding image update or host re-image correlates temporally with the start of user impact

### What the user reports
- "My screen goes black just after I log in"
- "I get disconnected and when I reconnect it just goes black again"
- "My screen was black for about 30 seconds then came back, but it keeps happening"
- "I can't use my desktop at all — it just shows a black screen"

> The partial-recovery variant (black screen for ~30 seconds then desktop appears) and the full disconnect-loop variant are both caused by the same underlying crash. Do not treat the 30-second recovery as a sign that the host is healthy.

---

## 3. Root Cause

An overnight image update applied to POOL-FIN-01 at approximately 02:00 introduced a **graphics/render stack regression** into the session host image. Specifically, the update delivered a version of the Intel graphics rendering module `igdumd64.dll` that is unstable during AVD session initialisation.

When a user successfully authenticates (LSM Event 21), Windows immediately starts DWM. DWM loads `igdumd64.dll` to initialise the hardware render pipeline. The module causes an access violation (`exception 0xc0000005` — null or invalid memory dereference), crashing `dwm.exe` within seconds of logon. Windows attempts to restart DWM, but the same dll is reloaded, causing a repeat crash. The session compositor becomes non-functional; the user's session either shows an unrendered black screen or is fully disconnected.

POOL-FIN-02 was not updated in the same wave and remained on a known-good image. DWM on POOL-FIN-02 hosts starts cleanly (Event 9011), confirming this is image-specific, not a platform-wide AVD or networking fault.

| Evidence item | What it confirms |
|---|---|
| Event 1000: `dwm.exe` faulting in `igdumd64.dll`, exception `0xc0000005` | DWM crashed due to graphics module fault |
| Event 9009: DWM process exited | DWM did not recover; session compositor failed |
| Event 21 immediately before each crash cluster | Authentication succeeded — this is a post-login render failure, not an auth failure |
| Event 40 (session disconnect) after 9009 | Session terminated as a consequence of DWM failure |
| Absence of Event 1000 / 9009 on POOL-FIN-02 hosts | Failure is image-specific, not infrastructure-wide |
| Kernel-General Event 1 at 02:03 on SHFIN-01-A | Host was rebooted after the 02:00 image update — confirms update was applied |

---

## 4. Detection

**Perform all steps below before acting. Do not skip to remediation without completing this section.**

### Event ID Quick Reference

All events referenced in this article come from two locations: **Event Viewer → Windows Logs → Application** and **Event Viewer → Windows Logs → System**. The table below lists every ID used — bookmark it before starting.

| Event ID | Log | Source | Level | Meaning in this incident |
|---|---|---|---|---|
| **21** | Windows Logs \ Application | `Microsoft-Windows-TerminalServices-LocalSessionManager` | Information | User session logon succeeded — auth is fine; fault is post-login |
| **40** | Windows Logs \ Application | `Microsoft-Windows-TerminalServices-LocalSessionManager` | Information | Session disconnected — appears immediately after each DWM crash |
| **1000** | Windows Logs \ Application | `Application Error` | Error | Application crash — **the primary fault signature**: `dwm.exe` faulting in `igdumd64.dll` |
| **9009** | Windows Logs \ Application | `Desktop Window Manager` | Error | DWM process exited — confirms crash was fatal; session compositor is down |
| **9011** | Windows Logs \ Application | `Desktop Window Manager` | Information | DWM started successfully — **healthy host reference signal**; present on POOL-FIN-02, absent on POOL-FIN-01 |
| **1** | Windows Logs \ System | `Microsoft-Windows-Kernel-General` | Information | OS boot record — confirms host rebooted after image update at 02:03 |

---

### Step D1 — Identify affected scope

In a browser, navigate to **portal.azure.com**. In the search bar type `Azure Virtual Desktop` → click **Azure Virtual Desktop** under Services → left nav → **Host pools** → click **POOL-FIN-01** → left nav under **Manage** → **Session hosts**.

In the Session hosts table, read the **OS version** column. Note which hosts show a different (newer) build number from the others — these are hosts that received the overnight image update.

> **Expected:** A subset (or all) of hosts in POOL-FIN-01 show the updated build. POOL-FIN-02 hosts show an older build. The updated hosts correlate with the pool where all user reports originate.

---

### Step D2 — Connect to a representative affected host

Connect to one of the hosts identified in D1 via **Azure Bastion** (preferred):

Portal search bar → `Virtual machines` → click the affected host (e.g. `SHFIN-01-A`) → left nav under **Connect** → **Bastion** → enter local admin credentials → **Connect**.

Alternatively: VM blade → **Connect → RDP** → download `.rdp` file → connect with admin credentials.

> **You need:** Azure RBAC — Desktop Virtualization Contributor, and local admin credentials on the session host.

---

### Step D3 — Filter Application log for DWM crash signature

**Log location:** Event Viewer → **Windows Logs** → **Application**  
**How to open:** `Win + R` → type `eventvwr.msc` → Enter. In the left panel expand **Windows Logs** → click **Application**.  
**Filter:** Right **Actions** panel → **Filter Current Log...** → **\<All Event IDs\>** field → type `1000` → **OK**.

For each result, click the row to select it, then read the **General** tab in the lower pane. Check the following three fields — all three must match:

| Field in General tab | Required value |
|---|---|
| `Faulting application name` | `dwm.exe` |
| `Faulting module name` | `igdumd64.dll` |
| `Exception code` | `0xc0000005` |

Also check the **Date and Time** column in the upper pane — the entry must be timestamped after 02:00 (the image update) and within the incident window.

> **Confirmed if:** At least one entry matches all three field values above, within the incident window.  
> **Not confirmed if:** Event 1000 entries exist but `Faulting application name` or `Faulting module name` differ — stop, do not proceed, re-triage using `avd-black-screen-ranked-hypotheses.md`.

**PowerShell fast-check (run on the affected host in an elevated prompt — faster than Event Viewer):**

```powershell
# Query the Application log for Event 1000 matching the DWM/igdumd64.dll signature
Get-WinEvent -FilterHashtable @{
    LogName   = 'Application'
    Id        = 1000
    StartTime = (Get-Date).Date   # from midnight today
} -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -like '*dwm.exe*' -and $_.Message -like '*igdumd64*' } |
    Select-Object TimeCreated,
                  @{ N='FaultingApp';    E={ ($_.Message -split '\r?\n' | Select-String 'Faulting application name').Line.Trim() } },
                  @{ N='FaultingModule'; E={ ($_.Message -split '\r?\n' | Select-String 'Faulting module name').Line.Trim() } },
                  @{ N='ExceptionCode';  E={ ($_.Message -split '\r?\n' | Select-String 'Exception code').Line.Trim() } } |
    Format-List
```

> **Expected output (confirmed):** One or more results where `FaultingApp` contains `dwm.exe`, `FaultingModule` contains `igdumd64.dll`, and `ExceptionCode` contains `0xc0000005`, timestamped after 02:00.  
> **Expected output (not confirmed):** No output, or output where the module is not `igdumd64.dll` — stop and re-triage.

---

### Step D4 — Confirm DWM exit events

**Log location:** Event Viewer → **Windows Logs** → **Application**  
**Filter:** Actions panel → **Clear Filter** → **Filter Current Log...** → **\<All Event IDs\>** field → type `9009` → **OK**.

For each result, check these fields:

| Field | Required value |
|---|---|
| **Source** column (upper pane) | `Desktop Window Manager` |
| **General** tab → description text | Contains `The Desktop Window Manager process has exited` |
| **Date and Time** column | Within seconds **after** a matching Event 1000 from D3 |

> **Confirmed if:** At least one Event 9009 entry matches all three field checks, appearing seconds after an Event 1000 entry from D3.  
> **Both D3 and D4 confirmed together** = root cause established. Proceed to D5 before starting remediation.

**PowerShell fast-check (run on the affected host in the same elevated prompt):**

```powershell
# Query the Application log for Event 9009 from Desktop Window Manager
Get-WinEvent -FilterHashtable @{
    LogName      = 'Application'
    Id           = 9009
    ProviderName = 'Desktop Window Manager'
    StartTime    = (Get-Date).Date
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Message |
    Format-List
```

> **Expected output (confirmed):** One or more results with `Message` containing `The Desktop Window Manager process has exited`, timestamped within seconds after the Event 1000 entries found in D3.  
> **Expected output (not confirmed):** No output — DWM exit events are absent; re-examine D3 results and verify the host is in scope.

---

### Step D5 — Pool comparison: POOL-FIN-01 vs POOL-FIN-02 (mandatory)

This step is **required** — it eliminates infrastructure-wide AVD faults and proves the failure is image-specific before you begin any remediation.

**Connect to a POOL-FIN-02 host** (e.g. `SHFIN-02-A`) via Azure Bastion:  
Portal path: **portal.azure.com → Virtual machines → SHFIN-02-A → Connect (left nav) → Bastion** → enter admin credentials → **Connect**.

**Check 1 — DWM healthy start present on POOL-FIN-02:**  
Event Viewer → **Windows Logs → Application** → **Filter Current Log...** → **\<All Event IDs\>** → `9011` → **OK**.  
Required: at least one Event 9011 entry, **Source** = `Desktop Window Manager`, **General** tab description = `The Desktop Window Manager has started successfully`, timestamped during the incident window.

**Check 2 — DWM crash absent on POOL-FIN-02:**  
Clear filter → **Filter Current Log...** → **\<All Event IDs\>** → `1000` → **OK**.  
Required: **zero** entries where `Faulting application name` = `dwm.exe` AND `Faulting module name` = `igdumd64.dll` during the incident window.

**PowerShell fast-check for both checks (run on SHFIN-02-A in an elevated prompt):**

```powershell
# Check 1: Event 9011 should be present — DWM started cleanly
Write-Host '--- Check 1: Event 9011 (DWM healthy start) on POOL-FIN-02 ---'
Get-WinEvent -FilterHashtable @{
    LogName      = 'Application'
    Id           = 9011
    ProviderName = 'Desktop Window Manager'
    StartTime    = (Get-Date).Date
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Message | Format-List

# Check 2: Event 1000 for dwm.exe/igdumd64.dll should be absent
Write-Host '--- Check 2: Event 1000 (DWM crash) on POOL-FIN-02 — expect NO output ---'
Get-WinEvent -FilterHashtable @{
    LogName   = 'Application'
    Id        = 1000
    StartTime = (Get-Date).Date
} -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -like '*dwm.exe*' -and $_.Message -like '*igdumd64*' } |
    Select-Object TimeCreated, Message | Format-List
```

> **Check 1 expected output (pass):** At least one result with `Message` containing `Desktop Window Manager has started successfully`.  
> **Check 1 expected output (fail):** No output — DWM is not starting cleanly even on POOL-FIN-02; escalate to AVD platform team, do not proceed with pool-specific remediation.  
> **Check 2 expected output (pass):** No output — zero DWM crashes on POOL-FIN-02.  
> **Check 2 expected output (fail):** Any output — both pools are crashing; this is not an image-regression pattern; escalate immediately.

| Signal | POOL-FIN-01 (affected) | POOL-FIN-02 (healthy) | Interpretation |
|---|---|---|---|
| Event 9011 present | No | Yes | DWM starts cleanly only on old image |
| Event 1000 `dwm.exe`/`igdumd64.dll` present | Yes | No | Crash is image-specific, not platform-wide |
| Event 9009 present | Yes | No | Fatal compositor failure only on updated image |

> **Comparison passes** (proceed to Resolution) if POOL-FIN-02 shows Event 9011 and zero matching Event 1000 entries in the same window.  
> **Comparison fails** (stop — escalate) if POOL-FIN-02 also shows Event 1000 `dwm.exe` crashes — this is no longer an image-regression pattern; escalate to AVD platform team immediately.

---

## 5. Resolution

> **Before starting:** Drain mode must be enabled on all affected POOL-FIN-01 hosts before any remediation is attempted. If you haven't done this, do Step R-Contain first.

### CLI Prerequisites — set once before running any CLI commands in this section

Requires Azure CLI with the `desktopvirtualization` extension. Run from any terminal.

```bash
# Authenticate and target the correct subscription
az login
az account set --subscription "<your-subscription-id>"

# Set variables once — every CLI block below references these
RG="rg-finance-avd"      # Resource group containing both pools
POOL="POOL-FIN-01"       # Affected host pool
GOOD_POOL="POOL-FIN-02"  # Healthy reference pool
```

---

### Step R-Contain — Enable drain mode on all affected hosts

**Portal path:** `portal.azure.com` → search `Azure Virtual Desktop` → **Azure Virtual Desktop** → **Host pools** (left nav) → **POOL-FIN-01** → **Manage** (left nav section) → **Session hosts**

For each affected host:
1. Tick the checkbox next to the host name
2. Toolbar → **Turn drain mode on**
3. Confirmation panel → **Turn on**

> **Expected:** Drain mode column shows **On** for all affected hosts. Status remains **Available** — existing sessions are preserved. No new sessions will be routed to these hosts.

**CLI fast-path (drains every host in one pass — faster than ticking each row):**

```bash
# Enable drain mode on all hosts in POOL-FIN-01
for HOST in $(az desktopvirtualization sessionhost list \
      --resource-group "$RG" --host-pool-name "$POOL" \
      --query "[].name" -o tsv); do
  az desktopvirtualization sessionhost update \
    --resource-group "$RG" --host-pool-name "$POOL" \
    --name "$HOST" --allow-new-session false
  echo "Drain ON: $HOST"
done

# Confirm — AllowNewSession must read 'false' for every row
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[].{Host:name, Status:status, DrainMode:allowNewSession}" -o table
```

> **Expected CLI output:** `DrainMode` column reads `false` for every host in POOL-FIN-01.

Notify the Service Desk: *"POOL-FIN-01 hosts are in drain mode. Direct Finance users reporting a black screen to fully close their Remote Desktop client, wait 30 seconds, and reconnect — they will land on a healthy host."*

---

> **Decision point:** Choose **Option A** (image rollback) if the previous known-good image version is available in Azure Compute Gallery. This is the preferred fix. Choose **Option B** (in-place registry workaround) only if the previous image is not available. Confirm your choice with your team lead.

---

### Option A — Roll back the host pool image (preferred)

**Step A1.** **Portal path:** `portal.azure.com` → search `Azure Virtual Desktop` → **Azure Virtual Desktop** → **Host pools** (left nav) → **POOL-FIN-01** → **Settings** (left nav section) → **Session host configuration**

Note the current image reference shown in the **Image** field (e.g. `CorpImageGallery / FinanceDesktop / 2024.03.15.0`). Record this version before making changes.

> **Expected:** Image field shows the version applied during the 02:00 update.

**CLI fast-path (read current image reference without opening the portal):**

```bash
# Save the current vmTemplate JSON — this is your rollback reference if A2 needs to be reverted
CURRENT_TEMPLATE=$(az desktopvirtualization hostpool show \
  --resource-group "$RG" --name "$POOL" \
  --query "vmTemplate" -o tsv)
echo "Current vmTemplate: $CURRENT_TEMPLATE"
# Copy this output to your incident notes before continuing
```

> **Expected CLI output:** A JSON string containing the gallery image reference, including the version number that was applied at 02:00 (e.g. `"exactVersion":"2024.03.15.0"`).

**Step A2.** **Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Settings** (left nav) → **Session host configuration** → click the **Edit (pencil)** icon next to the **Image** field:
1. Select **Azure Compute Gallery**
2. Select your gallery (e.g. `CorpImageGallery`)
3. Select the image definition (e.g. `FinanceDesktop`)
4. In the **Version** dropdown, select the version in use **before** the 02:00 update — cross-reference with the change record in your change management system
5. Click **Save**

> **Expected:** Green banner — *"Session host configuration updated successfully"*. The Image field reflects the prior version. This change governs future host provisioning only — existing hosts must be re-imaged in A3.

**CLI fast-path (update the host pool image reference without opening the portal):**

```bash
# Replace <KNOWN-GOOD-VERSION> with the version from the change record, e.g. 2024.03.14.0
GOOD_VERSION="<KNOWN-GOOD-VERSION>"

# Patch only the exactVersion field inside the existing vmTemplate JSON
UPDATED_TEMPLATE=$(az desktopvirtualization hostpool show \
  --resource-group "$RG" --name "$POOL" \
  --query "vmTemplate" -o tsv | \
  python3 -c "import json,sys; t=json.load(sys.stdin); \
    t['galleryImageReference']['exactVersion']='$GOOD_VERSION'; \
    print(json.dumps(t))")

az desktopvirtualization hostpool update \
  --resource-group "$RG" --name "$POOL" \
  --vm-template "$UPDATED_TEMPLATE"

# Confirm the version was written
az desktopvirtualization hostpool show \
  --resource-group "$RG" --name "$POOL" \
  --query "vmTemplate" -o tsv
```

> **Expected CLI output:** The `vmTemplate` JSON now contains `"exactVersion":"<KNOWN-GOOD-VERSION>"`. If the version string does not match, re-run the update command before proceeding.

**Step A3.** Re-image affected hosts one at a time (do not re-image all simultaneously — stagger to preserve capacity):

**Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Manage** (left nav section) → **Session hosts**
1. Tick the checkbox next to the first affected host
2. Toolbar → **Re-image**
3. Confirm dialog shows the known-good version from A2 — verify this before clicking through
4. Click **Re-image**
5. Host Status changes: **Available → Unavailable → Upgrading → Available**
6. Wait until Status returns to **Available** before starting the next host

> **Expected:** Each host returns to **Available** with the OS version column reflecting the known-good build. No host left in **Upgrading** or **Unavailable** state.

**CLI fast-path (re-image and monitor — stagger manually, do not loop):**

```bash
# Re-image one host at a time — replace SHFIN-01-A with the host you are targeting
TARGET_HOST="SHFIN-01-A"

az vm reimage \
  --resource-group "$RG" \
  --name "$TARGET_HOST"

# Poll status every 30 seconds until it returns 'Available'
watch -n 30 "az desktopvirtualization sessionhost show \
  --resource-group '$RG' --host-pool-name '$POOL' \
  --name '$TARGET_HOST' \
  --query '{Status:status, OSVersion:osVersion}' -o table"
# On Windows (no watch): run the show command manually every 30 seconds
az desktopvirtualization sessionhost show \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --name "$TARGET_HOST" \
  --query "{Status:status, OSVersion:osVersion, DrainMode:allowNewSession}" -o table
```

> **Expected CLI output:** `Status` field reads `Available` and `OSVersion` reflects the known-good build number. Move to the next host only when this is confirmed.

**Step A4.** Turn drain mode off on each remediated host:

**Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Manage** (left nav section) → **Session hosts** → tick checkbox next to host → Toolbar → **Turn drain mode off** → **Turn off** in confirmation panel. Repeat for each host.

> **Expected:** Drain mode column shows **Off**, Status shows **Available** for all remediated hosts.

**CLI fast-path:**

```bash
# Disable drain mode on a single host
az desktopvirtualization sessionhost update \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --name "SHFIN-01-A" --allow-new-session true

# After all hosts are done, confirm the full pool is clean
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[].{Host:name, Status:status, DrainMode:allowNewSession, Sessions:sessions}" \
  -o table
```

> **Expected CLI output:** `DrainMode` reads `true` (allow new sessions) and `Status` reads `Available` for every host.

---

### Option B — In-place registry mitigation (temporary workaround only)

> This disables hardware graphics acceleration for the session render path. It removes the condition that triggers the `igdumd64.dll` crash but does not fix the underlying image defect. Raise a change request to apply a corrected image at the next maintenance window before closing the incident.

**Step B1.** On the affected session host (Bastion/RDP session from Detection Step D2), right-click **Start** → **Windows PowerShell (Admin)** → **Yes** at UAC prompt.

**Step B2.** Paste and run:

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "bEnumerateHWBeforeSW" -Value 0 -Type DWord -Force
```

Confirm the write:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "bEnumerateHWBeforeSW"
```

> **Expected:** Second command outputs `bEnumerateHWBeforeSW : 0`. If the output shows a different value or a path error, re-run Set-ItemProperty and verify again before continuing.

**Step B3.** Restart the host:

```powershell
Restart-Computer -Force
```

> **Expected:** Bastion session disconnects immediately. In the Portal (**POOL-FIN-01 → Session hosts**), watch Status cycle through **Unavailable → Available** (typically 3–5 minutes). Do not proceed until Status reads **Available**.

**Step B4.** Turn drain mode off — same as Step A4 above.

Repeat Steps B1–B4 for each remaining affected host.

---

## 6. Verification

Complete all steps below in order. Do not mark the incident Resolved until all pass.

**Step V1 — Test logon with a non-production account**

Open the Remote Desktop client or navigate to `aka.ms/wvdweb`. Sign in with a test account that has Finance Desktop workspace access but is not an active Finance user. Launch **Finance Desktop**.

> **Pass:** Windows desktop loads within 30 seconds, taskbar is visible, session remains stable for at least 2 minutes — no black screen, no flash, no disconnect prompt.  
> **Fail:** Session goes black or disconnects → re-enable drain mode on all POOL-FIN-01 hosts immediately → proceed to Section 7 (Rollback).

**Step V2 — Identify the session host served**

In the Remote Desktop client: click the connection bar at the top of the session → signal icon → note the **Session host** field.  
In the AVD web client: click the signal-strength icon in the floating toolbar → note the **Session host** field.

> **Expected:** A host name is returned (e.g. `SHFIN-01-A`). Record this for V3/V4.

**Step V3 — Verify DWM starts cleanly on the verified host**

Bastion/RDP to the host identified in V2. Event Viewer → **Windows Logs → Application** → Filter for Event ID `9011`.

> **Pass:** At least one Event 9011 entry exists with Source = `Desktop Window Manager`, description = `The Desktop Window Manager has started successfully`, timestamped after Phase C/Option A/B remediation.  
> No Event 9009 entry exists with a timestamp after remediation.  
> **Fail:** 9009 appears after remediation timestamp → put this host back into drain mode → escalate to desktop engineering.

**Step V4 — Confirm zero post-remediation DWM crash events**

Still in the same Event Viewer session. Clear filter → apply new filter for Event ID `1000`.  
For each result, check the General tab for entries matching all three of:

- `Faulting application name: dwm.exe`
- `Faulting module name: igdumd64.dll`
- `Exception code: 0xc0000005`

> **Pass:** Zero matching entries exist with a timestamp **after** remediation completed. Pre-remediation entries with this signature are expected and do not constitute a failure.  
> **Fail:** Any post-remediation matching entry → drain mode On for this host → escalate.

**Step V5 — Affected user validation**

Contact the Service Desk. Ask two previously-affected Finance users to log in and report back directly.

> **Pass:** Both users confirm desktop loaded normally. Service Desk confirms no new black-screen calls in the last 10 minutes.  
> **Fail:** Either user reports a black screen → re-enable drain mode on all POOL-FIN-01 hosts → proceed to Rollback.

**Step V6 — Portal health check**

**Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Manage** (left nav section) → **Session hosts**

> **Pass:** Every host shows **Status: Available** and **Drain mode: Off**. No host in **Unavailable**, **Upgrading**, or **Needs assistance** state. Session count is incrementing across hosts.  
> Only when V1–V6 all pass is it safe to update the incident ticket to **Resolved**.

**CLI fast-path (full pool health snapshot in one command):**

```bash
# Full status snapshot for POOL-FIN-01
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[].{Host:name, Status:status, DrainMode:allowNewSession, \
              Sessions:sessions, OSVersion:osVersion}" \
  -o table

# Quick check: count any hosts NOT in Available state (should return 0)
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[?status != 'Available'].{Host:name, Status:status}" -o table
```

> **Expected CLI output — pass:** Every row shows `Status: Available`, `DrainMode: true` (allow new sessions). The second command returns no rows. If any host shows `Unavailable`, `Upgrading`, or `NeedsAssistance` — do not close the incident; investigate that host before proceeding.

---

## 7. Rollback

> **Trigger:** Use this section immediately if: users still report black screen after drain mode was turned off, new Event 1000/9009 entries appear after remediation, or any host fails to return to **Available** status.  
> All steps below must be completed within 3 minutes. Follow in order.

### R1 — Stop all user traffic to POOL-FIN-01 (~45 seconds)

**Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Manage** (left nav section) → **Session hosts** → tick the **checkbox in the table header row** to select all hosts → Toolbar → **Turn drain mode on** → **Turn on**

> **Expected:** Every host shows **Drain mode: On**. No new sessions will route to POOL-FIN-01.

**CLI fast-path (faster than the portal during an active incident):**

```bash
# Drain all POOL-FIN-01 hosts in one loop
for HOST in $(az desktopvirtualization sessionhost list \
      --resource-group "$RG" --host-pool-name "$POOL" \
      --query "[].name" -o tsv); do
  az desktopvirtualization sessionhost update \
    --resource-group "$RG" --host-pool-name "$POOL" \
    --name "$HOST" --allow-new-session false
  echo "Drain ON: $HOST"
done

# Verify — all hosts must show DrainMode: false
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[].{Host:name, DrainMode:allowNewSession}" -o table
```

> **Expected CLI output:** `DrainMode` column shows `false` for every host. Do not wait — move to R2 immediately after confirming.

### R2 — Redirect Finance users to POOL-FIN-02 (~30 seconds)

Call/message Service Desk immediately:

> *"Stop sending users to POOL-FIN-01. Tell all Finance users to fully close their Remote Desktop client, wait 10 seconds, reopen it, and connect to POOL-FIN-02 instead. Do not reconnect to POOL-FIN-01 until further notice."*

### R3 — Revert the image reference (Option A only)

*Skip if you used Option B — go to R4.*

**Portal path:** `portal.azure.com` → **Azure Virtual Desktop** → **Host pools** → **POOL-FIN-01** → **Settings** (left nav section) → **Session host configuration** → click **Edit (pencil)** next to **Image** field → **Azure Compute Gallery** → select gallery → select image definition → select the **Version** that was in place **before your Step A2 change** (the version you recorded at Step A1) → **Save**

> **Expected:** Green success banner. Image field shows the pre-A2 version.

**CLI fast-path (restore the vmTemplate JSON you saved at Step A1):**

```bash
# Paste the vmTemplate JSON string you captured at Step A1 into ORIGINAL_TEMPLATE
ORIGINAL_TEMPLATE='<paste the JSON string saved at Step A1 here>'

az desktopvirtualization hostpool update \
  --resource-group "$RG" --name "$POOL" \
  --vm-template "$ORIGINAL_TEMPLATE"

# Confirm the version reverted
az desktopvirtualization hostpool show \
  --resource-group "$RG" --name "$POOL" \
  --query "vmTemplate" -o tsv
```

> **Expected CLI output:** `vmTemplate` JSON shows the version string from before Step A2. If the version does not match the A1 snapshot, re-run the update command with the correct JSON before proceeding.

### R4 — Revert the registry key (Option B only)

*Skip if you used Option A — go to R5.*

For each host where you applied the B2 registry change:

Bastion/RDP to the host → PowerShell (Admin):

```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "bEnumerateHWBeforeSW" -Force
Restart-Computer -Force
```

> **Expected:** Bastion session disconnects. In Portal, watch Status return to **Available** (3–5 minutes) before moving to the next host. Do not turn drain mode Off on any host until Verification steps V3 and V4 pass.

### R5 — Escalate if not stable within 15 minutes

If POOL-FIN-01 remains unstable or POOL-FIN-02 cannot absorb redirected users, open a P1 bridge call with:

- **Desktop engineering team** — image and DWM fix ownership
- **AVD platform team** — host pool capacity and routing

Bridge message: *"POOL-FIN-01 is fully drained following a failed remediation of a DWM / igdumd64.dll crash. All Finance users are on POOL-FIN-02. Referencing runbook `avd-black-screen-dwm-runbook.md` and RCA `avd-black-screen-incident-rca-2024-03-15.md`."*

---

## 8. Prevention

The 5 Whys in the RCA (`avd-black-screen-incident-rca-2024-03-15.md`) traced the root cause chain to two missing controls in the image release pipeline. Each control below lists: owner role, timing in the release process, pass/fail criteria, what happens on failure, and whether the control is automated or manual.

---

### 8.1 — Mandatory post-logon validation gate in the image release pipeline

**Owner:** Release Engineer (image pipeline team)  
**Timing:** Before deployment — fires between Ring 0 build completion and Ring 1 promotion  
**Mode:** Automated  
**Pass signal:** Zero Event 1000 (`dwm.exe` + `igdumd64.dll`) and zero Event 9009 in the 60-second post-logon window on the canary host  
**Fail signal:** Any matching Event 1000 or Event 9009 in that window — pipeline exits with code 1  
**If it fails:** Azure DevOps marks the stage red and emails the release engineer; the image version is blocked from Ring 1 automatically; the release engineer opens a defect ticket against the image build team and does not manually override without a time-bound change record (max 4-hour exemption) signed off by the desktop engineering lead  
`[REQUIRES: Azure DevOps pipeline with AzurePowerShell task; canary AVD host pool; test account with Finance Desktop access; WinRM or Bastion connectivity from pipeline agent to canary host]`

**Tool:** Azure DevOps pipeline (or equivalent CI/CD) + PowerShell validation script

Add the following stage to the image promotion pipeline YAML **between** the "Build image" stage and the "Promote to Ring 1" stage:

```yaml
# Image promotion pipeline — insert between Build and Ring1Promote stages
- stage: ValidatePostLogon
  displayName: 'Post-logon DWM validation gate'
  dependsOn: BuildImage
  jobs:
  - job: DWMCrashCheck
    timeoutInMinutes: 20
    steps:
    - task: AzurePowerShell@5
      displayName: 'Provision canary host and validate DWM'
      inputs:
        azureSubscription: '$(serviceConnection)'
        ScriptType: 'InlineScript'
        Inline: |
          # Provision a single canary host from candidate image
          # (host provisioning steps omitted — use your existing New-AzWvdSessionHost wrapper)

          # Wait for host to reach Available
          $timeout = (Get-Date).AddMinutes(10)
          do { Start-Sleep -Seconds 30
               $status = (Get-AzWvdSessionHost -ResourceGroupName $env:RG `
                           -HostPoolName $env:CANARY_POOL `
                           -Name $env:CANARY_HOST).Status
          } while ($status -ne 'Available' -and (Get-Date) -lt $timeout)
          if ($status -ne 'Available') { throw 'Canary host did not reach Available in 10 min' }

          # Trigger a scripted test logon (use your existing test account)
          # ... logon automation omitted ...
          Start-Sleep -Seconds 60   # allow DWM init cycle to complete

          # Query Application event log on the canary host via Invoke-Command / Bastion
          $crashes = Invoke-Command -ComputerName $env:CANARY_HOST -ScriptBlock {
            Get-WinEvent -FilterHashtable @{
              LogName   = 'Application'
              Id        = 1000
              StartTime = (Get-Date).AddMinutes(-5)
            } -ErrorAction SilentlyContinue |
            Where-Object {
              $_.Properties[0].Value -eq 'dwm.exe' -and
              $_.Properties[2].Value -like '*igdumd64*'
            }
          }
          $exits = Invoke-Command -ComputerName $env:CANARY_HOST -ScriptBlock {
            Get-WinEvent -FilterHashtable @{
              LogName   = 'Application'
              Id        = 9009
              StartTime = (Get-Date).AddMinutes(-5)
            } -ErrorAction SilentlyContinue
          }
          if ($crashes -or $exits) {
            Write-Error "GATE FAILED: DWM crash (Event 1000) or exit (Event 9009) detected on canary host. Blocking promotion."
            exit 1
          }
          Write-Host "GATE PASSED: No DWM crash events in post-logon window."
```

**Bypass rule:** No pipeline variable or manual approval may skip this stage. A bypass requires a time-bound change record (maximum 4-hour exemption window) with desktop engineering lead sign-off recorded in the change management system.

---

### 8.2 — Three-ring rollout policy for all AVD host pool images

**Owner:** AVD Platform team (ring sequencing); Release Engineer (ring sign-off)  
**Timing:** During deployment — gates each ring transition  
**Mode:** Ring 0 halt = automated (pipeline gate 8.1); Ring 1 and Ring 2 halts = manual trigger by on-call DWP engineer responding to Alert 1/2/3 (8.3)  
**Pass signal per ring:** Zero Alert 1/2/3 firings during the soak period AND the named sign-off role has updated the change ticket with "Ring N pass"  
**Fail signal:** Any Alert 1, 2, or 3 fires during the soak window  
**If it fails:** On-call DWP engineer sets drain mode On for all remaining un-re-imaged hosts (CLI: `for HOST in ...` loop from Section 5 R-Contain), updates the change ticket to "Halt — DWM crash during Ring N soak", and escalates to desktop engineering lead before any further hosts are re-imaged  
**Automation note (manual → automated):** Integrate Alert 3 (8.3) with an Azure Logic App that auto-calls the drain-mode REST API and posts an alert to the incident channel when triggered during a change window `[REQUIRES: Azure Logic App; AVD REST API service principal with Desktop Virtualization Contributor role]`  
`[REQUIRES: Azure Compute Gallery with versioned image definitions; AVD host pool re-image capability; Ring 1 canary host designated in each pool before rollout begins]`

**Tool:** Azure Compute Gallery image versions + host pool re-image sequencing

| Ring | Scope | Soak period | Halt condition | Proceed criteria | Sign-off role |
|---|---|---|---|---|---|
| Ring 0 | Lab hosts only (no production users) | 30 min post-logon window | Any Event 1000 `dwm.exe` or Event 9009 | Gate script exits 0; zero events in window | Pipeline gate (8.1) — automated |
| Ring 1 | ≤10% of hosts per pool (1–2 hosts in POOL-FIN-01) | 4-hour business-hours soak with live users | ≥1 Event 1000 `dwm.exe` or ≥1 Event 9009 in soak window | Zero alerts for full 4 hours AND desktop engineering lead signs off in the change ticket | Desktop engineering lead |
| Ring 2 | Remaining hosts, one at a time | Per-host: monitor for 30 min after each re-image | Any Event 1000 `dwm.exe` post-re-image | All hosts Available; V6 CLI health check passes; change manager closes the change | DWP engineer (per host) + change manager (final close) |

**Automatic halt implementation for Ring 1:** Configure the following Azure Monitor alert rule to fire on Ring 1 canary hosts during the soak window. If it fires, the on-call engineer must halt the rollout and set drain mode On on all remaining un-re-imaged hosts before investigating.

---

### 8.3 — Log Analytics alert rules (implement before next image cycle)

**Owner:** Monitoring Engineer / AVD Platform team  
**Timing:** In-flight monitoring — active continuously; critical during any change window involving AVD images  
**Mode:** Automated detection; manual response  
`[REQUIRES: Log Analytics workspace with AVD session host Windows Event data collection enabled (Event log: Application, System). If not yet configured: portal.azure.com → Log Analytics workspace → Settings → Agents → Windows event logs → add Application and System logs]`

**Pass signal:** No alerts fire during the deployment window  
**Fail signal:** Alert fires  
**If it fails:** On-call DWP engineer receives page; within 5 minutes they must: (1) confirm the alert by running the D3 fast-check PowerShell from Section 4, (2) set drain mode On for affected hosts using the R-Contain CLI block from Section 5, (3) update the change ticket to "Halt — DWM alert fired during change window", (4) escalate to desktop engineering lead  

**Tool:** Azure Monitor → Log Analytics workspace connected to AVD session host diagnostics

Create the following three alert rules. Navigate to: **portal.azure.com → Monitor → Alerts → + Create → Alert rule** — set the scope to your Log Analytics workspace.

**Alert 1 — DWM crash spike (P2)**

```kql
// Query: Application event log — DWM crash in igdumd64.dll
Event
| where TimeGenerated > ago(5m)
| where EventLog == "Application"
| where EventID == 1000
| where RenderedDescription has "dwm.exe" and RenderedDescription has "igdumd64.dll"
| summarize CrashCount = count() by Computer, HostPool = tostring(split(Computer, "-")[0])
| where CrashCount >= 3
```

- **Threshold:** ≥ 3 occurrences in a 5-minute window on any host in the same pool  
- **Severity:** 2 (Warning)  
- **Action group:** Page the AVD on-call engineer  
- **On-alert action:** Run D3 fast-check PowerShell on the alerting host; if confirmed, execute R-Contain CLI and update change ticket

**Alert 2 — DWM exit spike (P2)**

```kql
// Query: Application event log — DWM process exited
Event
| where TimeGenerated > ago(5m)
| where EventLog == "Application"
| where EventID == 9009
| where Source == "Desktop Window Manager"
| summarize ExitCount = count() by Computer
| where ExitCount >= 3
```

- **Threshold:** ≥ 3 occurrences in a 5-minute window on any single host  
- **Severity:** 2 (Warning)  
- **Action group:** Page the AVD on-call engineer  
- **On-alert action:** Run D4 fast-check PowerShell on the alerting host; correlate with D3 results; if both fire on the same host, treat as confirmed DWM crash and execute R-Contain CLI

**Alert 3 — DWM crash within 2 hours of re-image (P1)**

```kql
// Query: Any DWM crash on a host within 2 hours of its last re-image boot
// Requires Kernel-General Event 1 (boot) joined to App Error Event 1000
let RecentBoots = Event
  | where TimeGenerated > ago(2h)
  | where EventLog == "System"
  | where EventID == 1
  | where Source == "Microsoft-Windows-Kernel-General"
  | project Computer, BootTime = TimeGenerated;
Event
| where TimeGenerated > ago(2h)
| where EventLog == "Application"
| where EventID == 1000
| where RenderedDescription has "dwm.exe" and RenderedDescription has "igdumd64.dll"
| join kind=inner RecentBoots on Computer
| where TimeGenerated > BootTime
| project Computer, CrashTime = TimeGenerated, BootTime
```

- **Threshold:** Any single result  
- **Severity:** 1 (Critical) — treat as active incident immediately  
- **Action group:** Page the AVD on-call engineer AND the desktop engineering lead  
- **On-alert action:** Immediately halt remaining Ring 2 re-images (drain mode On via CLI); do not close the change record; open a P1 incident; follow Section 7 Rollback from R1

---

### 8.4 — Driver version delta mandatory in change records

**Owner:** Change Manager (field enforcement); Image Owner (field population)  
**Timing:** Before deployment — change record must have this field approved before Ring 1 proceeds  
**Mode:** Manual — automation approach: add a workflow validation rule to the ITSM change template that marks the change "Pending approval" if the graphics driver delta field is blank `[REQUIRES: ITSM workflow engine with custom field validation (e.g. ServiceNow business rule)]`  
**Pass signal:** The `igdumd64.dll` version delta field is populated and the desktop engineering lead approval field shows a name and date  
**Fail signal:** Field is blank or unsigned when the AVD Platform team checks before triggering Ring 1  
**If it fails:** AVD Platform team must not proceed to Ring 1; they set the change ticket to "On hold — missing driver delta approval" and notify the image owner and change manager; Ring 1 does not start until the field is complete and re-approved

The change record template for AVD image updates must be updated to include a mandatory field:

```
Graphics driver delta (mandatory — leave blank only if no driver files were modified):
  Component:     igdumd64.dll (Intel graphics render module)
  Previous ver:  [e.g. 27.20.100.8681]
  New ver:       [e.g. 27.20.100.9030]
  Tested on:     [Lab host name and Ring 0 test date]
  Approved by:   [Desktop engineering lead name and date]
```

If the `igdumd64.dll` version changes between image versions, the change record **must not move to Ring 1** without the desktop engineering lead's explicit approval field populated. The AVD Platform team is responsible for verifying this field is complete before triggering the Ring 1 re-image sequence.

---

### 8.5 — Post-deployment validation gate before change closure *(new — gap identified in this incident)*

**Owner:** DWP Engineer who performed the deployment  
**Timing:** After deployment — before the change record is moved to "Closed"  
**Mode:** Manual (CLI commands already available in Section 6 Verification); automation approach: auto-trigger a post-deployment check job 30 minutes after the last Ring 2 re-image completes `[REQUIRES: Azure DevOps or Logic App scheduled trigger tied to re-image completion event]`  
**Pass signal:** (1) All POOL-FIN-01 hosts return `Status: Available` and `DrainMode: true` in the V6 CLI check; (2) Zero Event 1000/9009 entries on any POOL-FIN-01 host in the 30 minutes since Ring 2 completed; (3) Service Desk reports zero new black-screen calls for 30 minutes after final host is released  
**Fail signal:** Any of the three pass signals above is not met  
**If it fails:** Re-open the incident; set drain mode On for all POOL-FIN-01 hosts; escalate to desktop engineering lead; do not close the change record

```bash
# Post-deployment validation — run after all Ring 2 hosts are released
# Pass requires: zero rows returned from both queries

# 1. Any POOL-FIN-01 host not Available?
az desktopvirtualization sessionhost list \
  --resource-group "$RG" --host-pool-name "$POOL" \
  --query "[?status != 'Available'].{Host:name, Status:status}" -o table

# 2. Any DWM crash in the last 30 minutes on any POOL-FIN-01 host?
# (Run on each host via Invoke-Command or check Log Analytics Alert 3 history)
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'; Id = 1000
    StartTime = (Get-Date).AddMinutes(-30)
} -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -like '*dwm.exe*' -and $_.Message -like '*igdumd64*' }
```

---

### 8.6 — Knowledge update after each image-related incident *(new — gap identified in this incident)*

**Owner:** DWP Engineer who resolved the incident  
**Timing:** After deployment — within 48 hours of incident closure  
**Mode:** Manual — automation approach: auto-create a KB review ticket in the ITSM system whenever an incident is linked to this known error record `[REQUIRES: ITSM workflow rule on known error record closure]`  
**Pass signal:** This KB article (`avd-black-screen-l2l3-kb.md`) and the runbook (`avd-black-screen-dwm-runbook.md`) have been reviewed; any new DWM crash patterns, new Event IDs, or new affected modules are added to the Detection section; the KB review ticket is closed by the DWP engineer and countersigned by the desktop engineering lead  
**Fail signal:** KB review ticket remains open after 48 hours  
**If it fails:** Team lead escalates at the next weekly operations review; the knowledge gap is recorded as an open risk item until the review is completed

---

### Prevention controls summary

| Control | Type | Timing | Owner | Gap covered |
|---|---|---|---|---|
| 8.1 Pipeline gate | Automated | Before Ring 1 | Release Engineer | Pre-deployment smoke test |
| 8.2 Ring rollout | Manual (halt) / Automated (detect) | During deployment | AVD Platform team | Staged rollout + in-flight halt |
| 8.3 Log Analytics alerts | Automated detect / Manual respond | In-flight (continuous) | Monitoring Engineer | In-flight monitoring |
| 8.4 Driver delta field | Manual | Before Ring 1 | Change Manager + Image Owner | Change control gap |
| 8.5 Post-deployment gate | Manual (CLI) | After Ring 2 | DWP Engineer | Post-deployment validation |
| 8.6 Knowledge update | Manual | After closure | DWP Engineer | Runbook/KB currency |

| Document | Relationship |
|---|---|
| `avd-black-screen-incident-rca-2024-03-15.md` | Source RCA for this KB article — full 5 Whys, timeline, and evidence |
| `avd-black-screen-dwm-runbook.md` | Operational runbook — step-by-step procedure with portal paths and PowerShell commands |
| `avd-black-screen-ranked-hypotheses.md` | Triage hypothesis ranking used during the incident — use this if Detection steps D3/D4 do not confirm the DWM pattern |
| `known-error-avd-black-screen-pool-fin-01.md` | Known error record — symptom, cause, workaround, and permanent fix summary |
| `avd-incident-closure-note.md` | Incident closure summary and timeline |
| `avd-black-screen-user-kb.md` | L1 self-service KB article for end users — safe steps (log off, wait, reconnect) |
| Change record for 02:00 image update on 2024-03-15 | Verify the exact CR number in your change management system — required for rollback version reference |
