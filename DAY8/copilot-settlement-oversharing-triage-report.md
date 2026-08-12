# Incident Triage Report — Copilot: Surfaced Draft Settlement from Unassigned Matter

**Ticket Reference:** DAY8-TRIAGE-003  
**Date:** 2026-08-12  
**Assigned Engineer:** DWP Support  
**Reporter:** Partner (Legal)  
**Severity:** High — Potential data governance/oversharing concern; requires immediate permissions review  

---

## Incident Summary

A partner reports that Copilot in Microsoft 365 surfaced and summarised a draft settlement document from a legal matter they are not assigned to. The user was not previously aware they could access the folder containing the document. This raises a data governance concern that must be investigated promptly to determine whether the access was legitimate (through group membership, inherited permissions, or historical assignment) or whether an oversharing configuration exists.

**Important:** Copilot does not bypass permissions. If it surfaced this content, the user's account has some form of access to it. This is not evidence of a Copilot fault — it may be evidence of a permissions configuration that has gone unnoticed.

---

## User Impact

- **Affected users:** 1 (reporting partner) — potentially broader if oversharing is confirmed
- **Affected workflow:** Matter confidentiality and legal privilege management
- **Business impact:** High — if permissions oversharing is confirmed, other partners or staff may have unintended access to sensitive settlement documents across matters
- **Data at risk:** Potentially — draft settlement documents carry legal privilege and matter confidentiality obligations; scope to be confirmed by permissions review

---

## Findings

| # | Observation | Significance |
|---|-------------|--------------|
| 1 | Copilot surfaced a draft settlement from a matter the partner is not assigned to | Copilot only surfaces content the signed-in user can access; user has some form of access |
| 2 | User was unaware they could see the folder | Suggests access was inherited, group-based, or assigned historically without the user's knowledge |
| 3 | Document is a draft settlement — legally sensitive and subject to privilege | High data governance and legal risk if access is broader than intended |
| 4 | No indication that the user sought out the document — Copilot proactively surfaced it | Copilot's semantic search made previously unnoticed access visible; this is a known effect of Copilot deployment |
| 5 | No evidence of a Copilot service fault or cross-tenant data leak | Standard Copilot behaviour within the user's permission boundary |
| 6 | Scope of oversharing not yet known | May be limited to this user or may affect a wider group through shared security group membership |

---

## Likely Cause Ranking

1. **Permissions/access boundary — oversharing via inherited or group-based permissions** *(most probable)*  
   The most common explanation for this scenario is that the user is a member of a security group, Microsoft 365 group, or SharePoint site group that has access to the matter folder — possibly due to a broad "all partners" or "all staff" group being added to a site at initial setup. The user never noticed because they never navigated to the folder manually; Copilot's semantic search made the access visible.

2. **Permissions/access boundary — historical access assignment** *(probable)*  
   The user may have been added to the matter at an earlier stage (e.g., during conflict checking, initial intake, or a prior involvement) and access was never revoked when they were removed from active assignment.

3. **Sensitivity label restriction** *(worth checking — as absence of a label is significant)*  
   If the draft settlement does not carry an appropriate sensitivity label (e.g., Confidential – Legal Privilege), label-based access controls will not restrict Copilot from surfacing it. The absence of a label on a highly sensitive document is itself a governance gap.

4. **Data indexing lag** *(not applicable)*  
   Not relevant — the document was successfully surfaced and summarised, confirming it is indexed and accessible.

5. **License/client prerequisite issue** *(not applicable)*  
   Copilot is functioning; this is not a licence issue.

6. **Guest/external sharing limitation** *(not applicable)*  
   The reporter is an internal partner; external sharing is not relevant.

7. **Genuine Copilot fault** *(last resort — not supported by evidence)*  
   Copilot is architecturally incapable of surfacing content a user cannot access. If the document appeared, access exists. A genuine fault would require evidence of cross-user or cross-tenant data exposure, which is not indicated here.

---

## Fastest Check

> **Check the SharePoint permissions on the matter folder containing the settlement document.**  
> Navigate to the SharePoint site → locate the folder → **Manage access** → review all permission levels, inherited permissions, and group memberships. Expand any groups to confirm whether the reporting partner's account is included — directly or through nested group membership.

This check takes 5–10 minutes and will immediately confirm whether the access is legitimate or a misconfiguration.

---

## Investigation Steps

1. **Identify the SharePoint site and folder path** — Confirm the exact location of the draft settlement document from the Copilot interaction (site name, library, folder).
2. **Review folder and document permissions** — Check direct permissions, inherited permissions from parent site/library, and all group memberships. Expand any security groups to check for the partner's account.
3. **Check site-level access** — Review the SharePoint site's members, owners, and visitors lists. Look for broad groups (e.g., "All Staff", "All Partners", "Legal Team") that may grant unintended access.
4. **Review access history** — If SharePoint audit logging is enabled, check the Unified Audit Log in the Microsoft Purview compliance portal for the partner's access events on the matter site.
5. **Check security group memberships** — In Azure Active Directory / Entra ID, review all groups the partner belongs to and cross-reference with groups that have permissions to the matter site.
6. **Check sensitivity label on the document** — Confirm whether the draft settlement has an appropriate sensitivity label applied. If not, escalate to the Information Governance team.
7. **Assess scope of oversharing** — Determine how many users share the same access path to this matter folder. If a broad group is responsible, assess which other matters may be similarly exposed.
8. **Review the Copilot interaction log** — If Microsoft Purview audit logging captures Copilot activity, review the interaction to confirm exactly what was surfaced and summarised.
9. **Notify Information Security and Legal** — Given the sensitivity of settlement documents, inform the Information Security team and the supervising partner for the matter immediately, pending findings.

