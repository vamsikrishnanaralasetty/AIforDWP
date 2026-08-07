# AVD Incident Analysis - Ranked Hypotheses (POOL-FIN-01)

## Scope Facts Used
- Symptom: Black screen post-login; clears after ~30 seconds for some users, persists for others.
- Who: ~40% of users on POOL-FIN-01 affected.
- Control group: POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Change: Overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 was not updated.

## Most Consistent Clue
The strongest differentiator is update scope: only POOL-FIN-01 changed, and only POOL-FIN-01 is impacted.

## Re-ranked Likely Causes (Most Probable First)

### 1) Golden image regression in POOL-FIN-01
Why this fits:
- Direct temporal link: issue starts after the overnight update.
- Direct scope link: only the updated pool is affected; the non-updated pool is clean.
- Partial impact (~40%) is plausible if only a subset of hosts/sessions hit the regression path.

Fastest check:
- Correlate black-screen incidents to hosts/image version in POOL-FIN-01 and verify unaffected behavior on non-updated build.

### 2) FSLogix/profile attach behavior changed by the new image
Why this fits:
- Symptom is post-login black screen, consistent with profile attach delays/failures.
- Mixed behavior (30-second recovery for some, persistent for others) matches timeout/retry vs hard-failure patterns.
- Pool-specific timing aligns if image update altered profile-related components or timings.

Fastest check:
- On an affected POOL-FIN-01 host, review FSLogix logs during user sign-in for attach timeout/retry/access errors.

### 3) Logon-time policy/script/app provisioning delay introduced via updated image baseline
Why this fits:
- Pool-limited onset after update points to a baseline/configuration change in sign-in path.
- Variable duration aligns with policy/script/app provisioning contention at first logon.

Fastest check:
- Compare sign-in processing and applied logon items between one affected POOL-FIN-01 host and one unaffected POOL-FIN-02 host.

### 4) Subset of POOL-FIN-01 hosts unhealthy after update wave
Why this fits:
- 40% impact suggests host-subset concentration rather than tenant-wide failure.
- POOL-FIN-02 exclusion from update wave explains clean control group.

Fastest check:
- Map affected users to session hosts and check for clustering on a subset of recently updated hosts.

### 5) Graphics/render stack regression introduced in updated image
Why this fits:
- Black screen symptom can result from delayed desktop render initialization.
- Update-only impact and unaffected control pool remain consistent with image-scoped graphics regression.

Fastest check:
- Test one affected host with known-good display/acceleration settings and compare sign-in behavior immediately.

## Ranking Logic (Explicit Weighting)
1. Highest weight: differential update clue (POOL-FIN-01 updated, POOL-FIN-02 not updated, only updated pool affected).
2. Second weight: symptom phase (post-login black screen indicates shell/profile/logon pipeline).
3. Third weight: partial blast radius (~40%) suggests host/image-state variance, not broad identity outage.

## Position Statement
No single root cause is selected yet. This is a weighted hypothesis ranking for triage sequencing.

## Evidence Update (Event Logs 2024-03-15 07:00-07:30)

### Source Hosts
- Affected: SHFIN-01-A (POOL-FIN-01)
- Unaffected comparison: SHFIN-02-A (POOL-FIN-02, pre-update image)

### Key Events Observed (SHFIN-01-A)
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (FINBRIDGE\\mlopez, Session 3)
- 07:02:14 - Kernel-General Event 1: Host boot time 02:03:11 (post overnight update reboot)
- 07:02:16 - Application Error Event 1000: dwm.exe faulting in igdumd64.dll, exception 0xc0000005
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: Session disconnected (Session 3)
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited (0x40010004)
- 07:02:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (reconnect)
- 07:02:46 - Application Error Event 1000: dwm.exe faulting in igdumd64.dll (repeat)
- 07:02:47 - TerminalServices-LocalSessionManager Event 40: Session disconnected (repeat)
- 07:03:01 - Desktop Window Manager Event 9009: DWM exited (repeat)
- 07:03:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (second reconnect, Session 4)
- 07:08:24 - Application Error Event 1000: dwm.exe faulting in igdumd64.dll for another user context

### Comparison Events (SHFIN-02-A, unaffected)
- 07:01:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully
- No matching Application Error Event 1000 (dwm.exe/igdumd64.dll) in the incident window

## Hypothesis Elimination Result

### Surviving Hypothesis
Graphics/render stack regression introduced by the updated POOL-FIN-01 image, with DWM crashing in igdumd64.dll after session logon.

