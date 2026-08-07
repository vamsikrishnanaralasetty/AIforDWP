# Triage Summary — VDI Connection Failure (Remote / Home WiFi)

*Analyst note: Produced under Personal AI Usage Charter — no real PII or device identifiers used.*

---

## Summary
User unable to connect to VDI (Virtual Desktop Infrastructure) from home via WiFi today; connection was working on Friday.

---

## Impact
- **Who:** Single end-user (identity: to confirm)
- **How many affected:** 1 confirmed; unknown whether other remote users are affected — to confirm via service monitoring or recent call volume
- **Business urgency:** High — user is fully locked out of their working environment and cannot perform any desk-based tasks remotely. Escalate immediately if no office fallback is available.

---

## Known Facts
- User is working from home on a personal or corporate WiFi connection
- VDI connection was working successfully on Friday (last known good state)
- Error message presented: "cannot connect" (exact error string / error code: to confirm)
- Issue started today (exact time: to confirm)
- VDI platform assumed to be AVD (Azure Virtual Desktop) — to confirm

---

## Missing Information to Gather
- [ ] Full name and staff ID of affected user
- [ ] Device hostname / asset tag and OS (corporate laptop or personal device?)
- [ ] Exact error message or error code displayed
- [ ] Which client being used to connect — AVD web browser, Windows Desktop client, or other?
- [ ] Has the device been restarted since the issue started?
- [ ] Is the user able to reach other internet sites/services (confirms general connectivity)?
- [ ] Is VPN required before connecting to VDI, and if so is VPN connecting successfully?
- [ ] Has anything changed over the weekend — Windows Update, password expiry, MFA re-enrolment prompt?
- [ ] Is the user's account showing any lockout or conditional access block (to confirm via Azure AD / Entra portal)?
- [ ] Are other remote users reporting the same issue today (to confirm via service desk queue)?

---

## Likely Category
**Remote Access / Virtual Desktop — Connectivity Failure**
Sub-category: Post-weekend remote access break (possible MFA expiry, Conditional Access policy, VPN issue, or client update required)

---

## Suggested First Diagnostic Step
Ask the user to open a browser and navigate to **https://aka.ms/AVDweb** (or the DWP-specific AVD web portal URL — to confirm):
1. If the web client also fails to connect, this points to an **account, Conditional Access, or backend service issue** — check Entra sign-in logs for the user
2. If the web client connects successfully, the issue is **local to the installed AVD client** — advise user to check for client updates or reinstall
3. Simultaneously confirm whether VPN is required and if it is up — ask user to check VPN status before any other step
