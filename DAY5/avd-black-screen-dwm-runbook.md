# Runbook: AVD Black Screen Post-Login (DWM / igdumd64.dll Crash)

| Field | Detail |
|---|---|
| **Title** | AVD Black Screen Post-Login (DWM / igdumd64.dll Crash) |
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Author** | vamsikrishna |
| **Reviewed by** | self |
| **Status** | Draft |
| **Change** | Initial version from RCA |

---

**Service:** Azure Virtual Desktop  
**Affected component:** Desktop Window Manager (dwm.exe) — Intel graphics module igdumd64.dll  
**Trigger:** Post-image-update black screen on login; users disconnect/reconnect loop  
**Related RCA:** `avd-black-screen-incident-rca-2024-03-15.md`  
**Related known error:** `known-error-avd-black-screen-pool-fin-01.md`

---

## 1. Prerequisites

### Access rights required
| Requirement | Detail |
|---|---|
| Azure RBAC | Desktop Virtualization Contributor on the affected host pool resource group — **elevated** |
| Azure Portal or Az PowerShell | Logged in as an account with the above RBAC role |
| RDP / Bastion access to session hosts | Required for event log review; local admin on session hosts — **elevated** |
| AVD host pool drain mode permission | Included in Desktop Virtualization Contributor |

### Tools required
- Azure Portal **or** PowerShell with `Az.DesktopVirtualization` module installed (`Install-Module Az.DesktopVirtualization`)
- Remote Desktop client (to test a login after remediation)
- Event Viewer (on the session hosts) or Log Analytics workspace if configured

### Information to gather before starting
- Name of the affected host pool (e.g. `POOL-FIN-01`) and its resource group
- Name of the unaffected control pool (e.g. `POOL-FIN-02`) — used as reference
- Current image version applied to affected pool (check Azure Compute Gallery or the host pool image reference in the portal)
- Previous known-good image version or snapshot name
- List of session hosts in the affected pool (obtain from portal: Host pool → Session hosts)
- Change record number for the overnight image update that preceded the incident

---

## 2. Procedure

### Phase A — Contain (stop new users landing on broken hosts)

