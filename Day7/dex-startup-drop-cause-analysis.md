# DEX Startup Performance Drop — Cause Analysis

**Analyst:** DWP Analyst  
**Date:** 2026-08-12  
**Device group:** Finance-Win11 (215 devices)  
**Metric:** Median startup time / DEX score  

---

## Scope Facts (Established)

- **Affected group:** Finance-Win11, 215 devices
- **Change deployed:** 2026-08-04 at 02:00 — security baseline configuration profile pushed to Finance-Win11 only (startup compliance logging script + additional Defender scan policy)
- **Score drop:** 84 → 61 (−23 points); startup time 17.5 sec → 41.3 sec (+23.8 sec, +136%)
- **Degradation persists:** Days 2 and 3 post-change show no recovery (59, 60)
- **Comparison group:** IT-Win11 (40 devices, no config change) — startup times stable at 16.8–17.1 sec, scores 84–85 across the same period. No external factor can account for the Finance-Win11 drop.

---

## Ranked Causes

---

### #1 — Startup Compliance Logging Script Running Synchronously

**Why it fits the evidence:**  
The startup script is the first of the two deployed components and the most direct mechanism to delay login. If the script executes synchronously — meaning the system waits for it to finish before releasing the desktop — it would add exactly the duration the script takes to run, every time, for every user in the group. This explains the consistent delay: 41.3, 43.8, 42.1 seconds across three days is a narrow, stable range, which is characteristic of a deterministic blocking process rather than a variable one like a scan. The timing is exact (first occurrence the morning after the 02:00 deployment), and IT-Win11 — which received no script — shows zero impact. No external factor is needed to explain it.

**Fastest check:**  
On a single affected Finance-Win11 device, temporarily remove the startup script from the policy (or move it to run asynchronously in a test policy). Measure startup time before and after. If startup returns to ~18 sec, the script is the cause. Also review the script source to confirm whether it is configured as a synchronous startup script in Group Policy.

---

### #2 — Additional Defender Scan Policy Triggering an I/O-Intensive Scan at Login

**Why it fits the evidence:**  
The second component deployed was an additional Defender scan policy. Defender policies that schedule or trigger scans at system startup or user login are a known cause of degraded startup performance, particularly on devices where the user's profile or working directory is large. The impact would be felt only by Finance-Win11 (the only group that received the policy), and the comparison group's stability rules out a platform-level Defender update as a confounding factor. The slight day-to-day variation in startup time (41.3 → 43.8 → 42.1 sec) is consistent with scan duration varying based on the number of files changed since the last scan.

**Fastest check:**  
On an affected device, open Windows Security → Protection History and check for scan activity timestamped within the startup window (within 5 minutes of login). Cross-reference with Task Scheduler for any Defender-related tasks set to trigger at login or system start. Compare CPU and disk utilisation at login on an affected device vs a comparison group device using Performance Monitor or Task Manager logs.

---

### #3 — Compliance Script Making a Blocking Network Call That Times Out

**Why it fits the evidence:**  
If the compliance logging script sends data to a remote endpoint (e.g., a SIEM, a compliance log server, or a cloud API) and that endpoint is slow to respond or unreachable from the Finance network segment, the script will wait for the network timeout before completing. Network timeouts are typically fixed values (e.g., 30 seconds), which would produce a consistent, repeatable delay — matching the stable ~24-second addition seen across all three post-change days. This is a subset of cause #1 (the script is still the mechanism) but the root fix would be different: not removing the script, but fixing the network path or making the call asynchronous. It ranks third because it requires an additional failure (network issue) on top of the config change, whereas causes #1 and #2 require no secondary failure.

**Fastest check:**  
Run the startup script manually from an elevated PowerShell prompt on an affected device while capturing a network trace (e.g., `netsh trace start`). Look for outbound connection attempts, their destination, and whether they succeed or time out. Check the script source for any `-TimeoutSec` parameters, `Invoke-WebRequest`, `Invoke-RestMethod`, or WMI/CIM remote calls.

---

## Next Step

Confirm or eliminate cause #1 first — it requires the least effort (review the script source and test disabling it on one device) and is the highest-probability explanation. If startup time recovers to baseline on the test device, causes #2 and #3 can be deprioritised.
