# Win11 Migration – Week 2 Feedback Comparison

**Analyst:** DWP Analyst  
**Date:** 2026-08-12  
**Source:** 40 FinBridge staff comments, week 2 post-migration  

---

## Summary

| Status | Theme | W1 Count | W2 Count | Movement |
|--------|-------|----------|----------|----------|
| Resolved | Account Lockout | 5 | 3 confirm fixed | ✅ Closed |
| Resolved | OneDrive Files Missing | 4 | 6 confirm fixed | ✅ Closed |
| Resolved | VPN Dropping | 4 | 3 confirm fixed | ✅ Closed |
| Resolved | Slow Login | 3 | 5 confirm fixed | ✅ Closed |
| Persisting | Floor 3 Printer Not Mapping | 6 | 10 | 🔴 Worsening — tone escalating |
| New | Excel Crashes on Large Files | — | 9 | 🆕 Blocker for Finance |

---

## Resolved

### Account Lockout
Three users explicitly confirmed lockouts have stopped. No new lockout reports in week 2. The fix applied after week 1 appears effective.
> *"Account lockouts have completely stopped, appreciate the fix."* (ID 19)

### OneDrive Files Missing
Six users confirmed files are back and sync is working. Zero new missing-file reports.
> *"Files all present, sync working as expected."* (ID 32)

### VPN Dropping
Three users confirmed VPN has been stable all week. No new drop reports.
> *"VPN has been rock solid this week, no complaints."* (ID 10)

### Slow Login / Login Speed
Five users confirmed login is back to normal speed.
> *"Login is back to normal now, thanks for the fix."* (ID 1)

---

## Persisting — Escalating

### Floor 3 Printer Not Mapping
**Week 2 count: 10 comments (up from 6 in week 1)**  
**Severity: Blocker**

This is now entering its third week unresolved. Comment volume has increased and the tone has shifted from frustration to open threats of manager escalation and resignation to the problem entirely.

Notable signals:
- *"Can someone just replace the thing at this point."* (ID 9)
- *"Genuinely considering escalating this to my manager."* (ID 28)
- *"Unresolved for two weeks running now, needs escalation."* (ID 40)
- The team has permanently adapted to using floor 2 — the workaround is becoming the norm.

**Action required:** This can no longer be treated as an ongoing ticket. It needs a dedicated engineer visit with a resolution deadline, or a replacement device approved today.

---

## New Issue

### Excel Crashes on Large Files
**Week 2 count: 9 comments**  
**Severity: Blocker**

A new theme not present in week 1. Nine users report Excel crashing or freezing when opening large spreadsheets, with one user identifying files over 10MB as the trigger. The Finance team is specifically named as affected, and users report losing unsaved work on each crash.

Notable signals:
- *"Excel crash is really disruptive, losing unsaved work each time."* (ID 13)
- *"Excel crashing has become a real productivity problem for finance team."* (ID 20)
- *"Happens specifically with files over 10MB."* (ID 33)

**Likely cause:** Memory or compatibility issue with the Win11 build — possibly a 32-bit vs 64-bit Office mismatch, or a missing Windows update. Needs investigation against the Finance team's machine configuration.

**Action required:** Raise as a new priority ticket. Collect affected usernames, file sizes, and Office version from the Finance team. Check if a patch or Office version change resolves it.