**Step 1.** Open a browser and go to **[portal.azure.com](https://portal.azure.com)**. In the top search bar type `Azure Virtual Desktop` and press Enter. Under the **Services** heading in the results, click **Azure Virtual Desktop**.

> Expected result: The Azure Virtual Desktop overview page loads. The left navigation pane shows items including **Host pools**, **Application groups**, and **Workspaces**.

**Step 2.** In the left navigation pane click **Host pools**. In the list that loads, click the row for **POOL-FIN-01**.

> Expected result: The POOL-FIN-01 host pool blade opens. The breadcrumb at the top reads: `Home > Azure Virtual Desktop > Host pools > POOL-FIN-01`.

**Step 3.** In the POOL-FIN-01 left navigation pane, under the **Manage** heading, click **Session hosts**.

> Expected result: A table loads listing every session host in the pool (e.g. `SHFIN-01-A`, `SHFIN-01-B`). Columns visible include **Name**, **Status**, **Session count**, **Drain mode**, and **OS version**.

**Step 4.** For each host in the table, read the **OS version** column. Hosts on the updated image will show a newer build number. Write down the name of every host showing the new build — these are your affected hosts. If all hosts show the same build, list all of them.

> Expected result: You have a written list of affected host names (e.g. `SHFIN-01-A`, `SHFIN-01-B`). This list is used in every subsequent step.

**Step 5.** [**ELEVATED**] Enable drain mode on each affected host:
  1. Tick the **checkbox** to the left of the first affected host name.
  2. In the toolbar above the table, click **Turn drain mode on**.
  3. A confirmation panel slides in from the right reading *"Turn on drain mode for the selected session hosts?"*
  4. Click the blue **Turn on** button.
  5. Repeat sub-steps 1–4 for every remaining affected host from Step 4.

> Expected result: The **Drain mode** column for each affected host changes from **Off** to **On**. The **Status** column still shows **Available** — existing sessions are preserved; no new sessions will be routed to these hosts.

**Step 6.** Contact the Service Desk (call or ticket update) and pass this exact message: *"POOL-FIN-01 hosts are in drain mode. Direct any Finance user reporting a black screen to fully close their Remote Desktop client, wait 30 seconds, and reconnect — they will land on a healthy host. Do not close the incident ticket."*

> Expected result: Service Desk acknowledges and has a consistent message ready for incoming calls.

---

### Phase B — Confirm root cause on a representative host

**Step 7.** [**ELEVATED**] Connect to the first affected host (e.g. `SHFIN-01-A`) as a local administrator using one of these two methods:

  **Via Azure Bastion (preferred — no public IP needed):**
  - In the Azure Portal top search bar, type `Virtual machines` and click the **Virtual machines** service.
  - Click **SHFIN-01-A** in the VM list.
  - In the VM blade left nav under **Connect**, click **Bastion**.
  - Enter your admin username and password, then click **Connect**. A new browser tab opens with the desktop session.

  **Via direct RDP:**
  - In the VM blade, click **Connect → RDP** and download the `.rdp` file.
  - Open the file, click **Connect**, and enter admin credentials when prompted.

> Expected result: A Windows desktop session on `SHFIN-01-A` is open. You are logged in as a local administrator. The taskbar is visible at the bottom of the screen.

**Step 8.** On the session host desktop, press `Win + R`. In the Run dialog type `eventvwr.msc` and press Enter.

> Expected result: Event Viewer opens. The left panel shows a tree with **Custom Views**, **Windows Logs**, **Applications and Services Logs**, and **Subscriptions**.

**Step 9.** In the Event Viewer left panel, expand **Windows Logs** and click **Application**.

> Expected result: The centre panel fills with Application log events. The most recent events appear at the top of the list.

**Step 10.** Filter the Application log for DWM crashes:
  1. In the right-hand **Actions** panel, click **Filter Current Log...**
  2. The *Filter Current Log* dialog opens. In the **\<All Event IDs\>** field, clear any existing text and type `1000`.
  3. Click **OK**.
  4. In the filtered results, click each entry and read the **General** tab in the lower pane. Look for entries containing all three of:
     - `Faulting application name: dwm.exe`
     - `Faulting module name: igdumd64.dll`
     - `Exception code: 0xc0000005`

> Expected result: At least one Event ID 1000 entry matches all three criteria, timestamped during the incident window (from approximately 07:00 today). This confirms the DWM / Intel graphics crash pattern.
> **If no matching entry exists:** stop here, do not proceed to Phase C. Re-open `avd-black-screen-ranked-hypotheses.md` and escalate to your team lead for re-triage.

**Step 11.** In the Event Viewer **Actions** panel click **Clear Filter**. Then apply a new filter:
  1. Click **Filter Current Log...**
  2. In the **\<All Event IDs\>** field type `9009`.
  3. Click **OK**.
  4. Check that entries appear with **Source** = `Desktop Window Manager`.

> Expected result: At least one Event 9009 entry is present with description containing `The Desktop Window Manager process has exited`, timestamped after an Event 1000 entry from Step 10. Steps 10 and 11 together confirm root cause — proceed to Phase C.

---

### Phase C — Remediate affected hosts

> **Decision point:** Choose **Option C1** (image rollback — preferred) if the previous known-good image version is available in Azure Compute Gallery. Choose **Option C2** (in-place registry mitigation) only if the previous image is not available. Confirm your choice with your team lead before continuing.

---

#### Option C1 — Roll back the host pool image (preferred)

**Step 12.** [**ELEVATED**] In the Azure Portal, navigate back to the POOL-FIN-01 blade. In the left navigation pane under **Settings**, click **Session host configuration**.

> Expected result: The *Session host configuration* blade opens. Under the **Image** section you can see the current gallery image reference and version (e.g. `CorpImageGallery / FinanceDesktop / 2024.03.15.0`). Note this version number before changing it.

**Step 13.** [**ELEVATED**] Click the **Edit** (pencil) icon next to the **Image** field:
  1. In the image picker that opens, select **Azure Compute Gallery**.
  2. Select the gallery name (e.g. `CorpImageGallery`).
  3. Select the image definition (e.g. `FinanceDesktop`).
  4. In the **Version** dropdown, select the version in use **before** the 02:00 update — confirm the version number against the change record collected in Prerequisites.
  5. Click **Save**.

> Expected result: A green notification banner appears: *"Session host configuration updated successfully"*. The **Image** field now shows the previous version number. Note: this setting only applies to hosts provisioned from this point forward — existing hosts must be re-imaged in Step 14.

**Step 14.** [**ELEVATED**] Re-image each affected host, one at a time:
  1. In the left nav under **Manage**, click **Session hosts**.
  2. Tick the checkbox next to the first affected host.
  3. In the toolbar click **Re-image**.
  4. A confirmation dialog appears showing the image version that will be applied — verify it matches the known-good version selected in Step 13.
  5. Click **Re-image** to confirm.
  6. The host **Status** changes to **Unavailable** then **Upgrading**. Stay on this page and wait until **Status** returns to **Available** before starting the next host. Do not re-image all hosts simultaneously — stagger them to preserve capacity.
  7. Repeat sub-steps 2–6 for each remaining affected host.

> Expected result: All affected hosts show **Status: Available** and their **OS version** column reflects the known-good image build number. No host remains in **Upgrading** or **Unavailable** state.

**Step 15.** [**ELEVATED**] Turn drain mode off on each remediated host:
  1. Tick the checkbox next to one remediated host.
  2. In the toolbar click **Turn drain mode off**.
  3. In the confirmation panel click **Turn off**.
  4. Repeat for every remaining host.

> Expected result: The **Drain mode** column shows **Off** for all previously affected hosts. The **Status** column shows **Available**. Users will now be routed to these hosts on next login.

---

#### Option C2 — In-place graphics render mitigation (use only if C1 is unavailable)

**Step 12 (C2).** [**ELEVATED**] On the affected session host desktop (your session from Step 7 should still be open), right-click the **Start** button and click **Windows PowerShell (Admin)**. Click **Yes** in the UAC prompt.

> Expected result: A blue PowerShell window opens. The title bar reads **Administrator: Windows PowerShell**.

**Step 13 (C2).** In the PowerShell window, paste the following command exactly and press Enter:

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "bEnumerateHWBeforeSW" -Value 0 -Type DWord -Force
```

Then confirm the key was written by running:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "bEnumerateHWBeforeSW"
```

> Expected result: The first command returns to a prompt with no red error text. The second command outputs `bEnumerateHWBeforeSW : 0`. If the output shows a different value or a "cannot find path" error, do not proceed — re-run the Set-ItemProperty command and check again.

**Step 14 (C2).** In the same PowerShell window, restart the host:

```powershell
Restart-Computer -Force
```

> Expected result: The desktop session disconnects immediately as the host reboots. Switch to the Azure Portal browser tab, navigate to **POOL-FIN-01 → Session hosts**, and watch the host **Status** column. It will cycle through **Unavailable** then return to **Available** — typically 3–5 minutes. Do not proceed until **Status** reads **Available**.

**Step 15 (C2).** [**ELEVATED**] Turn drain mode off on the remediated host:
  1. In the Session hosts list, tick the checkbox next to the host.
  2. In the toolbar click **Turn drain mode off**.
  3. In the confirmation panel click **Turn off**.
  4. Repeat Steps 12–15 for each remaining affected host, one at a time.

> Expected result: The **Drain mode** column shows **Off** and **Status** shows **Available** for each host. No host remains in drain mode.

---

## 3. Verification

**Step V1.** On your own machine, open the **Remote Desktop** client (or navigate to `aka.ms/wvdweb` in a browser to use the AVD web client). Sign in with a test account that has access to the Finance Desktop workspace but is **not** an active Finance user. Launch the **Finance Desktop** resource.

> Expected result — success looks like this:
> - The Windows desktop appears within 30 seconds.
> - The taskbar is visible at the bottom of the screen.
> - The desktop remains stable for at least 2 minutes — no black overlay, no black flash, no automatic disconnect, and no reconnect prompt.
>
> **If the session goes black or disconnects:** do not proceed to V2. Set drain mode back **On** for all POOL-FIN-01 hosts (Step 5 of this runbook) and go to Section 4 (Rollback).

**Step V2.** While your test session is still active, identify the session host that served it:
- In the **Remote Desktop** client: click the **connection bar** at the top of the session → click the signal icon → note the **Session host** field.
- In the **AVD web client**: click the signal-strength icon in the floating toolbar at the top of the session → note the **Session host** field.

> Expected result: A host name is displayed (e.g. `SHFIN-01-A`). Record this name — it is the host you will inspect in Steps V3 and V4.

**Step V3.** [**ELEVATED**] Open an admin session on the host identified in V2 (use Azure Bastion or RDP as described in Step 7). Open Event Viewer (`Win + R` → `eventvwr.msc` → Enter). Expand **Windows Logs** in the left panel and click **Application**. In the right **Actions** panel click **Filter Current Log...**, type `9011` in the **\<All Event IDs\>** field, and click **OK**.

> Expected result — success looks like this:
> - At least one Event 9011 entry is present with **Source** = `Desktop Window Manager` and description = `The Desktop Window Manager has started successfully`.
> - The timestamp of this entry is **after** the time you completed Phase C remediation.
> - **No** Event 9009 entry (`DWM process has exited`) exists with a timestamp after the Phase C completion time.
>
> **If Event 9009 appears after the remediation timestamp:** set drain mode **On** for this host immediately and escalate to the desktop engineering team. Do not proceed.

**Step V4.** In the same Event Viewer session, click **Clear Filter** in the Actions panel. Apply a new filter for Event ID `1000`. For each result, check the **General** tab in the lower pane and confirm there are **zero** entries matching all three of:
- `Faulting application name: dwm.exe`
- `Faulting module name: igdumd64.dll`
- `Exception code: 0xc0000005`

with a timestamp **after** the Phase C remediation completed. (Pre-remediation entries with this signature are expected and can be ignored.)

> Expected result — success looks like this:
> - Zero Event 1000 entries matching all three criteria exist after the Phase C completion timestamp.
> - The filter returns either no results, or only results from before remediation.
>
> **If any post-remediation matching entry exists:** put the host back into drain mode and escalate. Do not sign off the incident.

**Step V5.** Contact the Service Desk and ask them to have **two previously affected Finance users** log in to POOL-FIN-01 and report back to you directly.

> Expected result — success looks like this:
> - Both users confirm their desktop loaded normally with no black screen.
> - Neither user reports an unexpected disconnect or reconnect prompt.
> - Service Desk confirms **no new black-screen calls** have been received in the last 10 minutes.
>
> **If either user reports a black screen:** re-enable drain mode on all POOL-FIN-01 hosts and move to Section 4 (Rollback). Do not close the incident.

**Step V6.** In the Azure Portal, navigate to **Azure Virtual Desktop → Host pools → POOL-FIN-01 → Session hosts** (left nav under **Manage**).

> Expected result — success looks like this:
> - Every host in the table shows **Status: Available**.
> - Every host in the table shows **Drain mode: Off**.
> - No host shows **Status: Unavailable**, **Upgrading**, or **Needs assistance**.
> - The **Session count** column is incrementing as users connect (not stuck at zero after 10+ minutes of availability).
>
> Only when all steps V1–V6 pass is it safe to update the incident ticket to **Resolved**.

---

## 4. Rollback

> **Trigger:** Use this section the moment remediation makes things worse — new errors after disabling drain mode, users still hitting black screen after re-image, or host status not recovering.  
> **Target:** All steps below must be completed within 3 minutes. Follow them in order without skipping.

---

### R1 — Stop all user traffic to POOL-FIN-01 `[~45 seconds]`

1. In your browser go to **[portal.azure.com](https://portal.azure.com)**.
2. In the top search bar type `Azure Virtual Desktop` and click **Azure Virtual Desktop** under Services.
3. In the left navigation pane click **Host pools**.
4. Click **POOL-FIN-01** in the list.
5. In the POOL-FIN-01 left nav under **Manage**, click **Session hosts**.
6. Click the **checkbox in the table header row** to select all hosts at once.
7. In the toolbar click **Turn drain mode on**.
8. In the confirmation panel click **Turn on**.

> Expected result: Every host in the table shows **Drain mode: On**. No new sessions will be routed to POOL-FIN-01. Do not wait — move to R2 immediately.

---

### R2 — Redirect Finance users to POOL-FIN-02 `[~30 seconds]`

Call or message the Service Desk now and read them this exact instruction:

> *"Stop sending users to POOL-FIN-01. Tell all Finance users to close their Remote Desktop client completely, wait 10 seconds, reopen it, and connect to POOL-FIN-02 instead. Do not reconnect to POOL-FIN-01 until further notice."*

> Expected result: Service Desk confirms they have the message. Users connecting now will land on POOL-FIN-02. Do not wait for confirmation from users — move to R3.

---

### R3 — Revert the image reference (only if you completed Option C1) `[~60 seconds]`

*Skip this step if you used Option C2 — go to R4 instead.*

1. In the POOL-FIN-01 blade, in the left nav under **Settings**, click **Session host configuration**.
2. Click the **Edit** (pencil) icon next to the **Image** field.
3. In the image picker, select **Azure Compute Gallery** → select the gallery (e.g. `CorpImageGallery`) → select the image definition (e.g. `FinanceDesktop`).
4. In the **Version** dropdown, select the version that was in place **before you made any changes** — this is the version you noted in Step 12 of the Procedure.
5. Click **Save**.

> Expected result: A green banner appears: *"Session host configuration updated successfully"*. The **Image** field shows the pre-change version number. POOL-FIN-01 will use this image for any hosts provisioned from this point forward.

---

### R4 — Revert the registry change (only if you applied Option C2) `[~60 seconds per host]`

*Skip this step if you used Option C1 — go to R5 instead.*

For each host you applied the C2 registry change to:

1. Connect to the host via Azure Bastion: in the portal search bar type `Virtual machines`, click the VM name, click **Connect → Bastion**, enter admin credentials, click **Connect**.
2. Right-click **Start** → **Windows PowerShell (Admin)** → click **Yes** in the UAC prompt.
3. Paste and run both commands:

```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "bEnumerateHWBeforeSW" -Force
Restart-Computer -Force
```

> Expected result: The Bastion session disconnects as the host reboots. In the Azure Portal, navigate to **POOL-FIN-01 → Session hosts** and watch the host **Status** column — wait until it returns to **Available** (3–5 minutes) before reverting the next host. **Do not turn drain mode Off on any host until you have completed Section 3 Verification steps V3 and V4.**

---

### R5 — Escalate if rollback is not stable within 15 minutes `[immediate]`

If POOL-FIN-01 is still not stable or POOL-FIN-02 cannot absorb the redirected users within 15 minutes of starting rollback, open a P1 bridge call immediately:

- **Desktop engineering team** — responsible for image and DWM fix
- **AVD platform team** — responsible for host pool capacity and routing

Tell them: *"POOL-FIN-01 is fully drained following a failed remediation of a DWM / igdumd64.dll crash. All Finance users are on POOL-FIN-02. Referencing runbook `avd-black-screen-dwm-runbook.md` and RCA `avd-black-screen-incident-rca-2024-03-15.md`."*

---

## 5. Notes

### Edge cases
- **Partial host impact (~40%):** Not all hosts in POOL-FIN-01 may be affected. Map impacted users to specific session hosts before remediating. Hosts on the old image within the same pool should not be touched.
- **Users already in a disconnect/reconnect loop:** Advise them to fully close the Remote Desktop client and relaunch, not just reconnect. The reconnect will automatically route them to a healthy host once drain mode is set.
- **Sessions that survive the black screen:** A subset of sessions recover after ~30 seconds. Do not assume recovery means the host is healthy — the DWM crash is still occurring; the session compositor is merely restarting. These hosts must still be drained and remediated.

### Warnings
- [**ELEVATED**] Steps marked elevated require Azure RBAC Desktop Virtualization Contributor. Do not attempt them with a standard user account — the portal will silently fail or return a permissions error.
- Do not delete active user sessions during drain without confirming users have saved their work. Use drain mode, not forced disconnect, to contain impact.
- Option C2 (registry mitigation) is a temporary workaround. It does not replace a proper image rollback. Raise a change request to apply the corrected image to POOL-FIN-01 within the next maintenance window.
- If the Intel graphics driver (`igdumd64.dll`) version differs between POOL-FIN-01 and POOL-FIN-02, escalate driver version as a specific change item in the post-incident review.

### Related incidents and documents
- `avd-black-screen-incident-rca-2024-03-15.md` — root cause analysis
- `avd-black-screen-ranked-hypotheses.md` — triage hypothesis ranking used during the incident
- `known-error-avd-black-screen-pool-fin-01.md` — known error record
- `avd-incident-closure-note.md` — incident closure summary
- Preceding change record: overnight image update to POOL-FIN-01 at 02:00 on 2024-03-15 (check your change management system for the exact CR number)

### Prevention note
The 5 Whys in the RCA identified that the update wave lacked a canary gate checking for Event 1000 (`dwm.exe`/`igdumd64.dll`) and Event 9009 after pilot logons. Until that gate is in place, treat any post-image-update black screen symptom on a single pool as a graphics regression until proven otherwise and triage against this runbook first.
