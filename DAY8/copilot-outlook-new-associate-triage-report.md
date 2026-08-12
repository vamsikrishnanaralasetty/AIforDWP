# Incident Triage Report — Copilot in Outlook: Cannot Find Case Emails (New Associate)

**Ticket Reference:** DAY8-TRIAGE-002  
**Date:** 2026-08-12  
**Assigned Engineer:** DWP Support  
**Reporter:** New Associate (started this week)  
**Severity:** Low — Single user, expected behaviour for new account  

---

## Incident Summary

A new associate who joined this week reports that Copilot in Outlook cannot find any of the case emails they need context on. The user started employment recently, meaning their Microsoft 365 account is newly provisioned. Copilot returned no relevant results when asked to surface case-related email content.

---

## User Impact

- **Affected users:** 1 (new associate)
- **Affected workflow:** Case email review and context gathering via Copilot in Outlook
- **Business impact:** Minor productivity delay during onboarding; user cannot leverage Copilot to get up to speed on cases
- **Data at risk:** None — no data loss or exposure

---

## Findings

| # | Observation | Significance |
|---|-------------|--------------|
| 1 | User started this week | Account is newly provisioned; mailbox history is minimal or absent |
| 2 | Cannot find "any" case emails | Suggests a systemic gap rather than a missing individual email |
| 3 | Case emails may have been sent before the user's account existed | User cannot have received emails sent prior to their mailbox being created |
| 4 | No mention of errors — just no results returned | Consistent with indexing lag or empty mailbox, not a hard fault |
| 5 | No indication of wider Copilot outage or other users affected | Isolated to this new account |
| 6 | Outlook client readiness and licence assignment not confirmed | Both must be verified for a newly provisioned account |

---

## Likely Cause Ranking

1. **Data indexing lag** *(most probable)*  
   Microsoft 365 Search (which underpins Copilot) requires time to index a newly provisioned mailbox. For new accounts, full indexing can take 24–72 hours. Until indexing completes, Copilot will be unable to find email content even if it exists in the mailbox.

2. **License/client prerequisite issue** *(highly probable — must verify)*  
   Copilot for Microsoft 365 licences are assigned separately from standard M365 licences. New starters may receive their base licence before the Copilot add-on is assigned. Additionally, Copilot in Outlook requires a supported Outlook client version (Microsoft 365 Apps for Enterprise, Current Channel). Both must be confirmed.

3. **Permissions/access boundary** *(possible)*  
   Case emails the user needs context on may be in shared mailboxes, team inboxes, or distribution group histories that the user has not yet been granted access to. Copilot cannot surface content from mailboxes the user is not authorised to access.

4. **Sensitivity label restriction** *(possible)*  
   Case emails may carry sensitivity labels (e.g., Confidential – Legal) that restrict Copilot's ability to process them, particularly if the user has not been added to the permitted group for that label scope.

5. **Guest/external sharing limitation** *(not applicable)*  
   The reporter is an internal new starter; this cause is not relevant.

6. **Genuine Copilot fault** *(last resort — not supported by evidence)*  
   All observable symptoms are fully explained by the new-account provisioning state. There is no evidence of a Copilot service fault.

---

## Fastest Check

> **Confirm the Copilot for Microsoft 365 licence is assigned to the user's account.**  
> In the Microsoft 365 Admin Center → **Users** → select the user → **Licences and apps** → verify that **Microsoft Copilot for Microsoft 365** is listed and toggled on.

This single check takes under two minutes and immediately confirms whether Copilot is even enabled for the account.

---

## Investigation Steps

1. **Verify Copilot licence assignment** — Microsoft 365 Admin Center → Users → Licences and apps → confirm Copilot for Microsoft 365 is active.
2. **Check mailbox provisioning state** — Confirm the Exchange Online mailbox is fully provisioned and active (not in a pending or soft-deleted state).
3. **Check Microsoft Search indexing status** — In the Microsoft 365 Admin Center or via the Search & Intelligence admin portal, review whether the mailbox has completed initial indexing. For new accounts, allow 24–72 hours.
4. **Confirm Outlook client version** — Verify the user is running Microsoft 365 Apps for Enterprise on a supported channel (Current Channel or Monthly Enterprise Channel). Copilot is not available in legacy Outlook or Outlook 2019/2021.
5. **Check whether case emails exist in the mailbox** — Ask the user whether the case emails were forwarded or added to their mailbox, or whether they are in a shared mailbox/team inbox. If the latter, confirm the user has delegate or member access.
6. **Check sensitivity labels on case emails** — If the emails exist and the user has access, check Microsoft Purview for any label policy that would restrict Copilot processing.
7. **Reproduce the issue** — Ask the user to attempt a specific Copilot prompt (e.g., *"Summarise recent emails about [case name]"*) and capture the exact response or screenshot.
8. **Check for service incidents** — Review the Microsoft 365 Service Health Dashboard for any active Copilot or Exchange Online incidents.

---

## Root Cause

**Primary root cause: Data indexing lag for a newly provisioned account.**  
Microsoft 365 Search indexes mailbox content after account provisioning. For a user who joined this week, the mailbox may not yet be fully indexed, meaning Copilot has no searchable content to draw on even if emails have been delivered.

**Contributing factor: Possible Copilot licence assignment gap.**  
New starters frequently receive base M365 licences before Copilot add-on licences are assigned. If the licence has not been applied, Copilot features will not function regardless of mailbox state.

**Additional contributing factor: Limited mailbox history.**  
Case emails sent before the user's account was created cannot exist in their personal mailbox. If the user expects to access historical case correspondence, they will need access to a shared mailbox, team inbox, or will need those emails forwarded to them — and Copilot will only be able to use content once it has been indexed.

---

## Recommended Resolution

1. **Confirm and assign Copilot licence** if not already active.
2. **Allow 24–72 hours** from account provisioning for Microsoft 365 Search to complete initial mailbox indexing.
3. **Grant shared mailbox access** if historical case emails reside in a team or case inbox — and ensure that mailbox is also indexed and accessible.
4. **Ask the user to open and interact with key emails** — Manually opening emails can accelerate their appearance in the search index.
5. **Advise the user to retry Copilot** after the indexing window has passed and confirm the experience improves.
6. **If the issue persists beyond 72 hours** with licence confirmed and mailbox active, escalate to Microsoft Support with tenant diagnostics.

---

## Validation Steps

1. Confirm Copilot for Microsoft 365 licence shows as active in the Admin Center.
2. Confirm the mailbox is fully provisioned and receiving email.
3. After the 24–72 hour indexing window, ask the user to retry a Copilot prompt referencing a specific case email.
4. Confirm Copilot returns relevant results.
5. If shared mailbox access was granted, confirm Copilot can also surface content from that mailbox.
6. Close the ticket only after the user confirms Copilot is finding case emails successfully.

---

## Triage Conclusion

**Is this actually a Copilot bug? No.**

The symptoms are entirely consistent with the expected behaviour of a newly provisioned Microsoft 365 account: minimal mailbox history, incomplete search indexing, and a potentially unassigned Copilot licence. Copilot is operating within its documented constraints. No evidence supports a product fault.

**Action required:** Verify licence assignment; allow the indexing window to complete; grant shared mailbox access if historical case emails are required.

---

*Report prepared by DWP Support Engineering | 2026-08-12*
