# AVD Incident Communications - Three Audiences (Fact-Aligned)

## Audience 1 - Non-technical executive
Your access is restored and your data is safe. On 15 Mar, after a 02:00 update to Finance desktop pool POOL-FIN-01, about 40% of users saw a black screen after sign-in from around 07:00, while POOL-FIN-02 was unaffected. The issue was fixed, and by 10:00 users were logging in normally with no new reports. No action is needed unless the issue returns.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access is restored and your data is safe. On 15 Mar, after a 02:00 update to Finance desktop pool POOL-FIN-01, about 40% of users saw a black screen after sign-in from around 07:00, while POOL-FIN-02 was unaffected; we fixed this and by 10:00 users were logging in normally with no new reports. If you see the same symptom again, take a screenshot with the time and contact FinBridge Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access is restored and data is safe. Incident date 2024-03-15: after the 02:00 image update to POOL-FIN-01 only, approximately 40% of POOL-FIN-01 users hit black screen post-logon from approximately 07:00; POOL-FIN-02 (not updated) remained unaffected. Service verified restored at 10:00 with successful POOL-FIN-01 logons and no further reports.

Root cause:
- Graphics/render stack regression in updated POOL-FIN-01 image.
- DWM crash signature: dwm.exe faulting in igdumd64.dll (Application Error Event 1000), followed by DWM exit (Event 9009) and session disconnect (LSM Event 40) after successful logon (LSM Event 21).

Config details and evidence anchors:
- Affected host: SHFIN-01-A (POOL-FIN-01).
- Update-reboot evidence: Kernel-General Event 1 at 07:02:14 reports boot time 02:03:11.
- Crash chain examples:
  - 07:02:10 Event 21 (logon success) -> 07:02:16 Event 1000 (dwm.exe/igdumd64.dll) -> 07:02:17 Event 40 (disconnect) -> 07:02:18 Event 9009 (DWM exit).
  - Repeats at 07:02:46/07:02:47/07:03:01.
- Control host: SHFIN-02-A (POOL-FIN-02) shows Event 9011 (DWM started successfully) and no matching Event 1000 in window.

Exact action taken:
- Contained affected POOL-FIN-01 hosts and routed around impact where possible.
- Applied graphics/render mitigation path and recovered impacted hosts.
- Reopened capacity in controlled fashion after validation.

Verification step:
- Post-remediation user logons to POOL-FIN-01 succeeded.
- No recurring Event 1000 (dwm.exe/igdumd64.dll), Event 9009, or immediate Event 40 disconnect pattern in verification window.
- User confirmation at 10:00: normal login behavior, no new issues reported.

Preventive action needed:
- Add image promotion guardrail: block rollout on pilot if Event 1000 (dwm.exe/igdumd64.dll) or Event 9009 appears post-logon.
- Enforce ringed rollout (lab -> canary -> staged pool) with automatic halt criteria.
- Add correlated alerting for Event 1000 + 9009 + near-term Event 40 after Event 21.
- Maintain tested rollback path and known-good baseline image for rapid redeploy.
