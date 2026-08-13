# Root Cause Analysis — Citrix VDI Session Launch Failure
**Incident ID:** INC-2026-0813-VDI-002  
**Date of incident:** 2026-08-13  
**Date of RCA:** 2026-08-13  
**Severity:** High (22 users unable to work)  
**Service affected:** FinBridge-VDI-Pool-02  
**Prepared by:** DWP Tier 2 Analyst  
**Status:** Root cause confirmed  

---

## 1. Executive summary

On 2026-08-13, 22 of 30 users on `FinBridge-VDI-Pool-02` were unable to launch virtual desktop sessions. The Citrix Broker returned error 1030 (`No machines available in the desktop group`). The root cause was the Citrix Broker Service (`CitrixBrokerService`) stopping on Delivery Controller `dc-vdi-02.finbridge.local` following a Windows Update installation at 00:15. The host was not rebooted after the update, leaving the service in a stopped state. All 22 unregistered Pool-02 machines reported `connection refused` to `dc-vdi-02:80`, confirming the service was not listening. Pool-01 and its controller dc-vdi-01 were unaffected throughout.

---

## 2. Incident timeline

| Time | Event | Source |
|---|---|---|
| Yesterday 23:40 | Citrix Broker Service last confirmed running on dc-vdi-02 | DC health log |
| Today 00:15 | Windows Update installs on dc-vdi-02; reboot-required flag set; host NOT rebooted | DC health log |
| 00:15–06:15 | Broker Service in stopped state; no monitoring alert triggered | Gap in monitoring |
| 06:15:22 | VDI-P02-014 attempts re-registration — connection refused (dc-vdi-02:80) | Unregistered machine log |
| 06:16:01 | VDI-P02-017 attempts re-registration — connection refused (dc-vdi-02:80) | Unregistered machine log |
| 08:58:03 | User jsmith attempts session launch on Pool-02 | Broker log |
| 08:58:04 | Broker queries Pool-02 for available machines | Broker log |
| 08:58:34 | Broker times out (30,000 ms) — no registered machines respond | Broker log |
| 08:58:34 | Session launch FAILED — error 1030 reported to user | Broker log |
| 08:58+ | 22 users affected; Pool-01 (dc-vdi-01) continues operating normally | Broker log / catalog |

---

## 3. Supporting evidence

### 3.1 Broker log extract

```
[08:58:03] Session launch requested: user jsmith, Pool-02
[08:58:04] Broker: Querying available machines in Pool-02
[08:58:34] Broker: Timeout waiting for machine registration response (30000ms exceeded)
[08:58:34] Session launch FAILED: error 1030 'No machines available in the desktop group'
```

### 3.2 Machine catalog registration state

| Pool | Provisioned | Registered | Unregistered | Maintenance |
|---|---|---|---|---|
| Pool-02 (affected) | 25 | 3 | **22** | 0 |
| Pool-01 (unaffected) | 20 | 19 | 1 | 0 |

### 3.3 Unregistered machine error detail

```
VDI-P02-014: Last registration attempt 06:15:22, failed
  Error: Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 - connection refused

VDI-P02-017: Last registration attempt 06:16:01, failed
  Error: Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 - connection refused
```

`connection refused` (TCP RST) confirms the target process is not listening on port 80. This is distinct from `connection timed out`, which would indicate a network-level block.

### 3.4 Delivery Controller health state

| Controller | Service | Detail |
|---|---|---|
| dc-vdi-02 | **STOPPED** | Last running yesterday 23:40. Windows Update installed today 00:15. Reboot-required flag set. Host NOT rebooted. |
| dc-vdi-01 | RUNNING | 14 days uptime. No events. Serves Pool-01. |

### 3.5 Scope isolation evidence

| Scope test | Result | Inference |
|---|---|---|
| Same site, different pool (Pool-01) | Unaffected | Site-wide cause eliminated |
| Same infrastructure | Pool-01 normal | Hypervisor/storage cause eliminated |
| Multiple users affected | 22 different users | User-account cause eliminated |
| All unregistered machines report same error | dc-vdi-02:80 refused | Single point of failure confirmed |

---

## 4. Root cause

**The Citrix Broker Service (`CitrixBrokerService`) on Delivery Controller `dc-vdi-02.finbridge.local` was stopped by a Windows Update installation at 00:15 and did not recover because the required host reboot was not performed.**

With the Broker Service stopped, `dc-vdi-02` stopped listening on port 80. All 22 Pool-02 machines that attempted re-registration after 00:15 received `connection refused` and transitioned to the `Unregistered` state. When users attempted session launches, the broker found zero available machines and returned error 1030.

The 3 machines that remained `Registered` had maintained continuous TCP sessions established before the service stopped and had not yet performed a re-registration cycle.

---

## 5. Five Whys analysis

