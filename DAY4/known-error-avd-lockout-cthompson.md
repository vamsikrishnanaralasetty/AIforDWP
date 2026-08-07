Symptom     : The user could not log in and experienced repeated sign-in failures. The account became locked out during login attempts.

Cause       : Repeated invalid credential attempts for FINBRIDGE\cthompson caused account lockout. Security evidence also showed continued wrong-password Kerberos pre-authentication attempts from source IP 10.10.8.112.

Scope       : This incident affected one user account, FINBRIDGE\cthompson. The observed systems in evidence were DESKTOP-FB022 and source IP 10.10.8.112 in the 2024-03-15 incident window.

Workaround  : Re-enable the locked account and retest user sign-in from DESKTOP-FB022. This restoration path was verified by Event 4722 at 09:08:14 followed by successful Event 4624 at 09:09:01.

Permanent fix: Remediate the stale credential source at 10.10.8.112 and clear saved or cached credentials tied to FINBRIDGE\cthompson on known source systems. Add correlation alerting for the lockout sequence pattern documented in this incident.

How to spot it: Look for Event 4776 with error 0xC000006A (wrong password), repeated Event 4625 failures, then Event 4740 account lockout. Confirm continued failures with Event 4771 failure code 0x18 from alternate source IPs, and confirm recovery with Event 4722 then Event 4624.
