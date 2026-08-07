# RDP Connection Failure Incident RCA (DWP)

## Incident Summary
- Incident type: Failed Remote Desktop (RDP) authentication attempts followed by account lockout and later successful access.
- Affected account: FINBRIDGE\bwalker
- Source client IP: 10.10.5.44
- Observation window: 2024-03-15 14:01:02 to 14:22:09
- Log sources reviewed: System and Security
- Primary incident pattern: Repeated bad-credential RemoteInteractive logons (type 10), lockout event, later successful reconnection.

## Impact Assessment
- User impact:
1. User unable to establish RDP session during failed-attempt window.
2. Account became locked, preventing continued authentication until lockout condition was cleared/expired or administratively resolved.

- Service impact:
1. No evidence of sustained RDP service outage from provided events.
2. Later successful TCP connection and successful logon indicate service availability recovered/continued.

- Business impact:
1. Temporary productivity interruption for the affected user.
2. Potential Service Desk workload increase due to lockout recovery and password/authentication support.

- Severity assessment:
1. Proposed severity: Sev3 (single-user authentication disruption).
2. Escalate to Sev2 if multiple users or hosts show same pattern concurrently.

## Event ID Analysis

### Event ID 56 (System, Source: TermDD, Error)
- What the event records:
1. Terminal Server security layer detected a protocol stream error and disconnected the client.

- Status classification:
1. Failure (Error level).

- Significance to this incident:
1. Indicates connection/session establishment was interrupted at security/protocol handling stage.
2. Occurs at the same timestamp as credential failure warning (Event 140), suggesting the failed handshake/authentication path for that attempt.

- Caution:
1. Exact protocol sub-cause (for example TLS/NLA negotiation nuance) is not fully determinable from this single event text alone.
2. Verification against Microsoft documentation is required before asserting specific protocol defect details.

### Event ID 140 (System, Source: RemoteDesktopServices-RdpCoreTS, Warning)
- What the event records:
1. RDP connection from 10.10.5.44 failed because username or password was not correct.

- Status classification:
1. Warning that reflects an authentication failure condition.

- Significance to this incident:
1. Directly ties the failed RDP attempt to credential mismatch for the source client.
2. Correlates with subsequent Security 4625 failed logon entries.

### Event ID 4625 (Security, Audit Failure)
- What the event records:
1. Failed logon attempt.
2. In this incident: Logon type 10 (RemoteInteractive) with failure reason "Unknown username or bad password".

- Status classification:
1. Failure (Audit Failure).

- Significance to this incident:
1. This is the primary evidence of repeated bad-credential RDP authentication attempts.
2. Repetition at 14:01:04, 14:03:18, and 14:05:33 supports lockout-threshold trigger conditions.

### Event ID 4740 (Security, Audit Failure)
- What the event records:
1. User account was locked out.
2. Caller/source identified as 10.10.5.44.

- Status classification:
1. Failure (Audit Failure) from user access perspective.

- Significance to this incident:
1. Confirms failed-attempt threshold was reached and account lockout policy enforced.
2. Provides strong causal link between repeated 4625 failures and lockout.

### Event ID 131 (System, Source: RemoteDesktopServices-RdpCoreTS, Information)
- What the event records:
1. Server accepted a new TCP connection from client 10.10.5.44:52341.

- Status classification:
1. Success/Informational for network-layer connection acceptance.

- Significance to this incident:
1. Indicates RDP listener/network path was functioning at this timestamp.
2. Supports conclusion that incident was not a persistent network transport outage.

### Event ID 4624 (Security, Audit Success)
- What the event records:
1. Successful logon.
2. In this incident: Logon type 10 (RemoteInteractive) for FINBRIDGE\bwalker from 10.10.5.44.

- Status classification:
1. Success (Audit Success).

- Significance to this incident:
1. Confirms eventual successful authentication and access restoration.
2. Supports interpretation that root issue was credential/lockout state, not sustained RDP service failure.

## Timeline of Events
1. 14:01:02 - Event 56: TermDD logs protocol stream error; client disconnected (10.10.5.44).
2. 14:01:02 - Event 140: RDPCoreTS logs failed connection due to incorrect username/password (10.10.5.44).
3. 14:01:04 - Event 4625: Failed RemoteInteractive logon for FINBRIDGE\bwalker (bad username/password).
4. 14:03:18 - Event 4625: Second failed RemoteInteractive logon for FINBRIDGE\bwalker (bad username/password).
5. 14:05:33 - Event 4625: Third failed RemoteInteractive logon for FINBRIDGE\bwalker (bad username/password).
6. 14:05:34 - Event 4740: FINBRIDGE\bwalker account locked out; caller 10.10.5.44.
7. 14:22:07 - Event 131: Server accepts new TCP connection from 10.10.5.44:52341.
8. 14:22:09 - Event 4624: Successful RemoteInteractive logon for FINBRIDGE\bwalker from 10.10.5.44.

## Technical Findings
1. Distinct Event IDs present: 56, 140, 4625, 4740, 131, 4624.
2. Authentication failure pattern is explicit and repeated (three 4625 entries with same reason and source IP).
3. Account lockout occurred immediately after repeated failures (4740 one second after third 4625).
4. Later connection and logon success indicate endpoint/service remained capable of RDP access.
5. Event 56 indicates protocol/security-layer disconnect but is not, by itself, sufficient to prove independent infrastructure defect.

## Root Cause
Most likely root cause: Repeated invalid credentials for FINBRIDGE\bwalker during RDP (logon type 10) from client 10.10.5.44 triggered account lockout policy, causing connection failure until credentials/account state were corrected.