| Why | Answer |
|---|---|
| **Why** did users fail to launch VDI sessions on Pool-02? | The Citrix Broker returned error 1030: no machines were available in the desktop group |
| **Why** were no machines available? | 22 of 25 Pool-02 machines were in the `Unregistered` state with the Delivery Controller |
| **Why** were the machines unregistered? | Machines could not contact `dc-vdi-02.finbridge.local:80` — they received `connection refused` on every registration attempt |
| **Why** was dc-vdi-02 refusing connections on port 80? | The Citrix Broker Service on dc-vdi-02 was stopped and not listening on that port |
| **Why** was the Citrix Broker Service stopped? | A Windows Update installed at 00:15 stopped the service as part of its installation process; the host was not rebooted, so the service did not recover and no alert was triggered |

**Underlying systemic cause:** Windows Updates are applied to Delivery Controllers without a defined maintenance window, without a post-update health verification step, and without a monitoring alert on the Broker Service state. The 6+ hour gap between the service stopping (00:15) and first user impact (08:58) indicates no automated detection was in place.

---

## 6. Remediation steps

### 6.1 Immediate resolution (in order)

| # | Step | Command / Action |
|---|---|---|
| 1 | Notify affected users | Send holding message via IT communications |
| 2 | RDP to dc-vdi-02 as administrator | Use jump server or management console |
| 3 | Attempt service start | `Start-Service CitrixBrokerService` |
| 4 | If service starts: monitor machine registration recovery | Pool-02 registered count should reach 25 within 5 minutes |
| 5 | If service fails to start: perform controlled reboot | `Restart-Computer -Force` (schedule with CAB if production hours) |
| 6 | Post-reboot: confirm service running | `Get-Service CitrixBrokerService` → Status: Running |
| 7 | Confirm all 25 Pool-02 machines registered | Citrix Studio → Pool-02 catalog |
| 8 | Run test session launch | Log in as a Pool-02 test user and launch desktop |
| 9 | Send all-clear to users | Close incident communications |

### 6.2 Post-resolution verification

```powershell
# --- On dc-vdi-02 ---
Get-Service CitrixBrokerService | Select-Object Status, StartType
# Expected: Status = Running, StartType = Automatic

# --- From Citrix Delivery Controller (PowerShell SDK) ---
Add-PSSnapin Citrix.*
Get-BrokerMachine -DesktopGroupName "FinBridge-VDI-Pool-02" |
  Group-Object RegistrationState |
  Select-Object Name, Count
# Expected: Registered = 25, Unregistered = 0

# --- End-to-end test ---
# Broker log should show successful session launch for a Pool-02 user
# No error 1030 entries after remediation
```

---

## 7. Preventive actions

| Priority | Action | Detail | Owner | Target date |
|---|---|---|---|---|
| P1 — Critical | Service health monitoring | Add alert: page on-call within 5 minutes if `CitrixBrokerService` stops on any Delivery Controller | Monitoring team | Immediate |
| P1 — Critical | Windows Update maintenance window | Restrict automatic update installation on all Delivery Controllers to an approved window (e.g., Saturday 02:00–04:00). Require manual approval outside the window | Infrastructure team | Within 1 week |
| P2 — High | Post-update health check | After any update installation, run automated check: if `CitrixBrokerService` is not Running within 2 minutes, trigger alert and attempt auto-restart | Automation/Monitoring | Within 2 weeks |
| P2 — High | Reboot workflow | Any update that sets reboot-required on a Delivery Controller must trigger a change request for a scheduled reboot within 24 hours. No Delivery Controller to remain in reboot-pending state overnight | Change management | Within 1 week |
| P3 — Medium | Runbook update | Add Delivery Controller update procedure to the DWP runbook: verify Broker Service status before and after every update, document reboot requirement handling | DWP team | Within 2 weeks |
| P3 — Medium | Staggered update rollout | Apply updates to dc-vdi-01 and dc-vdi-02 on different nights to ensure one controller is always available per pool | Infrastructure team | Within 1 month |

---

## 8. Lessons learned

1. **A 6-hour detection gap existed** between the service stopping (00:15) and first user impact (08:58). Monitoring on a critical service like the Citrix Broker Service was absent. Early detection would have enabled remediation before business hours.

2. **Windows Update on infrastructure components requires a post-install health gate.** Updating a Delivery Controller without verifying service recovery is an operational risk. The update process must include an automated health check step.

3. **The "reboot required" flag on a production host must be actioned immediately.** Leaving a Delivery Controller in a reboot-pending state overnight creates unpredictable service behaviour and should be treated as an open risk item.

4. **Single Delivery Controller per pool is a single point of failure.** Pool-02 had no resilience when dc-vdi-02 became unavailable. Consider assigning a secondary Delivery Controller to Pool-02 for high-availability.

---

## 9. Sign-off

| Role | Name | Date |
|---|---|---|
| Analyst | DWP Tier 2 | 2026-08-13 |
| Reviewer | | |
| Approver | | |
