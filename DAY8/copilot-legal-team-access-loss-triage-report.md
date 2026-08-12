# Incident Triage Report — Copilot: Entire Legal Department Lost Access (40 Users)

**Ticket Reference:** DAY8-TRIAGE-004  
**Date:** 2026-08-12  
**Assigned Engineer:** DWP Support  
**Reporter:** Legal Ops Manager  
**Severity:** P1 — Critical; entire department affected, simultaneous loss of service  

---

## Incident Summary

All 40 members of the Legal team lost access to Microsoft 365 Copilot simultaneously this morning. Copilot was functioning normally for all affected users throughout the previous week. The sudden, simultaneous, department-wide nature of the outage is a strong indicator of a platform-level configuration change, licensing event, or service incident rather than individual user issues. No single-user cause can account for 40 simultaneous failures.

---

## User Impact

- **Affected users:** 40 (entire Legal department)
- **Affected workflow:** All Copilot-assisted tasks across the Legal team — document drafting, email summarisation, case research, matter management
- **Business impact:** High — complete loss of Copilot productivity tooling for a department handling legally sensitive, time-critical work
- **Duration:** Confirmed since this morning; prior week was unaffected
- **Data at risk:** None — this is a loss-of-service incident, not a data exposure incident

---

## Findings

| # | Observation | Significance |
|---|-------------|--------------|
| 1 | All 40 Legal team members affected simultaneously | Rules out individual user issues; points to a group-level or service-level change |
| 2 | Copilot was working normally for all users throughout the previous week | Confirms Copilot was correctly provisioned; something changed recently |
| 3 | Sudden onset this morning | Consistent with a scheduled licensing change, automated group policy update, conditional access policy modification, or a Microsoft service incident |
| 4 | No partial failure reported — all 40 users lost access | Suggests a shared dependency (e.g., a licensing group, Entra ID group, or tenant-level setting) rather than gradual drift |
| 5 | No mention of individual error messages | Needs clarification — error type (licence error, authentication failure, feature unavailable) would narrow the cause quickly |
| 6 | No other M365 services reported as affected | If only Copilot is impacted, a Copilot-specific licence removal or service incident is more likely than a broad authentication failure |

---

## Likely Cause Ranking

1. **License/client prerequisite issue — group-based licence assignment change** *(most probable)*  
   If Legal team members receive their Copilot for Microsoft 365 licence via an Entra ID group-based licensing assignment, any change to that group — removal of members, group deletion, licence plan modification, or licence cap being reached — would remove Copilot access for all members simultaneously. A scheduled or automated change overnight is the most likely trigger.

2. **License/client prerequisite issue — tenant-level licence change** *(highly probable)*  
   A licence purchase expiry, a subscription plan change, or an admin removing or reassigning Copilot licence seats at the tenant level could remove access for an entire assigned group at once.

3. **Permissions/access boundary — Entra ID group membership change** *(probable)*  
   If a conditional access policy, group-based access rule, or application permission policy governing Copilot access was modified (e.g., the Legal group was removed from a permitted group for the Copilot application), all 40 users would lose access simultaneously.

4. **Data indexing lag** *(not applicable)*  
   Not relevant — this is a loss of access, not a failure to find content.

5. **Sensitivity label restriction** *(not applicable)*  
   Sensitivity labels affect content access, not Copilot service availability.

6. **Guest/external sharing limitation** *(not applicable)*  
   All affected users are internal; not relevant.

7. **Genuine Copilot fault / Microsoft service incident** *(possible — must check)*  
   A Microsoft 365 service incident affecting Copilot for a specific tenant or region could explain simultaneous loss of access. This should be checked via the Service Health Dashboard in parallel with licence investigation. However, a Microsoft-side service incident affecting only one department within one tenant is less likely than a configuration change.

---

## Fastest Check

> **Check the Microsoft 365 Service Health Dashboard for active Copilot incidents, then immediately check the Entra ID group used for Copilot licence assignment.**  
> Admin Center → **Health** → **Service health** → filter for **Microsoft Copilot** — confirm whether there is an active incident.  
> Then: Admin Center → **Billing** → **Licences** → **Microsoft Copilot for Microsoft 365** → confirm how many licences are assigned and to which groups or users.

These two checks together take under five minutes and will immediately distinguish between a Microsoft service incident and a local configuration/licensing change.

---

## Investigation Steps

1. **Check Microsoft 365 Service Health Dashboard** — Admin Center → Health → Service health → filter for Microsoft Copilot and Microsoft 365 Apps. Check for active incidents, advisories, or degraded service status.

2. **Check the Microsoft 365 Admin Center — Copilot licence assignments** — Billing → Licences → Microsoft Copilot for Microsoft 365 → confirm total assigned seats, available seats, and which groups or users are assigned. Check whether the Legal team's licences are still showing as assigned.

3. **Check Entra ID group-based licensing** — Azure Active Directory / Entra ID → Groups → locate the group used for Copilot licence assignment → Members → confirm all 40 Legal team members are still present. Check the group's licence assignments under Licences.

4. **Review the Entra ID audit log** — Entra ID → Monitoring → Audit logs → filter for the past 24 hours → look for group membership changes, licence assignment changes, or policy modifications affecting the Legal team or Copilot licensing group.

5. **Check Microsoft 365 Admin Center audit log** — Compliance or Admin Center → Audit log search → filter for licence-related activity in the past 24 hours.

6. **Check conditional access policies** — Entra ID → Security → Conditional access → review any policies that govern access to Microsoft 365 Copilot or Microsoft 365 Apps. Look for recent policy changes, new exclusions, or group changes that took effect this morning.

