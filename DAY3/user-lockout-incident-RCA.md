# User Lockout Incident RCA (DWP)

## Incident Summary
- Incident type: User account lockout during interactive sign-in attempts
- Affected user: jsmith
- Affected endpoint: DESKTOP-FB001
- Observation window: 08:02:14 to 08:23:44
- Outcome: Account access restored by helpdesk-admin, followed by successful user logon

## Event ID Reference (What Each Event Records)

### Event ID 4625 (Audit Failure)
- Meaning: Failed logon attempt.
- In this incident: Records failed sign-in attempts for jsmith.
- Failure reasons seen:
  - Unknown username or bad password
  - Account locked out
- Logon types seen:
  - Type 2: Interactive (local console sign-in)
  - Type 7: Unlock (unlocking an already logged-in workstation)

### Event ID 4740 (Audit Failure)
- Meaning: User account was locked out.
- In this incident: jsmith account lockout was triggered.
- Evidence includes caller/source host DESKTOP-FB001.

### Event ID 4722 (Audit Success)
- Meaning: User account was enabled.
- In this incident: FINBRIDGE\helpdesk-admin enabled jsmith account.
- Operational interpretation: Administrative recovery action was performed.

### Event ID 4624 (Audit Success)
- Meaning: Successful logon.
- In this incident: jsmith successfully signed in after administrative action.

## Reconstructed Sequence of Events (Plain English)
1. At 08:02:14, jsmith attempted an interactive sign-in on DESKTOP-FB001 and failed due to bad credentials (4625, type 2).
2. At 08:04:22, another interactive sign-in failed for the same reason (4625, type 2).
3. At 08:06:01, the account reached lockout threshold and was locked (4740), with DESKTOP-FB001 as caller.
4. At 08:07:45, a further unlock attempt failed because the account was already locked (4625, type 7).
5. At 08:22:10, FINBRIDGE\helpdesk-admin performed an administrative enable action on the account (4722).
6. At 08:23:44, jsmith successfully logged on interactively (4624, type 2).

## Most Likely Cause of Lockout (With Evidence)
Most likely cause: Repeated incorrect password entry by the user at the local workstation, causing threshold-based account lockout.

Evidence:
- Two explicit bad-password failures before lockout:
  - 08:02:14, Event 4625, failure reason Unknown username or bad password, type 2
  - 08:04:22, Event 4625, failure reason Unknown username or bad password, type 2
- Lockout event occurs shortly after:
  - 08:06:01, Event 4740, account locked out, caller DESKTOP-FB001
- Post-lockout attempt confirms lock state:
  - 08:07:45, Event 4625, failure reason Account locked out, type 7
- Recovery and success confirm no persistent platform outage:
  - 08:22:10, Event 4722 by helpdesk-admin
  - 08:23:44, Event 4624 successful logon

## Root Cause Analysis (5 Whys)

### Problem Statement
jsmith was locked out of their machine and could not authenticate until helpdesk intervention.

### Why 1
Why was jsmith locked out?
- Because the account exceeded failed logon threshold and lockout policy was enforced.
- Evidence: Event 4740 at 08:06:01.

### Why 2
Why did the failed logon threshold get exceeded?
- Because multiple interactive logon attempts used invalid credentials.
- Evidence: Event 4625 at 08:02:14 and 08:04:22 with bad password reason.

### Why 3
Why were invalid credentials entered repeatedly?
- Most likely user-side credential mismatch (mistyped password, stale remembered password, keyboard layout issue, or outdated cached expectation).
- Evidence: Same endpoint as source and interactive logon type, indicating local user session attempts, not service/system logons.

### Why 4
Why was self-recovery not immediate?
- Because once policy lockout occurred, additional attempts were blocked until admin intervention.
- Evidence: Event 4625 at 08:07:45 shows Account locked out, then later helpdesk admin action at 08:22:10.

### Why 5
Why did support action include account enable before successful login?
- Account state required administrative correction before user could proceed, likely due local/domain policy workflow or manual recovery process.
- Evidence: Event 4722 by FINBRIDGE\helpdesk-admin followed by Event 4624 success.

### Root Cause
Primary root cause: Repeated bad-password interactive sign-in attempts on DESKTOP-FB001 triggered account lockout policy.
Contributing factors: Lack of immediate user awareness of credential mismatch and reliance on helpdesk for account state recovery.

## Corrective and Preventive Actions
1. User guidance
- Confirm correct username format and current password before repeated attempts.
- Verify keyboard layout and Caps Lock state at sign-in screen.

2. Endpoint checks
- Confirm no stale cached credentials for mapped resources, VPN clients, or credential manager entries tied to old password.
- Validate lock/unlock workflow prompts user clearly after first failed attempts.

3. Support process
- Add first-line playbook step to review Security events 4625, 4740, 4722, 4624 in sequence before reset/enable actions.
- Capture source host and logon type each time for faster diagnosis.

4. Policy and monitoring
- Review lockout threshold and reset window for balance between security and usability.
- Alert on repeated 4625 bursts from the same endpoint before lockout to enable proactive assistance.

## Confidence and Limitations
- Confidence: High for lockout sequence and immediate trigger.
- Limitation: No direct user action recording (for example, exact keystrokes) in event logs; human-factor causes are inferred from standard authentication behavior.
