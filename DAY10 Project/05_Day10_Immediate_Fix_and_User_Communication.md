# Floor 6 Immediate Fix and User Communication

## Version Header
- Title: Floor 6 Immediate Fix and User Communication
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Draft

## Scope
This document identifies the single most likely current cause of the Floor 6 login and performance issue based on the investigation record completed so far, recommends an immediate operational fix path, and provides user and manager communications. This is not a final root-cause report.

---

## SECTION 1 - Most Likely Cause

### Most Likely Cause
The single most likely current cause is that the Friday document management application deployment introduced startup-time resource overhead or unstable application components on recently migrated Windows 11 and Intune-enrolled Floor 6 devices, resulting in severe login slowness and some apparent login failures.

### Evidence Supporting the Conclusion
- A targeted change is known: a new document management application was deployed to Floor 6 on Friday afternoon.
- The reported issue began on Monday morning after that deployment window.
- The impact appears concentrated on Floor 6, which aligns with a floor-scoped change more than with a broad enterprise platform failure.
- The symptom mix includes very slow logins, which is consistent with startup processing overhead, application service initialization delay, shell extension impact, update loops, or failed post-install components.
- The evidence-collection planning completed earlier identified application version, active processes, CPU, memory, disk, startup entries, and crash evidence as the fastest direct tests of this deployment hypothesis.
- The deployment hypothesis is also the most operationally reversible cause currently on the table, which matters when deciding what immediate containment action is proportionate while evidence remains incomplete.

### Evidence Still Missing
- Confirmed overlap between affected users/devices and the Friday deployment target ring.
- Per-device install success or failure state.
- Application crash or hang evidence.
- Resource utilization data showing the application or its components consuming CPU, memory, or disk during login.
- Sign-in logs proving whether affected users were blocked before or after successful authentication.
- Comparison with unaffected Floor 6 devices.

### Confidence Level
Low-Medium.

### Why Other Hypotheses Were Not Selected
- Authentication path degradation:
  - This was previously ranked highly because it explains "cannot log in" well.
  - It was not selected here because there is still no reviewed sign-in evidence, no confirmed wider identity-service signal, and the issue remains associated with a recent floor-specific change.
  - It remains a valid alternative and must still be checked.

- Intune policy or compliance processing impact:
  - This remains plausible because the floor was recently enrolled in Intune.
  - It was not selected because the only specific known change in the reported window is the Friday application deployment.
  - It may still be a contributing factor or an interaction effect.

- Profile loading issue:
  - This can explain severe delay but is less directly supported by the known timing and recent deployment context.
  - No profile-service evidence has yet been reviewed.

- Network-related issue:
  - A floor-local network problem could explain broad impact.
  - It was not selected because there is no known network incident evidence and no floor network telemetry has been reviewed.

- Device resource constraints unrelated to the application:
  - This could worsen login times.
  - It was not selected because the recent targeted deployment provides a more specific and more actionable explanation for resource pressure.

### Reasoning
This is an operational selection, not a confirmed root cause. The decision is based on the combination of targeted change timing, floor-local scope, symptom fit with startup/resource degradation, and the availability of a low-blast-radius containment action. The missing evidence means the conclusion must remain provisional.

### Facts vs Assumptions
- Facts:
  - Floor 6 devices were recently migrated to Windows 11 and enrolled in Intune.
  - At least a dozen users were reported as unable to log in or experiencing extremely slow logins.
  - A new document management application was deployed to Floor 6 on Friday afternoon.
  - Issues were first reported Monday morning.
- Assumptions still requiring validation:
  - Affected devices actually received the deployment.
  - The deployed application starts during sign-in or desktop initialization.
  - The application is the dominant cause rather than one contributor among several.
  - Apparent login failures are downstream of slowdown rather than primary identity failure.

---

## SECTION 2 - Immediate Technical Action

The selected cause is related to the Friday application deployment, so the immediate action is containment of the deployment scope followed by controlled rollback on the affected cohort.