---

## Root Cause

**Most probable root cause: Permissions oversharing through security group membership or inherited SharePoint permissions.**

Copilot behaved correctly — it surfaced content that the user's account has access to. The issue is not with Copilot but with the underlying permissions configuration. The partner's account has access to the matter folder through one of the following mechanisms:

- Membership of a broad security group (e.g., "All Partners") that was added to the SharePoint site at setup
- Inherited permissions from a parent site or library that was not scoped appropriately
- Historical access assignment that was not revoked when the partner was removed from the matter

Copilot's semantic search capability makes previously unnoticed access visible by proactively surfacing relevant content across everything the user can access. This is a documented effect of Microsoft 365 Copilot deployment and a key reason why permissions hygiene must be addressed before or alongside Copilot rollout.

---

## Business Risk Assessment

| Risk | Likelihood | Impact | Action |
|------|------------|--------|--------|
| Partner has unintended access to privileged settlement documents | High (pending confirmation) | High — legal privilege, matter confidentiality | Immediate permissions review and remediation |
| Other staff have the same unintended access via shared group | Medium | High — systemic oversharing across matters | Audit all group memberships with access to matter sites |
| Copilot has already summarised other sensitive documents for this user | Medium | High — information exposure without awareness | Review Copilot audit logs; consider targeted review |
| Settlement document lacks appropriate sensitivity label | Medium | Medium — label controls are a key defence | Escalate to Information Governance for labelling review |
| Wider matter sites are similarly misconfigured | Medium | High — systemic governance gap | Conduct SharePoint permissions audit across legal matter sites |

**Overall risk level: HIGH** — Requires prompt action regardless of whether the access is ultimately deemed legitimate.

---

## Recommended Resolution

**Immediate actions (within 24 hours):**
1. **Conduct SharePoint permissions review** on the matter site and the specific folder.
2. **Notify the supervising partner** for the matter and the Information Security team.
3. **Revoke unintended access** if confirmed — remove the user or the over-permissioned group from the matter site. Do not wait for a full audit before taking this step.
4. **Apply a sensitivity label** to the draft settlement and any other unlabelled privileged documents on the matter site.

**Short-term actions (within 1 week):**
5. **Audit group memberships** — Review all security groups with access to matter sites and remove broad groups that should not have blanket access to sensitive matter content.
6. **Review other matter sites** for the same pattern — a "break-glass" permissions review of all active matter SharePoint sites.
7. **Review Copilot audit logs** to determine whether other sensitive documents have been surfaced to users without expected access.

**Structural actions (within 1 month):**
8. **Implement a permissions governance model** for legal matter sites — matter-specific security groups with access managed through a defined joiners/leavers/movers process.
9. **Ensure all privileged documents carry appropriate sensitivity labels** to provide a secondary access control layer.
10. **Brief the legal team** on how Copilot surfaces content and the importance of permissions hygiene.

---

## Validation Steps

1. Confirm the permissions review has identified how the partner gained access.
2. Confirm unintended access has been revoked and the partner can no longer open the document directly in SharePoint.
3. Confirm Copilot no longer surfaces the settlement document to this user after access is removed.
4. Confirm a sensitivity label has been applied to the document.
5. Confirm the scope assessment is complete and no other users have the same unintended access path.
6. Close the ticket only after Information Security sign-off on the findings and remediation.

---

## Preventive Recommendations

- **Run a permissions audit before expanding Copilot access** — Copilot makes all accessible content visible through semantic search; oversharing that was previously invisible becomes immediately apparent.
- **Adopt a least-privilege model for SharePoint matter sites** — Access should be granted per matter, not via broad "all partners" or "all staff" groups.
- **Enforce sensitivity labelling on all legally privileged documents** — Labels provide a secondary enforcement layer independent of folder permissions.
- **Enable Microsoft Purview audit logging** for Copilot interactions — This allows retrospective review of what content Copilot has surfaced to which users.
- **Establish a regular permissions review cadence** for active matter sites — Quarterly reviews to remove stale or overly broad access assignments.
- **Provide user awareness training** on how Copilot works — Users should understand that Copilot will surface anything they can access, which reinforces the importance of reporting unexpected results (as this partner did).

---

## Triage Conclusion

**Is this actually a Copilot bug? No.**

Copilot surfaced content the user's account has permission to access. This is correct and expected behaviour. The issue is a permissions configuration problem — most likely oversharing through security group membership or inherited permissions — that Copilot has made visible. Copilot cannot access content beyond the user's existing permissions, and there is no evidence of a product fault.

**The partner should be commended for reporting this immediately.** Their prompt report has surfaced a potential governance gap that requires urgent review.

**Action required:** Immediate SharePoint permissions review; revocation of unintended access; sensitivity label application; broader permissions audit of matter sites.

---

*Report prepared by DWP Support Engineering | 2026-08-12*
