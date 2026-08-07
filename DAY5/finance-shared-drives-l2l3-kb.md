# KB Article: Finance Team Cannot Access Shared Drives - L2/L3

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Audience** | L2 / L3 Endpoint Engineering |
| **Related Runbook** | `finance-shared-drives-runbook.md` |
| **Related RCA** | `drive-mapping-failure-rca.md` |

---

## 1. Background

A migration changed drive mapping delivery from a GPO user logon script to an Intune PowerShell script. After this change, Finance users on `DESKTOP-FB*` endpoints reported that `S:` was not mapped at sign-in.

This pattern indicates a delivery-model mismatch:
- Legacy GPO behavior executed mapping in user logon flow.
- New Intune behavior did not consistently reproduce the same user-session timing/context.

Result: user signs in successfully, but mapped drive is missing at first interactive session.

---

## 2. Scope Pattern and Signals

Expected scope markers:
- Department-limited impact (Finance)
- Device cohort pattern (`DESKTOP-FB*`)
- Symptom tied to sign-in timing (`S:` missing right after logon)
- Strong temporal correlation to overnight migration/cutover

Differentiators from other issues:
- Authentication succeeds
- Endpoint is usable
- Specific mapped drive missing, not full profile failure
- Often reproducible on first sign-in but may improve after retry

---

## 3. Technical Root Cause

Root cause from RCA:
- Post-migration mismatch between GPO user-logon execution model and Intune script delivery behavior.

Likely failure mechanics:
1. Script executed in device/system context for user mapping workload.
2. Script executed before user network/session dependencies were ready.
3. Assignment targeting did not fully map to intended Finance user scope.
4. Validation focused on deployment status instead of user-logon functional parity.

---

## 4. Detection and Evidence Collection

Collect these artifacts from an affected session:

### 4.1 User-session state

```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue
Get-ItemProperty -Path "HKCU:\Network\S" -ErrorAction SilentlyContinue
whoami
```

What this shows:
- Whether `S:` exists in active session
- Whether persistent mapping key exists in user hive
- Which security principal is executing checks

### 4.2 Share reachability

```powershell
Test-Path "\\<server>\\<share>"
```

Interpretation:
- `True`: path reachable, failure likely in mapping delivery logic.
- `False`: validate DNS, routing, ACL, VPN/line-of-sight dependencies.

### 4.3 Intune execution evidence

Log path:
- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`

What to extract:
- Script assignment ID
- Execution timestamp near sign-in
- Execution context clues (user/device)
- Exit code and error strings

### 4.4 Scope integrity

Validate in Intune:
- Assignment includes intended Finance identities
- Exclusion groups are not accidentally filtering Finance users
- No conflicting script/profile unmapping `S:` later in sign-in sequence

---

## 5. Resolution Strategy

Use a controlled rollout with pilot-first validation.

### Option A (preferred): Correct Intune delivery parity

1. Ensure mapping logic runs in user-compatible execution model.
2. Ensure assignment targets intended Finance user scope.
3. Add sign-in timing resilience in script (retry with short backoff while waiting for network path).
4. Re-deploy to pilot subset of Finance users on `DESKTOP-FB*`.
5. Validate first-logon outcome before broader rollout.

Suggested script behavior guardrails:
- Check if `S:` already mapped before mapping.
- Validate UNC path is reachable.
- Write deterministic logging for success/failure.
- Return non-zero exit code on hard failure for reporting.

### Option B: Temporary fallback to known-good GPO behavior

Use only when production impact is ongoing and parity fix needs more time.

1. Re-enable known-good GPO mapping for affected Finance cohort.
2. Disable or narrow problematic Intune assignment.
3. Confirm restored sign-in behavior.
4. Resume Intune migration only after pilot parity checks pass.

---

## 6. Validation Criteria

Fix is complete only if all are true:
- `S:` maps on first sign-in for pilot and then full Finance cohort.
- At least 3-5 representative users on different `DESKTOP-FB*` endpoints confirm success.
- No new L1 tickets for missing `S:` during first business-hour monitoring window.
- Intune execution report indicates expected success for in-scope assignments.

Recommended test matrix:
- Existing user on previously affected device
- New sign-in on previously affected device
- User with recent password/token refresh
- Device after reboot and fresh sign-in

---

## 7. Known Pitfalls

- Treating deployment success as functional success.
- Running user-drive mapping in device/system context.
- Missing pilot gates and post-cutover observation window.
- Not validating conflicting policies/scripts that alter drive mappings.
- Assuming one successful user test proves cohort-level stability.

---

## 8. Preventive Controls

Implement these controls for future migrations:
1. Mandatory pre-cutover parity checklist (GPO vs Intune user outcome).
2. Explicit execution-context sign-off for each script.
3. Pilot ring with representative users/devices before full rollout.
4. Rollback trigger threshold (for example >5% sign-in mapping failures).
5. First-hour post-change monitoring and on-call ownership.

---

## 9. Escalation Guidance

Escalate beyond endpoint engineering if:
- UNC path unreachable across multiple in-scope users (possible file service/network issue)
- Evidence suggests identity/authorization failure rather than mapping delivery
- Impact expands outside Finance or outside `DESKTOP-FB*` unexpectedly

Escalation packet should include:
- Affected users/devices/time window
- Intune assignment and context configuration evidence
- Relevant log excerpts and command outputs
- Validation outcomes before and after remediation
