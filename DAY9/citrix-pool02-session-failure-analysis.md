# Citrix VDI Session Failure — Detailed Analysis
**Incident:** FinBridge-VDI-Pool-02 session launch failures  
**Date:** 2026-08-13  
**Analyst:** DWP Tier 2  
**Status:** Root cause identified — remediation actions defined  

---

## 1. Incident summary

22 of 30 users on `FinBridge-VDI-Pool-02` were unable to launch VDI sessions. The broker returned error 1030 (`No machines available in the desktop group`) after a 30-second timeout. Pool-01 users on the same site were unaffected throughout.

---

## 2. Scope

| Item | Detail |
|---|---|
| Affected pool | FinBridge-VDI-Pool-02 |
| Affected users | 22 of 30 |
| Unaffected pool | FinBridge-VDI-Pool-01 (same site) |
| First failure observed | 08:58:03 (jsmith session launch) |
| Affected Delivery Controller | dc-vdi-02.finbridge.local |
| Unaffected Delivery Controller | dc-vdi-01 (serves Pool-01) |

---

## 3. Evidence collected

### 3.1 Broker log (08:58)
```
[08:58:03] Session launch requested: user jsmith, Pool-02
[08:58:04] Broker: Querying available machines in Pool-02
[08:58:34] Broker: Timeout waiting for machine registration response (30000ms exceeded)
[08:58:34] Session launch FAILED: error 1030 'No machines available in the desktop group'
```

### 3.2 Machine catalog registration status

| Pool | Provisioned | Registered | Unregistered | Maintenance |
|---|---|---|---|---|
| Pool-02 (affected) | 25 | 3 | 22 | 0 |
| Pool-01 (unaffected) | 20 | 19 | 1 | 0 |

### 3.3 Unregistered machine errors (Pool-02 sample)

| Machine | Last attempt | Error |
|---|---|---|
| VDI-P02-014 | 06:15:22 | Unable to contact Delivery Controller — dc-vdi-02.finbridge.local:80 — **connection refused** |
| VDI-P02-017 | 06:16:01 | Unable to contact Delivery Controller — dc-vdi-02.finbridge.local:80 — **connection refused** |

### 3.4 Delivery Controller health

| Controller | Service | Uptime | Notes |
|---|---|---|---|
| dc-vdi-02 | **STOPPED** | Last running: yesterday 23:40 | Windows Update ran 00:15 today; reboot-required flag set; host NOT rebooted |
| dc-vdi-01 | RUNNING | 14 days | No issues |

---

## 4. Analysis

### 4.1 Signal isolation

The scope split — Pool-02 affected, Pool-01 not — immediately eliminates site-wide causes:
- Network connectivity to the site: eliminated (Pool-01 machines registering normally)
- Hypervisor or storage issues: eliminated (same infrastructure, different outcome)
- User account or profile issues: eliminated (22 different users, same pool-scoped failure)

The failure is contained to Pool-02 and its Delivery Controller, dc-vdi-02.

### 4.2 Error code interpretation

**Error 1030** (`No machines available in the desktop group`) is a Citrix broker error indicating that when the broker queried the desktop group, it found zero machines in a `Registered` state able to accept a session. This is a symptom, not a root cause — it reflects the registration state of the pool.

**Connection refused on port 80** is a TCP-level rejection. This means the destination host (dc-vdi-02) is actively refusing the connection on that port — the Citrix Broker Service is not listening. This is distinct from `connection timed out`, which would indicate a firewall or network block.

### 4.3 Timeline correlation

| Time | Event |
|---|---|
| Yesterday 23:40 | Citrix Broker Service last confirmed running on dc-vdi-02 |
| Today 00:15 | Windows Update installs on dc-vdi-02; reboot-required flag set; host NOT rebooted |
| 06:15–06:16 | Pool-02 VMs attempt re-registration, receive connection refused on port 80 |
| 08:58 | First user session launch failure logged (error 1030) |

The sequence is linear. The update ran between the last known-good state (23:40) and the first failure evidence (06:15). No other change event is recorded.

### 4.4 Why 3 machines remained registered

The 3 machines that stayed registered had active or recently re-established connections to dc-vdi-02 before the service stopped and maintained their TCP session state. Machines that attempted re-registration after 00:15 (the update window) received connection refused and entered the unregistered state.

---

## 5. Ranked hypotheses

### Hypothesis 1 — Windows Update stopped the Citrix Broker Service (PRIMARY)
The update ran, stopped the Broker Service as part of its installation process, and the service did not restart because the required reboot was not performed. The reboot-required flag confirms pending file replacement operations that prevent full service recovery without a restart.

**Confidence: High.** All evidence points here. No conflicting data.

### Hypothesis 2 — Service cannot start due to pending reboot file locks
A sub-variant of H1: even if the service is manually started, it may fail because Windows Update has pending file replacements (held in `%WinDir%\WinSxS\pending.xml`) that lock components the Broker Service depends on. The reboot resolves the lock.

**Confidence: Medium.** Plausible co-condition with H1. Start attempt should confirm or eliminate.

### Hypothesis 3 — Update modified service account permissions
Some updates reset Local Security Policy, removing the "Log on as a service" right from the Broker Service account. Less common and would produce a specific 1069 event in the System log.

**Confidence: Low.** Not the primary hypothesis but should be checked if H1 remediation fails.

---

## 6. Remediation plan

### 6.1 Immediate steps (in order)

| Step | Action | Expected outcome |
|---|---|---|
| 1 | Notify affected users via IT communications channel | User awareness; reduce repeat contacts |
| 2 | RDP to dc-vdi-02 as administrator | Access to take remediation action |
| 3 | Run: `Start-Service CitrixBrokerService` | Service starts (fastest path, no reboot) |
| 4 | If step 3 succeeds: monitor Pool-02 registration count | Should recover to ~25 within 5 minutes |
| 5 | If step 3 fails: schedule and execute `Restart-Computer -Force` | Clears pending file locks; service starts on boot |
| 6 | Post-reboot: confirm `Get-Service CitrixBrokerService` shows Running | Service recovered |
| 7 | Confirm Pool-02 registered machine count returns to 25 | All machines back in service |
| 8 | Run a test session launch for a Pool-02 user | End-to-end validation |
| 9 | Send all-clear to affected users | Incident resolved |

### 6.2 Verification check

```powershell
# On dc-vdi-02
Get-Service CitrixBrokerService | Select-Object Status, StartType
# Expected: Status=Running, StartType=Automatic

# From Citrix Studio / Delivery Controller PowerShell
Get-BrokerMachine -DesktopGroupName "FinBridge-VDI-Pool-02" |
  Group-Object RegistrationState |
  Select-Object Name, Count
# Expected: Registered=25, Unregistered=0
```

---

## 7. Preventive actions

| Priority | Action | Owner |
|---|---|---|
| High | Configure Windows Update on all Delivery Controllers to install only during an approved maintenance window (e.g., Saturday 02:00–04:00) with automatic reboot and post-reboot health check | Infrastructure team |
| High | Add service monitoring alert for `CitrixBrokerService` on all Delivery Controllers — page on-call within 5 minutes of service stopping | Monitoring team |
| Medium | Implement a post-update validation script that checks Broker Service status after any update and auto-starts the service or triggers an alert if it fails to start | Automation team |
| Low | Document Delivery Controller update procedures in the team runbook, including the requirement to manually verify service health after every update | DWP team |