7. **Check tenant-level Copilot settings** — Microsoft 365 Admin Center → Copilot settings → confirm Copilot is enabled at the tenant level and that no organisation-level toggle has been changed.

8. **Collect an error message from an affected user** — Ask one user to attempt to access Copilot and capture the exact error message or screenshot. The error type (e.g., "You don't have a licence for this feature" vs "Something went wrong") will help narrow the cause.

9. **Check for any scheduled changes or change management records** — Contact the M365 admin team to confirm whether any planned changes (licence reallocation, group policy update, tenant configuration) were applied overnight or this morning.

10. **Test with a single user remediation** — If a licensing group change is suspected, attempt to manually assign a Copilot licence directly to one affected user and confirm whether access is restored. This validates the licence theory without waiting for a full group remediation.

---

## Root Cause

**Most probable root cause: Group-based licence assignment change.**

The simultaneous, department-wide loss of Copilot access following a period of normal operation is most consistent with a change to the Entra ID group used to assign Copilot for Microsoft 365 licences to the Legal team. This could have been caused by:

- Removal of Legal team members from the licensing group (manually or via an automated rule)
- Deletion or modification of the licensing group itself
- Licence seat count reduction leaving insufficient seats for the assigned group
- A subscription renewal failure or plan change removing the Copilot add-on

A Microsoft service incident is a secondary possibility that must be ruled out in parallel via the Service Health Dashboard.

Root cause confirmation requires completion of investigation steps 1–5 above.

---

## Business Impact Assessment

| Dimension | Assessment |
|-----------|------------|
| Productivity loss | High — 40 legal professionals without Copilot for an unknown duration; document drafting, email management, and research tasks slowed |
| Time sensitivity | High — legal work is often deadline-driven; matter deadlines and client commitments may be at risk |
| Reputational risk | Low to Medium — internal service disruption; no client-facing exposure unless matter deadlines are missed |
| Data risk | None — this is a service availability issue, not a data exposure event |
| Escalation requirement | Yes — P1 severity; requires immediate admin action and, if a Microsoft service incident, a Microsoft support case |
| Estimated impact duration | Unknown — hours if a configuration fix; potentially longer if a Microsoft service incident |

---

## Recommended Resolution

**Immediate actions (within the hour):**
1. **Check Service Health** — If an active Microsoft incident is confirmed, raise a Microsoft support case and monitor for updates. Share the incident reference with the Legal Ops Manager.
2. **Check licence assignments** — If licences have been removed from the group, re-add them immediately. If the group has been modified, restore its membership.
3. **Re-assign licences if needed** — If group-based assignment is the cause, either restore the group or temporarily assign licences directly to affected users while the group is investigated.
4. **Communicate to the Legal team** — Send an update within the hour confirming the issue is under investigation and providing an estimated resolution window.

**Short-term actions (within the day):**
5. **Confirm root cause** — Complete the full investigation steps and document the change that caused the outage.
6. **Restore full access** — Ensure all 40 users have Copilot access restored and confirmed.
7. **Post-incident review** — Identify who or what made the change that caused the outage.

**Structural actions (within 1 week):**
8. **Implement change management controls** for licence assignment group modifications — changes to groups that affect service access should require approval and notification.
9. **Set up licence monitoring alerts** — Configure alerts in the Microsoft 365 Admin Center or a monitoring tool to notify the team if Copilot licence assignments drop below expected thresholds.
10. **Document the Copilot licensing architecture** — Ensure the groups, policies, and licence assignments for Copilot are documented so the team can respond quickly to future incidents.

---

## Validation Steps

1. Confirm at least one affected user can access and use Copilot successfully after remediation.
2. Confirm all 40 Legal team members have Copilot access restored — do not close the incident after testing with a single user.
3. Confirm the Copilot licence assignment group is correctly configured and all members are present.
4. Ask the Legal Ops Manager to confirm the team is fully operational.
5. Monitor the Service Health Dashboard for the following 24 hours for any related advisories.
6. Close the incident only after full-team confirmation and root cause documented.

---

## Preventive Recommendations

- **Implement change management approval for licence group modifications** — Any change to groups used for Copilot or other critical service licence assignments should require documented approval and advance notification.
- **Configure licence threshold alerts** — Set up automated alerts if assigned Copilot licences fall below the expected number for the Legal team.
- **Conduct regular licence assignment audits** — Monthly review of group-based licence assignments to catch unintended changes before they cause outages.
- **Subscribe to Microsoft 365 Service Health notifications** — Ensure IT leadership and service desk receive email or webhook alerts for Copilot service incidents so response time is minimised.
- **Document the Copilot licence architecture** — Maintain a record of which groups control Copilot access for each department, reviewed quarterly.
- **Test licence changes in a staging group** — Before modifying any group used for production licence assignment, validate the change against a small test group first.

---

## Triage Conclusion

**Is this actually a Copilot bug? Unclear — service incident must be ruled out, but configuration change is more probable.**

The simultaneous, department-wide loss of access following normal operation is not consistent with a product bug affecting a single department within a single tenant. It is consistent with a group-based licence assignment change, a tenant configuration modification, or — as a secondary possibility — an active Microsoft service incident scoped to this tenant or region.

**The evidence does not support a Copilot product fault.** It points strongly to a platform or configuration-level change. The Service Health Dashboard and Entra ID audit log are the two fastest paths to confirmation.

**Severity: P1. Immediate admin investigation required.** The Legal Ops Manager should be updated within 30 minutes of this report with the findings from the Service Health and licence checks.

---

*Report prepared by DWP Support Engineering | 2026-08-12*
