# Root Cause Analysis (RCA)

## Incident
- Title: AVD login failure due to account lockout (user-specific)
- Date: 2024-03-15
- Service context: AVD access attempt from endpoint DESKTOP-FB022
- Affected user: FINBRIDGE\cthompson
- Incident status: Resolved
- Resolution verified at: 09:09

## Executive Summary
On 2024-03-15, user FINBRIDGE\cthompson was unable to log in due to repeated bad credential attempts that resulted in account lockout. Security logs show multiple wrong-password failures, lockout, and continued Kerberos pre-auth failures from a second source IP. The account was enabled by helpdesk and successful interactive login was verified at 09:09, with no further issues reported.

## User Impact
- Impact type: Single-user login outage
- User-visible symptom: Login failures and account lockout during sign-in attempts
- Business impact: Access interruption until account restoration and credential source cleanup

## Supporting Evidence

### Failure Evidence (Security Log, DESKTOP-FB022, 08:44-09:12)
- 08:44:01 - Event 4776 (Audit Failure)
  - Domain credential validation failed
  - Account: FINBRIDGE\cthompson
  - Error code: 0xC000006A (wrong password)
- 08:44:03 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022
- 08:44:28 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type: 2
- 08:44:55 - Event 4625 (Audit Failure)
  - Unknown user name or bad password
  - Logon type: 2
- 08:44:56 - Event 4740 (Audit Failure)
  - Account locked out
  - Account: FINBRIDGE\cthompson
  - Caller computer: DESKTOP-FB022
- 08:45:10 - Event 4625 (Audit Failure)
  - Failure reason: Account locked out
  - Logon type: 7 (Unlock attempt)
- 08:45:44 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112
- 08:46:01 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18
  - Source IP: 10.10.8.112
- 08:46:33 - Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed
  - Failure code: 0x18
  - Source IP: 10.10.8.112

### Recovery Evidence
- 09:08:14 - Event 4722 (Audit Success)
  - User account enabled
  - Account: FINBRIDGE\cthompson
  - Performed by: FINBRIDGE\helpdesk-admin
- 09:09:01 - Event 4624 (Audit Success)
  - Account successfully logged on
  - Account: FINBRIDGE\cthompson
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022
- Verification statement: User confirmed logging in to host successfully; no issues reported after restoration.

## Timeline (Local Time)
- 08:44:01 - First wrong-password validation failure observed (4776)
- 08:44:03 to 08:44:55 - Repeated interactive bad-password failures (4625)
- 08:44:56 - Account lockout triggered (4740)
- 08:45:10 - Locked-out login attempt recorded (4625, logon type 7)
- 08:45:44 to 08:46:33 - Continued wrong-password Kerberos pre-auth failures from 10.10.8.112 (4771)
- 09:08:14 - Helpdesk enabled account (4722)
- 09:09:01 - Successful interactive login (4624)
- 09:09 - Resolution confirmed by user, no further issues reported

## Root Cause
Repeated invalid credential attempts for FINBRIDGE\cthompson caused account lockout, preventing successful login until account restoration.

## Contributing Factors
- Multiple consecutive incorrect password attempts from DESKTOP-FB022.
- Additional incorrect Kerberos pre-authentication attempts from a separate source IP (10.10.8.112), indicating another stale credential source.

## 5 Whys Analysis
1. Why could the user not log in?
   - Because the account became locked out after repeated failed authentication attempts.
2. Why did authentication keep failing?
   - Because wrong passwords were submitted multiple times (4776, 4625, 4771 evidence).
3. Why did failures continue after lockout?
   - Because attempts continued from at least one additional source (10.10.8.112), not only the interactive workstation.
4. Why did this become a user-visible outage?
   - Because lockout state blocked all successful sign-in attempts until helpdesk intervention.
5. Why was intervention required to restore service?
   - Because account enable/unlock and credential correction were necessary to end the failure loop and allow a successful login.

## Resolution Actions Taken
- Identified lockout pattern using Security event evidence.
- Helpdesk re-enabled the affected account (Event 4722).
- User sign-in retested and validated successful (Event 4624 at 09:09:01).
- User confirmed login to host and stable access after remediation.

## Preventive and Corrective Actions

### Immediate Prevention
- Investigate and remediate stale credential source at 10.10.8.112.
- Clear saved/cached credentials associated with FINBRIDGE\cthompson on known source systems.

### Detection and Monitoring
- Add alerting for rapid sequence pattern:
  - Event 4776 wrong password
  - Multiple Event 4625 failures
  - Event 4740 lockout
  - Repeated Event 4771 from alternate source IPs
- Add correlation rule to highlight multi-source bad-password behavior for the same account.

### Process Improvements
- Update service desk triage runbook to classify this pattern as identity lockout first, before AVD session-host investigation.
- Require lockout-source validation checklist before closing similar incidents.

## Closure Evidence
- Event 4722 at 09:08:14 confirms account restoration action.
- Event 4624 at 09:09:01 confirms successful interactive sign-in.
- User verification confirms host login success and no further issues reported.
