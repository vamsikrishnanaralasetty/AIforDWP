# Runbook: Finance Team Cannot Access Shared Drives (S: Not Mapped at Logon)

| Field | Detail |
|---|---|
| **Title** | Finance Team Cannot Access Shared Drives (S: Not Mapped at Logon) |
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Change** | Initial runbook from RCA |

---

**Service:** Windows endpoint drive mapping  
**Affected component:** Shared drive mapping for `S:` at user sign-in  
**Trigger:** Migration from GPO logon script to Intune PowerShell delivery  
**Related RCA:** `drive-mapping-failure-rca.md`  

---

## 1. Prerequisites

### Access required
| Requirement | Detail |
|---|---|
| Intune admin access | Ability to view and edit script assignment and execution context |
| AD / identity admin access | Validate Finance user group membership |
| Endpoint admin access | Local admin on affected device for diagnostics |
| File server access | Read access to shared path backing `S:` |

### Tools required
- Intune admin center
- Event Viewer
- PowerShell (run as affected user and as admin when requested)
- Service Desk contact channel for user validation

### Information to gather before starting
- Affected user UPN(s)
- Affected device name(s), expected pattern `DESKTOP-FB*`
- Expected mapping details:
  - Drive letter: `S:`
  - UNC path: `<server>\<share>`
- Change ticket for the migration from GPO to Intune script

---

## 2. Procedure

### Phase A - Confirm impact and contain

**Step 1.** Confirm scope with Service Desk:
- Users impacted are from Finance
- Devices match `DESKTOP-FB*`
- Symptom is specifically: `S:` missing right after sign-in

> Expected result: Scope is consistent and incident is not random single-device failure.

**Step 2.** Ask affected users to sign out and sign in once.

> Expected result: If `S:` appears after second sign-in, this indicates sign-in timing race. Keep incident open and continue triage.

**Step 3.** Pause further rollout of the new Intune mapping script assignment (if still expanding).

> Expected result: No additional users are newly impacted during investigation.

---

### Phase B - Verify mapping behavior on one affected endpoint

**Step 4.** Sign in to one affected endpoint as an affected Finance user.

Run in user PowerShell:

```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue
```

> Expected result: No output or drive missing confirms current failure state.

**Step 5.** Validate share reachability from the same user session.

```powershell
Test-Path "\\<server>\\<share>"
```

> Expected result:
- `True`: network path is reachable, issue is mapping delivery/timing/context.
- `False`: check DNS/network/permissions before blaming script migration.

**Step 6.** Check whether a persistent mapping exists but was not restored.

```powershell
Get-ItemProperty -Path "HKCU:\Network\S" -ErrorAction SilentlyContinue
```

> Expected result:
- Key absent: mapping never created in user profile.
- Key present but drive absent: stale/broken persistent mapping logic.

---

### Phase C - Validate Intune script delivery assumptions

**Step 7.** In Intune, open the drive mapping PowerShell script and check:
- Assignment targets Finance users (not only devices)
- Script execution context is user context for user drive mapping
- Script runs at sign-in or near sign-in, not only one-time device provisioning

> Expected result: Configuration matches user-logon mapping requirements.

**Step 8.** On affected endpoint, review Intune Management Extension logs for script execution timing and result.
- Primary location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`
- Review `IntuneManagementExtension.log` around user sign-in time

> Expected result: Script execution record exists for affected user and timestamp aligns with sign-in.

**Step 9.** If script ran in system context, correct to user-compatible delivery approach and re-deploy.

> Expected result: Mapping logic runs in user session context where `HKCU` and user token are valid.

---

### Phase D - Apply remediation

Use the least risky approved option:

**Option D1 (preferred):** Correct Intune script execution model
1. Ensure user-targeted assignment for Finance scope
2. Ensure user-session compatible execution method
3. Re-sync policy on pilot devices
4. Sign out and sign in for pilot users

**Option D2 (containment):** Temporary fallback to known-good GPO mapping for Finance until Intune parity is proven

> Expected result: Finance users receive `S:` reliably at first sign-in after deployment.

---

## 3. Verification

**Step V1.** On at least 3 affected Finance users across different `DESKTOP-FB*` devices, sign out and sign in.

> Expected success:
- `S:` is present in File Explorer and `Get-PSDrive`
- Mapped path opens without prompt loops
- No manual script launch needed

**Step V2.** Confirm no new incidents for 30-60 minutes after fix during active business period.

> Expected success: No fresh reports for missing `S:` mapping.

**Step V3.** Confirm Intune report state shows successful script execution for in-scope users/devices.

> Expected success: Failures are cleared or reduced to known exceptions.

---

## 4. Rollback

Trigger rollback if any of these occur:
- Mapping still fails for more than 20% of pilot users
- Script only works after multiple sign-ins
- New user cohorts start failing

Rollback actions:
1. Revert to known-good mapping method (previous GPO logon script or equivalent)
2. Remove or disable problematic Intune assignment
3. Re-validate with 3 Finance users before closing rollback activity

---

## 5. Escalation

Escalate to L2/L3 if:
- UNC path is reachable but mapping still fails after context fix
- Script success is reported but `S:` still absent in user session
- Behavior differs by subset of `DESKTOP-FB*` devices with same policy state

Escalation bundle must include:
- User UPN, device name, incident timestamp
- Script assignment screenshot (scope + context)
- Relevant Intune log lines during sign-in window
- Output of:

```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue
Test-Path "\\<server>\\<share>"
Get-ItemProperty -Path "HKCU:\Network\S" -ErrorAction SilentlyContinue
```

---

## 6. Closure Criteria

Close incident only when all are true:
- Finance users on `DESKTOP-FB*` can access `S:` at sign-in
- No repeat calls in monitoring window
- Remediation and validation evidence is recorded in incident notes
- Preventive actions logged (parity testing, context verification, pilot gates)
