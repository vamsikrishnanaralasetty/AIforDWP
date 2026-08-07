# Root Cause Analysis (RCA)

## Incident
- Title: AVD black screen post-login on Finance desktop pool
- Date: 2024-03-15
- Service: Azure Virtual Desktop (AVD)
- Affected pool: POOL-FIN-01
- Unaffected pool: POOL-FIN-02
- Incident status: Resolved
- Resolution verified at: 10:00

## Executive Summary
On 2024-03-15, Finance users experienced black screen behavior after successful AVD sign-in on POOL-FIN-01. Some sessions recovered after approximately 30 seconds, while others disconnected and retried. Approximately 40% of users in POOL-FIN-01 were affected. POOL-FIN-02 had no reported impact. Event evidence from affected hosts showed repeated Desktop Window Manager (DWM) crashes in the Intel graphics module igdumd64.dll immediately after successful session logon. The issue was resolved after applying the graphics/render mitigation path and recovering affected hosts. At 10:00, user verification confirmed successful logins on POOL-FIN-01 with no new issues reported.

## Business Impact
- User impact: Partial outage for Finance AVD sessions
- Scope: Approximately 40% of users in POOL-FIN-01
- Symptom: Black screen post-login; variable recovery; some disconnect/reconnect loops
- Business risk: Delayed start of work, repeated support calls, productivity disruption

## Scope and Change Correlation
- Start of user impact: Approximately 07:00
- Significant preceding change: Overnight image update to POOL-FIN-01 at 02:00
- Control comparison: POOL-FIN-02 was not updated and remained unaffected
- Correlation strength: High (time, scope, and symptom alignment)

## Supporting Evidence

### Affected Host Evidence (SHFIN-01-A)
- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded (FINBRIDGE\\mlopez, Session 3)
- 07:02:14 - Microsoft-Windows-Kernel-General, Event 1
  - Boot time 02:03:11 (host restarted after overnight update)
- 07:02:16 - Application Error, Event 1000 (Error)
  - Faulting app: dwm.exe
  - Faulting module: igdumd64.dll
  - Exception: 0xc0000005
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40
  - Session disconnected (Reason code 0)
- 07:02:18 - Desktop Window Manager, Event 9009 (Error)
  - DWM exited with code 0x40010004
- 07:02:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded (reconnect)
- 07:02:46 - Application Error, Event 1000 (Error)
  - Repeat dwm.exe fault in igdumd64.dll
- 07:02:47 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 40
  - Session disconnected again
- 07:03:01 - Desktop Window Manager, Event 9009 (Error)
  - Repeat DWM exit
- 07:03:10 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded (second reconnect, Session 4)
- 07:08:24 - Application Error, Event 1000 (Error)
  - Repeat dwm.exe/igdumd64.dll signature for another user context

### Unaffected Host Comparison (SHFIN-02-A, POOL-FIN-02)
- 07:01:44 - Microsoft-Windows-TerminalServices-LocalSessionManager, Event 21
  - Session logon succeeded
- 07:01:46 - Desktop Window Manager, Event 9011 (Information)
  - DWM started successfully
- No matching Application Error Event 1000 for dwm.exe/igdumd64.dll in the incident window

### Evidence Interpretation
- Authentication was successful (Event 21), then render stack failed (Event 1000 + Event 9009), followed by disconnects (Event 40).
- Failure pattern is post-login desktop composition/render, not primary identity failure.
- Pattern appears on updated pool host and not on non-updated control pool host.

## Timeline (All times local)
- 02:00 - Overnight image update initiated for POOL-FIN-01
- 02:03 - SHFIN-01-A rebooted after update (Kernel-General Event 1)
- Approximately 07:00 - First user symptoms reported on POOL-FIN-01
- 07:02 to 07:08 - Repeated DWM and igdumd64.dll crash/disconnect sequence captured on SHFIN-01-A
- 07:18 - Incident formally logged by Service Desk
- Morning triage window - Hypothesis ranking and evidence elimination performed
- Mitigation window - Graphics/render-focused remediation and affected host recovery actions applied
- 10:00 - Resolution verified: users logging into POOL-FIN-01 successfully, no new issues reported

## Root Cause
A graphics/render stack regression was introduced into the POOL-FIN-01 image update, causing dwm.exe to crash in igdumd64.dll during session initialization after successful user logon.

## Contributing Factors
- Update wave was applied to POOL-FIN-01 without prior production-like canary validation for this render path.
- No promotion guardrail detected repeated post-logon DWM crash signature before broad user exposure.
- Partial host/user impact delayed immediate pattern recognition as a pool-wide image defect.

## 5 Whys Analysis
1. Why did users see a black screen and disconnects after login?
   - Because Desktop Window Manager (DWM) failed during desktop composition, causing unstable or dropped sessions.
2. Why did DWM fail?
   - Because dwm.exe repeatedly crashed with Application Error Event 1000 in igdumd64.dll.
3. Why was the crashing graphics module present on affected hosts?
   - Because the overnight image update introduced a graphics/render stack state that was unstable for POOL-FIN-01 sessions.
4. Why did this reach production users?
   - Because the update wave lacked an effective canary gate focused on post-logon render stability signatures.
5. Why was the gate missing or insufficient?
   - Because release validation controls did not include a hard fail condition for DWM crash patterns (Event 1000 and Event 9009) in pilot logon tests.

## Resolution Actions Taken
- Contained blast radius by prioritizing affected host handling in POOL-FIN-01.
- Applied graphics/render remediation path and recovered impacted hosts.
- Validated successful logon behavior after remediation.
- Confirmed service restoration through user verification at 10:00.

## Preventive and Corrective Actions

### Immediate Hardening
- Add image promotion guardrail to fail deployment if any pilot host logs:
  - Application Error Event 1000 for dwm.exe with igdumd64.dll
  - Desktop Window Manager Event 9009 in post-logon validation window
- Require explicit sign-off on post-logon render test results before rollout expansion.

### Release Process Improvements
- Introduce phased rollout rings for AVD images:
  - Ring 0: lab validation
  - Ring 1: limited production canary host set
  - Ring 2: staged pool rollout
- Define automatic halt criteria for ring progression on render/session stability signals.

### Monitoring and Detection
- Create near-real-time alerting for spike conditions:
  - Event 1000 (dwm.exe)
  - Event 9009 (DWM exited)
  - Correlated Event 40 disconnects within 2 minutes of Event 21 logon
- Add pool-level health dashboard showing incident signatures by host and image version.

### Operational Readiness
- Maintain tested rollback playbook for image and graphics driver regressions.
- Keep known-good baseline image available for rapid redeploy.
- Run quarterly game-day simulation for AVD image rollback and host drain/recovery.

### Ownership and Due Dates
- AVD Platform Team: implement ringed deployment and promotion guardrails
- Endpoint Engineering: validate graphics driver compatibility matrix per image release
- Monitoring Team: publish event-correlation alerts and dashboard
- Service Desk Operations: update triage script to classify post-logon black screen signatures quickly
- Target completion: next release cycle (exact dates to be assigned in change board)

## Validation and Closure Evidence
- User verification at 10:00 confirmed successful logins to POOL-FIN-01.
- No further black screen incidents reported after mitigation in the verification window.
- Control pool remained stable throughout, supporting update-linked root cause isolation.

## Lessons Learned
- Differential pool updates with clean control pools provide high-confidence direction for fast hypothesis elimination.
- Post-logon black screen incidents require early review of DWM and graphics module crashes before deeper identity/profile escalation.
- Event-signature-based promotion gates can prevent recurrence from image regressions.