### Assumptions Required for This Fix Path
- The application was deployed through Intune as a Windows app assignment.
- The deployed app is identifiable in Intune as `Document Management Client`.
- Affected Floor 6 devices can be listed in a CSV file named `Floor6-AffectedDevices.csv` with a `DeviceName` column.
- Either a silent uninstall string is available on the endpoint or a known-good previous version package already exists in Intune.
- The engineer running these actions has Microsoft Graph and Intune administrative rights.

### Prerequisites
- Administrative access to Intune and Microsoft Graph.
- Confirmed list of affected devices.
- Existing rollback or uninstall approach validated in a test device or pilot group.
- Maintenance approval in line with incident handling policy.
- JSON/CSV-safe storage location for the affected device list.

### Immediate Action Sequence

#### Action 1 - Freeze further exposure by excluding affected devices from the active deployment
Administrative platform action:
1. Open Intune Admin Center.
2. Go to Apps > Windows > `Document Management Client`.
3. Open Properties > Assignments.
4. Remove or suspend the required assignment to the Floor 6 deployment ring.
5. Add an exclusion assignment for a new security group named `DG-Floor6-DocMgmt-Rollback`.
6. Save the assignment change.

Expected result after action:
- No additional affected Floor 6 devices continue receiving the application while rollback actions are being prepared.

#### Action 2 - Create an exclusion / rollback group
PowerShell commands:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph.Groups
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All","DeviceManagementApps.ReadWrite.All","DeviceManagementManagedDevices.PrivilegedOperations.All"

$rollbackGroup = New-MgGroup `
  -DisplayName "DG-Floor6-DocMgmt-Rollback" `
  -MailEnabled:$false `
  -MailNickname "dgfloor6docmgmtrollback" `
  -SecurityEnabled:$true

$rollbackGroup.Id
```

Expected result after action:
- A dedicated security group exists to isolate affected devices from the deployment.

#### Action 3 - Add affected devices to the rollback group
PowerShell commands:

```powershell
$devices = Import-Csv .\Floor6-AffectedDevices.csv

foreach ($item in $devices) {
    $device = Get-MgDevice -Filter "displayName eq '$($item.DeviceName)'"
    if ($device) {
        New-MgGroupMemberByRef -GroupId $rollbackGroup.Id -BodyParameter @{
            '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($device.Id)"
        }
    }
}
```

Expected result after action:
- The identified affected Floor 6 devices are excluded from the active deployment assignment.

#### Action 4 - Push an immediate Intune sync to affected managed devices
PowerShell commands:

```powershell
Import-Module Microsoft.Graph.DeviceManagement

foreach ($item in $devices) {
    $managedDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($item.DeviceName)'"
    if ($managedDevice) {
        Invoke-MgDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $managedDevice.Id
    }
}
```

Expected result after action:
- Assignment changes are picked up sooner on the affected devices.

#### Action 5 - Deploy an uninstall script to the affected cohort
PowerShell uninstall script to deploy through Intune script or remediation package:

```powershell
$matchName = "Document Management"
$paths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$app = foreach ($path in $paths) {
    if (Test-Path $path) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.DisplayName -like "*$matchName*" }
    }
} | Select-Object -First 1

if (-not $app) {
    throw "Document Management application not found."
}

if (-not $app.UninstallString) {
    throw "Uninstall string not found for installed application."
}

$uninstallString = $app.UninstallString