### Why It Survives
- Direct crash signal: Application Error Event 1000 repeatedly shows dwm.exe faulting in igdumd64.dll.
- Immediate symptom chain: logon success (Event 21) -> DWM crash (Event 1000/9009) -> session disconnect (Event 40).
- Scope alignment: affected pool was updated; unaffected pool was not updated and shows normal DWM startup (Event 9011).

## Resolution Plan (Detailed)

### 1) Immediate Containment
- Put affected POOL-FIN-01 hosts in drain mode to stop new impacted sessions.
- Route users to known-good capacity where available.
- Pause additional host provisioning from the current updated image.

### 2) Rapid Service Recovery
- Preferred: redeploy/reimage affected POOL-FIN-01 hosts from the last known-good image.
- Interim fallback: roll back/replace the Intel graphics driver package associated with igdumd64.dll crashes, then reboot hosts.
- Keep remediated hosts drained until validation passes.

### 3) Validation Gates Before Reopen
- Execute test logons with representative Finance users on remediated hosts.
- Confirm no recurrence of:
	- Application Error Event 1000 (dwm.exe / igdumd64.dll)
	- Desktop Window Manager Event 9009
	- Immediate post-logon disconnects (Event 40)
- Confirm normal comparison behavior equivalent to unaffected host pattern (DWM Event 9011 without crash events).

### 4) Controlled Reintroduction
- Remove drain mode host-by-host.
- Monitor incident signatures for at least 60-120 minutes.
- Re-drain any host showing renewed DWM/graphics crash sequence.

### 5) Permanent Corrective Actions
- Produce a corrected image with validated graphics/render stack.
- Introduce canary rollout ring before broad deployment.
- Add promotion guardrails: fail image promotion if post-logon DWM crash signature appears in validation window.
- Capture and publish RCA artifacts (timeline, impacted hosts, before/after event evidence, remediation trace).

## Addendum - Security Log Evidence Update (2024-03-15 08:44-09:12)

### Source
- Security Event Log: DESKTOP-FB022
- User context: FINBRIDGE\\cthompson

### Key Events Observed
- 08:44:01 - Event 4776 Audit Failure: credential validation failed, error 0xC000006A (wrong password)
- 08:44:03 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2 (interactive)
- 08:44:28 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2
- 08:44:55 - Event 4625 Audit Failure: unknown user name or bad password, logon type 2
- 08:44:56 - Event 4740 Audit Failure: account locked out
- 08:45:10 - Event 4625 Audit Failure: account locked out, logon type 7 (unlock attempt)
- 08:45:44 - Event 4771 Audit Failure: Kerberos pre-auth failed, failure code 0x18 (wrong password), source IP 10.10.8.112
- 08:46:01 - Event 4771 Audit Failure: Kerberos pre-auth failed, failure code 0x18, source IP 10.10.8.112
- 08:46:33 - Event 4771 Audit Failure: Kerberos pre-auth failed, failure code 0x18, source IP 10.10.8.112

### Elimination Outcome for This Evidence Set
- Contradicted by evidence:
	- Golden image regression in POOL-FIN-01
	- FSLogix/profile attach behavior changed by new image
	- Logon-time policy/script/app provisioning delay
	- Graphics/render stack regression
- Neutral (not directly proven by this dataset):
	- Subset of POOL-FIN-01 hosts unhealthy after update wave

### Surviving Hypothesis (from this elimination pass)
Subset of POOL-FIN-01 hosts unhealthy after update wave remained the only non-contradicted hypothesis in the original five, because this evidence set contains endpoint/identity lockout telemetry rather than AVD session-host health telemetry.

### Resolution Steps Applied for This Evidence Pattern
1. Restore user access:
- Confirm lockout state for FINBRIDGE\\cthompson.
- Unlock account and perform password reset.

2. Stop repeated bad-auth source(s):
- Identify and remediate source IP 10.10.8.112, which differs from DESKTOP-FB022.
- Remove stale credentials from endpoints and services (saved credentials, mapped drives, scheduled tasks, app sign-ins).

3. Validate clean sign-in:
- Test sign-in from DESKTOP-FB022 with updated credentials.
- Monitor for absence of new Event 4625, 4776, 4771, and 4740 during observation window.

4. Re-test AVD path:
- After successful authentication, validate login to POOL-FIN-01.
- If post-logon black screen recurs, branch back to session-host evidence collection and render-stack checks.
