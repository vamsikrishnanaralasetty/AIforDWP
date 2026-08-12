# Win11 Migration – Post-Migration Feedback: Top 3 Priority Actions

**Analyst:** DWP Analyst  
**Date:** 2026-08-12  
**Source:** 50 FinBridge staff comments post-Win11 migration  

---

## Ranking Rationale

Severity is the primary sort key. Within the same severity tier, volume and consequence break the tie. A theme with a known workaround is demoted below a same-severity theme with none.

| Rank | Theme | Count | Severity | Workaround exists? | Notes |
|------|-------|-------|----------|--------------------|-------|
| 1 | Account Lockout | 5 | Blocker | No | Complete access denial; repeated = systemic fault |
| 2 | OneDrive Files Missing / Sync Error | 4 | Blocker | No | Data-loss risk; highest consequence if wrong |
| 3 | Floor 3 Printer Not Mapping | 6 | Blocker | Yes (floor 2) | High volume but partial workaround exists |
| — | Shared Drive (S:) Access Denied | 3 | Blocker | No | Close #4; financial data blocked |
| — | AVD Login Failure | 2 | Blocker | No | Low volume, investigate alongside lockouts |
| — | VPN Dropping / Instability | 4 | Friction | Partial | Reconnect possible; disrupts but not total stop |
| — | Desktop & App Discoverability | 5 | Friction | Yes | Self-recoverable |

---

## Top 3 Priority Themes

### #1 — Account Lockout
**Count:** 5 comments | **Severity:** Blocker

**Why it ranks #1:**  
A locked-out user has zero access to any system — no workaround exists. Five separate users are affected, with one locked out three times in a single week and another locked out immediately before a client call. Repeated lockouts for the same individuals rule out user error and point to a systemic policy misconfiguration (e.g., failed-attempt threshold or password policy incorrectly applied during migration). Despite having slightly lower volume than the printer issue, this ranks first because the impact is total and there is no partial workaround.

**Manager summary:**  
> Five users are being repeatedly locked out of their accounts post-migration with no workaround — the recurrence pattern strongly suggests a policy misconfiguration that needs same-day resolution before more staff lose access.

---

### #2 — OneDrive Files Missing / Sync Error
**Count:** 4 comments | **Severity:** Blocker

**Why it ranks #2:**  
Data loss risk places this above higher-volume Blockers that have workarounds. Even if files are intact server-side and the issue is a sync or profile-mapping error, users cannot distinguish that from genuine data loss — and four are already alarmed, two with explicit same-day deadlines. Leaving this unresolved past end of business risks an escalation to a formal data-loss incident regardless of the actual root cause.

**Manager summary:**  
> Four users cannot find their OneDrive files post-migration, two of them have same-day deadlines, and we need to rule out actual data loss today before this becomes a formal data-loss incident.

---

### #3 — Floor 3 Printer Not Mapping
**Count:** 6 comments | **Severity:** Blocker

**Why it ranks #3:**  
Highest comment volume of any theme, unresolved for three consecutive days, and affecting an entire floor team rather than isolated individuals. It ranks third — not first — because a workaround exists: users are walking to floor 2 to print. That partial workaround prevents it from being a total-access blocker. It remains a same-day action because the workaround is unsustainable and a client meeting has already been flagged.

**Manager summary:**  
> The entire floor 3 team has been unable to map the printer for three days since migration, and staff are now walking to another floor to print client documents — this needs an engineer on-site today.

---

*Themes identified from 50 post-migration feedback comments. Full theme list available in session analysis.*