if ($uninstallString -match "msiexec") {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString /qn /norestart" -Wait -NoNewWindow
}
else {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString /quiet /norestart" -Wait -NoNewWindow
}
```

Administrative platform action:
1. In Intune, create a temporary rollback script or uninstall app assignment targeted only to `DG-Floor6-DocMgmt-Rollback`.
2. Set execution in system context.
3. Do not target the wider tenant.

Expected result after action:
- The suspected application is removed from the affected devices.

#### Action 6 - If a known-good prior version exists, assign it only after rollback validation
Administrative platform action:
1. In Intune, select the previous stable package for `Document Management Client`.
2. Assign it as Required only to a temporary pilot group such as `DG-Floor6-DocMgmt-Rollback-Pilot`.
3. Limit pilot to a small number of previously affected users.

Expected result after action:
- A small pilot group receives a known-good version for controlled reintroduction only after the unstable version is removed.

### Validation Steps
- Confirm the active deployment assignment no longer targets the affected cohort.
- Confirm rollback group membership matches the affected device list.
- Confirm devices synced successfully in Intune.
- Confirm uninstall completion on sample endpoints.
- Confirm the application no longer appears in uninstall registry paths on affected devices.
- Confirm no immediate increase in login duration after next sign-in cycle.

---

## SECTION 3 - Verification Plan

| What Will Be Checked | Tool | What Success Looks Like | What Indicates Rollback Was Unsuccessful |
| --- | --- | --- | --- |
| Login duration on previously affected devices | Endpoint Analytics, user validation | Login time falls materially from incident condition and users reach desktop normally | Login remains very slow or users still cannot reach desktop |
| Sign-in success versus failure pattern | Entra Sign-in Logs | Failed sign-ins reduce and successful logins increase for previously affected users | Same failure pattern continues after rollback |
| Device performance during sign-in | Nexthink, Endpoint Analytics, Task Manager/Resource Monitor on sample device | CPU, memory, and disk pressure return to normal or materially improve | High disk queue, CPU saturation, or memory pressure persists |
| Application presence after rollback | Intune device status, registry uninstall entries | Suspected app/version no longer present on rollback devices | App remains installed or reinstalls unexpectedly |
| Application stability / crash evidence | Event Viewer, Reliability Monitor | Relevant crash/hang events stop recurring after rollback | Application Error, Service Control Manager, or hang events continue |
| Startup impact | Startup entries, Autoruns or Win32_StartupCommand review | Application startup entries removed or changed as expected | Startup entries remain and continue to trigger at sign-in |
| User experience validation | Direct user confirmation through service desk | Users report meaningful improvement after next sign-in | Users report no change or only partial improvement |

Verification sequence reasoning:
- First confirm the platform action landed.
- Then confirm the suspected app is removed.
- Then confirm login behavior and performance improved.
- Then confirm users see the same improvement.

---

## SECTION 4 - Floor 6 User Communication

Subject: Update on Floor 6 login and slow computer issue

We’re aware that some people on Floor 6 are having trouble signing in or are seeing unusually long wait times when they start work. We are actively reviewing a recent software change on Floor 6 and are taking steps to reduce the impact while we continue to confirm the exact cause.

If you are affected, please report it to the Service Desk with your device name, the time the problem happened, and whether you were unable to sign in or whether sign-in was just very slow. We will send another update once we have confirmed whether the change we are reviewing has improved the situation.

---

## SECTION 5 - Manager Talking Points

- Situation Summary: Floor 6 is experiencing a concentrated login and performance issue affecting multiple users, and the leading operational hypothesis is a recently deployed application change specific to that floor.
- Current Action: IT is containing that deployment, isolating affected devices, and validating whether removing the application improves sign-in performance.
- Business Impact: The issue is causing active productivity loss for part of the floor and needs close monitoring until device performance and sign-in reliability stabilize.
- Next Update Commitment: We will provide the next evidence-based update after rollback validation results are available from the affected device group.

---

## SECTION 6 - Risks and Considerations

### Risks of Taking the Immediate Fix
- The application may not be the true cause, so rollback may not resolve the issue.
- If the application supports time-sensitive document workflows, removing it may reduce user capability temporarily.
- If the issue is multi-causal, rollback may only partially improve the symptom.

### Potential Side Effects
- Users may lose access to the new document management client until a stable version is restored.
- Device sync timing may vary, so results may not appear immediately on all affected endpoints.
- If uninstall strings differ across package variants, uninstall success may be inconsistent.

### Rollback Considerations
- Rollback should be limited to the affected Floor 6 cohort first.
- A known-good version should not be reintroduced broadly until pilot validation succeeds.
- Group assignments must be reviewed carefully to avoid removing the app from unaffected populations unintentionally.

### Communication Considerations
- User updates should state what is known, what is still being checked, and what users should do if affected.
- Communications should avoid declaring a final cause before validation.
- Managers should be told that the rollback is a containment action based on current evidence, not proof of final root cause.

---

End of Document