## Contributing Factors
1. Account lockout threshold policy converted repeated failed attempts into enforced lockout.
2. Possible stale saved credentials on the RDP client (Credential Manager or cached `.rdp` settings).
3. Possible user-entry issues (mistyped password, keyboard layout/Caps Lock differences).
4. Potential initial protocol/security-layer disconnect signal (Event 56) increased failed-attempt noise, but not proven as a separate root defect.

## Evidence
1. Event 140 (14:01:02): explicit username/password incorrect message from RDPCoreTS.
2. Event 4625 (14:01:04, 14:03:18, 14:05:33): repeated failed logons for same account, logon type 10, same source IP.
3. Event 4740 (14:05:34): account lockout for same account and caller 10.10.5.44.
4. Event 131 (14:22:07) and Event 4624 (14:22:09): accepted connection and successful RemoteInteractive logon from same source IP.

## Corrective Actions
Ranked remediation plan (most likely fix first):

1. Validate and correct user credentials
- Reset/unlock account if required per policy.
- Confirm user enters correct domain format and current password.
- Force fresh credential entry in RDP client.

2. Clear stale RDP cached credentials on source client 10.10.5.44
- Remove saved credentials from Windows Credential Manager.
- Remove/refresh cached `.rdp` profile entries.

3. Verify account lockout policy and lockout state handling
- Confirm lockout threshold, duration, and reset counter settings match security baseline.
- Confirm account unlocked/expired lockout before retry.

4. Validate RDP/NLA configuration consistency
- Confirm server/client security settings are baseline compliant.
- Review whether Event 56 repeats after credential correction.

5. Investigate for automated retry sources
- Check scheduled tasks, services, mapped resources, or scripts using old credentials from 10.10.5.44.

6. Deep diagnostics if failures persist
- Correlate additional TermDD/Schannel/LSA events during failures.
- Capture RDP operational logs and network trace for protocol-level investigation.

## Preventive Actions
1. Implement user guidance for credential hygiene before repeated retries.
2. Add Service Desk playbook step to correlate 140/4625/4740 quickly before network escalation.
3. Alert on repeated 4625 (logon type 10) bursts per account/source IP to preempt lockout.
4. Standardize periodic cleanup checks for stale stored credentials on managed endpoints.
5. Validate lockout policy balance between security and usability (threshold/duration).
6. Document a known-error pattern for "RDP bad password -> lockout -> post-unlock success".

## 5 Why Analysis
Problem statement: FINBRIDGE\bwalker could not complete RDP login and account became locked.

Why 1: Why did RDP fail initially?
- Because authentication attempts used incorrect credentials.
- Evidence: Event 140 and Event 4625 (bad username or password).

Why 2: Why did incorrect-credential failures continue?
- Because additional RemoteInteractive attempts were made from the same source without successful credential correction.
- Evidence: Three 4625 failures from 10.10.5.44.

Why 3: Why was access fully blocked?
- Because lockout threshold was reached and account lockout policy enforced.
- Evidence: Event 4740 immediately after third failure.

Why 4: Why did access later succeed?
- Because by 14:22:09 the account state and credential conditions were valid again.
- Evidence: Event 4624 success following Event 131 accepted TCP connection.

Why 5: Why was this incident not prevented earlier?
- Because proactive detection and first-line guidance for repeated 4625 logon type 10 attempts likely did not interrupt the retry loop before lockout.
- Evidence: Multiple failures occurred before successful recovery window.

## Lessons Learned
1. Security Event 4625 + 4740 provides strong lockout RCA path when correlated with source IP and logon type.
2. RDP transport acceptance (Event 131) and authentication success (4624) help rule out persistent server/network outage.
3. Early Service Desk intervention after first 1-2 failures can prevent lockout and reduce downtime.
4. Event 56 should be treated as contextual unless repeated and corroborated by additional protocol/security logs.

## Verification Steps

Operational verification after remediation:
1. Confirm no new Event 4625 for FINBRIDGE\bwalker from 10.10.5.44 during retest window.
2. Confirm no new Event 4740 lockout entries for account during retest window.
3. Confirm expected sequence on success path: Event 131 followed by Event 4624 (logon type 10).
4. Confirm user can establish and maintain RDP session without disconnection.

Items that must be verified against Microsoft documentation (do not assume):
1. Precise semantic scope of TermDD Event 56 for protocol stream errors and typical root-cause categories.
2. Authoritative mapping of RDPCoreTS Event 140 wording to authentication pipeline stages.
3. Current Microsoft guidance on Security Event 4740 interpretation in hybrid AD scenarios.
4. Official recommendations for lockout threshold tuning and RDP authentication hardening.
5. Any OS-version-specific behavior differences for RDP-related Event IDs 56, 131, and 140.

## Assumptions
1. All provided events are from the same target server and are complete for the incident window.
2. Time synchronization is accurate across System and Security logs.
3. No additional identity provider events (for example ADFS, Entra, smartcard auth logs) are required to interpret this sequence.
4. FINBRIDGE\bwalker is a domain account subject to domain/local lockout policy.
5. Source IP 10.10.5.44 represents the same client/user activity across all listed events.

## Plain-English Sequence for Service Desk
1. The user at 10.10.5.44 tried to RDP in, but the credentials were rejected.
2. The same user/account retried several times with bad credentials.
3. After repeated failures, the account lockout policy triggered and locked the account.
4. Later, a new RDP connection from the same client was accepted and the login succeeded, which means RDP service/network were available and the earlier issue was mainly authentication and lockout related.
