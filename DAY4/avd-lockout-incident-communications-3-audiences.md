# AVD Lockout Incident Communications - Three Audiences (Fact-Aligned)

## Audience 1 - Non-technical executive
Your access is restored and your data is safe. On 15 Mar, repeated incorrect password attempts for FINBRIDGE\cthompson from DESKTOP-FB022 and another source (10.10.8.112) locked the account. Helpdesk re-enabled the account at 09:08:14, and sign-in succeeded at 09:09:01 from DESKTOP-FB022. The user confirmed host access and no further issues were reported. No action is needed unless this happens again.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access is restored and your data is safe. On 15 Mar, repeated incorrect password attempts for FINBRIDGE\cthompson from DESKTOP-FB022 and another source (10.10.8.112) locked the account, then Helpdesk re-enabled it at 09:08:14 and login succeeded at 09:09:01 from DESKTOP-FB022, with host access confirmed and no further issues reported. If you see the same issue, contact FinBridge Service Desk and report the time it happened. Contact: FinBridge Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access is restored and data is safe.

Root cause:
- Repeated invalid credential attempts for FINBRIDGE\cthompson caused account lockout.
- Attempts came from DESKTOP-FB022 and an additional source 10.10.8.112.

Exact action taken:
- Security evidence reviewed for lockout sequence.
- Account re-enabled by FINBRIDGE\helpdesk-admin at 09:08:14 (Event 4722).
- Sign-in retested and succeeded at 09:09:01 from DESKTOP-FB022 (Event 4624).
- User confirmed successful host login and no further issues.

Config detail:
- Date: 2024-03-15.
- Endpoint: DESKTOP-FB022.
- Account: FINBRIDGE\cthompson.
- Secondary failure source: 10.10.8.112.

Verification step:
- Positive recovery evidence: Event 4722 at 09:08:14 followed by Event 4624 at 09:09:01.
- User confirmation: host login works, no new issues reported.

Preventive action needed:
- Investigate and remediate stale credential source at 10.10.8.112.
- Clear saved or cached credentials tied to FINBRIDGE\cthompson on known source systems.
- Add correlation alerting for 4776 plus repeated 4625 plus 4740 plus repeated 4771 from alternate sources.
- Update service desk runbook to route this pattern as identity lockout first.
