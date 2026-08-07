# Triage Summary — Laptop Slow / Outlook Not Launching

*Analyst note: Produced under Personal AI Usage Charter — no real PII or device identifiers used.*

---

## Summary
User reports new Win11 laptop running slowly since this morning with Outlook failing to open (spinning), while other applications appear unaffected.

---

## Impact
- **Who:** Single end-user (identity: to confirm)
- **How many affected:** 1 confirmed; wider impact unknown — to confirm whether other users on same Win11 rollout batch are affected
- **Business urgency:** Medium — user cannot access email; productivity impacted but not a full system outage. Escalate to High if user is on call-handling or time-sensitive business role (to confirm)

---

## Known Facts
- Device is a newly provisioned Windows 11 machine (deployed within the last week)
- Slowness onset: this morning (exact time to confirm)
- Outlook fails to launch — application hangs/spins at startup
- Other applications reported as "OK" by user (not independently verified)
- Device is part of a recent Win11 rollout batch

---

## Missing Information to Gather
- [ ] Full name and staff ID of affected user
- [ ] Device hostname / asset tag
- [ ] Exact time slowness started — any specific trigger (e.g. Windows Update, login, resume from sleep)?
- [ ] Has the device been restarted since the issue started?
- [ ] Is the device joined to the domain / Entra ID and is VPN/network connectivity confirmed?
- [ ] Which version of Outlook (classic M365, new Outlook, or web)?
- [ ] Is the Outlook profile new or migrated from previous device?
- [ ] Are background processes or high CPU/RAM visible in Task Manager?
- [ ] Has any Windows Update or Intune policy applied overnight (to confirm via Intune portal)?
- [ ] Are other users from the same Win11 deployment batch reporting similar issues?

---

## Likely Category
**Desktop / Endpoint — Application Performance**
Sub-category: New device post-deployment issue (possible Intune policy/profile sync, Windows Update side-effect, or Outlook profile corruption)

---

## Suggested First Diagnostic Step
Ask the user to open **Task Manager** (`Ctrl + Shift + Esc`) and report:
1. CPU and RAM usage percentages
2. Any process consuming >30% CPU (particularly `MsMpEng.exe` / Defender, `SearchIndexer.exe`, or `OUTLOOK.EXE`)

This will immediately distinguish between a system-wide resource problem (e.g. Defender initial scan on new device, Windows Update in background) and an Outlook-specific process hang, and determine the next diagnostic path without requiring remote access.
