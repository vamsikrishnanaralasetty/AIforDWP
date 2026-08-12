# Incident Triage Report — Copilot: "I don't have access to that content"

**Ticket Reference:** DAY8-TRIAGE-001  
**Date:** 2026-08-12  
**Assigned Engineer:** DWP Support  
**Reporter:** Paralegal (Finance/Legal)  
**Severity:** Low — Single user, no data loss  

---

## Incident Summary

A paralegal asked Microsoft 365 Copilot to summarise a client NDA stored in SharePoint. Copilot returned the message: *"I don't have access to that content."* The user had never opened or navigated to the folder containing the file; she became aware of its existence through a meeting conversation.

---

## User Impact

- **Affected users:** 1 (paralegal)
- **Affected workflow:** Legal document review / NDA summarisation via Copilot
- **Business impact:** Minor delay; user cannot use Copilot to accelerate document review
- **Data at risk:** None — Copilot correctly enforced an access boundary

---

## Findings

| # | Observation | Significance |
|---|-------------|--------------|
| 1 | User has never opened or navigated to the folder | Indicates she may never have been granted explicit permissions |
| 2 | User learned of the file only through a meeting | No evidence of a formal share or permission grant |
| 3 | Copilot returned an access error, not a content error | Consistent with a permissions/access boundary, not a Copilot fault |
| 4 | File is a client NDA — likely stored in a restricted legal folder | High probability of sensitivity label or permission-scoped access |
| 5 | No indication of a Copilot service incident or widespread complaints | Isolated to this user and this document |

---

## Likely Cause Ranking

1. **Permissions/access boundary** *(most probable)*  
   The user has never accessed the folder and was not formally granted access. SharePoint permissions have not been assigned to her account for that library or folder. Copilot respects SharePoint permissions and will not surface content the user cannot already access.

2. **Sensitivity label restriction** *(possible)*  
   If the NDA carries a sensitivity label (e.g., Confidential – Legal) that restricts access to a defined group, Copilot will be blocked even if the user inadvertently has read rights elsewhere.

3. **Data indexing lag** *(lower probability)*  
   If the file was recently created or moved, Microsoft Search may not have indexed it yet, causing Copilot to be unable to locate it. However, the error message "I don't have access" points to a permissions block rather than an indexing gap.

4. **License/client prerequisite issue** *(unlikely)*  
   If the user lacks a Copilot for Microsoft 365 licence or the licence was recently assigned and not fully propagated, some features may be limited. Given Copilot is otherwise functional for the user, this is low probability.

5. **Guest/external sharing limitation** *(not applicable here)*  
   Not relevant — the reporter appears to be an internal user.

6. **Genuine Copilot fault** *(last resort — not supported by evidence)*  
   The error is consistent with a standard permissions response. There is no indication of a Copilot service fault.

---

## Fastest Check

> **Verify SharePoint permissions on the target folder.**  
> Navigate to the SharePoint library → select the folder → click **Manage access** → confirm whether the paralegal's account (or a group she belongs to) has any permission level assigned.

This single check will confirm or rule out the most probable cause in under two minutes.

---

## Investigation Steps

1. **Identify the SharePoint site and folder path** — Ask the user for the URL or site name and folder name mentioned in the meeting.
2. **Check folder permissions** — In SharePoint, go to the folder → **⋮ (ellipsis)** → **Manage access** → review direct permissions and group memberships.
3. **Check site-level permissions** — Verify whether the paralegal has been granted access at the site or library level that would inherit to the folder.
4. **Check sensitivity labels** — In the Microsoft Purview compliance portal, confirm whether the document carries a label that restricts access to a named group (e.g., Legal team only).
5. **Check Copilot licence** — In the Microsoft 365 Admin Center, confirm the user has an active Copilot for Microsoft 365 licence.
6. **Check Microsoft Search indexing** — If permissions are confirmed as correct, use the SharePoint Search diagnostics or wait 24–48 hours for indexing to complete, then retry.
7. **Reproduce the error** — If permissions are granted and indexing has completed, ask the user to retry and capture the exact error text or a screenshot.

---

## Root Cause

**Primary root cause: Permissions/access boundary.**  
The paralegal does not have SharePoint permissions to the folder containing the client NDA. Microsoft 365 Copilot uses the same permission model as Microsoft Search and SharePoint — it cannot surface, read, or summarise content that the signed-in user is not already authorised to access. Hearing about a file in a meeting does not grant access to it.

A secondary contributing factor may be a sensitivity label restricting the document to legal team members only, which would reinforce the permissions block even if access were partially granted.

---

## Recommended Resolution

1. **If the user legitimately needs access:**  
   - The document owner or SharePoint site admin should grant the paralegal the appropriate permission level (at minimum: **Read**) on the folder or document.
   - If a sensitivity label is applied, the label policy owner (typically the Information Security or Legal team) must add the user to the permitted group.

2. **Once access is granted:**  
   - Ask the user to open the document directly in SharePoint or Word Online first — this confirms permissions are working and triggers indexing.
   - Wait up to 24 hours for Microsoft Search to index the newly accessible content.
   - The user can then retry the Copilot summarisation request.

3. **If the user should NOT have access:**  
   - Inform the user that the document is restricted and they should contact their line manager or the document owner to request access through the appropriate process.
   - No further action required on the Copilot/IT side.

---

## Validation Steps

1. Confirm the paralegal can open the document directly in SharePoint without error.
2. Confirm the sensitivity label (if present) does not block the user.
3. Ask the user to retry: *"Summarise the NDA located at [SharePoint URL]"* in Copilot.
4. Confirm Copilot returns a summary rather than an access error.
5. Close the ticket only after the user confirms successful access.

---

## Triage Conclusion

**Is this actually a Copilot bug? No.**

Copilot behaved correctly. It returned an access error because the user does not have SharePoint permissions to the file in question. This is expected behaviour — Copilot cannot and should not bypass access controls. The resolution path is a SharePoint permissions grant, not a Copilot fix.

**Action required:** SharePoint admin or document owner to review and grant appropriate access if the user is entitled to it.

---

*Report prepared by DWP Support Engineering | 2026-08-12*
