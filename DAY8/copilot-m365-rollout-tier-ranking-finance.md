# Microsoft 365 Copilot — Rollout Tier Ranking: Finance Department

| Field | Detail |
|---|---|
| **Title** | Copilot Rollout Tier Ranking — Finance |
| **Version** | 1.0 |
| **Date** | 12/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Source checklist** | copilot-m365-readiness-checklist-finance.md |
| **Scope** | Finance department, ~200 users |

---

## How to read this document

Each checklist item has been assigned to one of three tiers based on two factors:

- **Consequence of skipping:** what is the realistic worst-case outcome if this item is not done before the Copilot add-on is assigned?
- **Reversibility:** if something goes wrong after rollout because this item was skipped, can it be fixed quickly and quietly, or does it become a reportable incident?

Items where the consequence is a data breach, regulatory exposure, or irreversible reputational harm are MUST. Items where the consequence is degraded user experience or elevated but manageable risk are SHOULD. Items where the consequence is a missed adoption opportunity or minor friction are CAN.

---

## Tier 1 — MUST complete before rollout (blocking)

These items must be confirmed before the Copilot add-on is assigned to any Finance user, including the pilot group. Skipping any of these means accepting a risk that is not acceptable for a department handling payroll, board packs, M&A documents, and client financial data.

### Permissions and Oversharing (Section 4 — all items)

| Check | Ref | Why it is a hard blocker |
|---|---|---|
| Full permissions report run across all Finance SharePoint site collections | 4.1 | Without this, the actual exposure is unknown. You cannot mitigate what you have not measured. |
| Inherited permission chains from 2019 migration reviewed and remediated | 4.2 | Seven years of unreviewed inheritance is the core risk. Broken or unintentional inheritance is the most common mechanism by which the wrong people hold read access to sensitive content. |
| "Everyone", "Everyone except external users", and "All Company" groups removed from Finance sites | 4.3 | These groups grant access to the entire organisation. With Copilot active, any member of those groups — potentially all staff — can retrieve Finance content via a prompt. |
| Legacy broad AD security groups reviewed and replaced with named groups | 4.4 | Groups migrated in 2019 may have grown via normal HR processes to include people who were never intended to access Finance data. Membership drift is invisible without an audit. |
| Site owners have confirmed current permissions are correct | 4.5 | Technical remediation without business sign-off can miss contextual access that should exist. Owner confirmation closes the loop. |
| Post-remediation permissions export confirms clean state | 4.6 | Remediation without re-verification is not remediation. A second export is required as evidence. |
| Payroll library — unique permissions, named members only | 4.7 | Payroll data has statutory protection obligations. Any unauthorised access is a potential GDPR breach and an HR incident. |
| Board pack library — unique permissions, named members only | 4.8 | Board materials are market-sensitive. Unauthorised access or leakage could constitute an insider information incident under FCA rules. |
| M&A site collection — standalone, named deal-team members only | 4.9 | M&A data is the most sensitive category in this department. Exposure of an active deal to unpermissioned users via Copilot is a catastrophic and potentially criminal event. |
| Client financial data — per-engagement access only | 4.10 | Client confidentiality obligations are contractual. A breach here triggers client notification duties and potential litigation. |
| Tenant external sharing set to "Existing guests only" or stricter | 4.11 | "Anyone" links created before this change remain active. Copilot can reference content shared via anonymous links, meaning external-facing content could surface in internal Copilot sessions. |
| Finance sites set to "Only people in your organisation" | 4.12 | Site-level sharing settings override tenant defaults downward. Finance sites need the strictest available setting regardless of tenant default. |
| All existing anonymous sharing links expired or revoked | 4.13 | A clean sharing setting does not retroactively revoke links already created. Existing "Anyone" links must be explicitly expired. |
| OneDrive sharing restricted for Finance users | 4.14 | Copilot can summarise content from a user's OneDrive. If users can share externally freely, a file that should not leave the organisation could be summarised and forwarded via Copilot-generated email. |

### Licensing (Section 1)

| Check | Ref | Why it is a hard blocker |
|---|---|---|
| All Finance users confirmed on M365 E5 | 1.1 | The Copilot add-on requires E3 or E5 as a base. Assigning to an unlicensed user will fail silently or generate an error that wastes time during rollout. |
| Copilot add-on licences procured and available | 1.3 | Assignment cannot proceed without available licence inventory. |
| Pilot group (~20 users) planned before full rollout | 1.4 | Assigning to all 200 simultaneously removes the ability to catch configuration problems before they affect the entire department. |

### Identity and MFA (Section 3)

| Check | Ref | Why it is a hard blocker |
|---|---|---|
| All Finance users have MFA registered (authenticator app) | 3.1 | Copilot access without MFA means a compromised password alone is sufficient to query all Finance SharePoint content. For this data sensitivity level, SMS MFA is insufficient. |
| Conditional Access policy requires MFA + compliant device | 3.2, 3.3 | Without this, Copilot is accessible from any device, including personal or unmanaged devices outside Intune policy. |
| All Finance devices are Intune-compliant | 3.4 | A non-compliant device that nonetheless passes Conditional Access represents an unmanaged endpoint with access to Copilot and high-sensitivity Finance content. |

### DLP in Enforce Mode (Section 5)

| Check | Ref | Why it is a hard blocker |
|---|---|---|
| DLP policies in Enforce mode covering SharePoint, OneDrive, Teams, Exchange | 5.4 | Audit-only mode detects violations but does not prevent them. With Copilot active, a user could prompt Copilot to draft an external email containing payroll figures; DLP in enforce mode is the last technical control that blocks the send. |
| DLP detects relevant sensitive information types | 5.5 | A DLP policy that does not recognise the actual data formats in use provides false confidence. |

### Acceptable Use Policy (Section 6)

| Check | Ref | Why it is a hard blocker |
|---|---|---|
| Acceptable use policy signed off by Finance Director and Legal/Compliance | 6.1 | Without a published policy, there is no governance basis for action if a Finance user misuses Copilot. The policy is also the mechanism for communicating Finance-specific restrictions before users encounter the tool. |

---

## Tier 2 — SHOULD complete before rollout (high risk if skipped)

These items do not individually prevent Copilot from functioning, but skipping them meaningfully increases the risk of a data incident, a poor user experience, or a compliance gap within days of go-live. They should be complete at pilot launch and confirmed before full rollout.

| Check | Ref | Risk if skipped |
|---|---|---|
| Finance users not on E3 or lower confirmed | 1.2 | Unlikely to affect many users given confirmed E5 estate, but an unlicensed user receiving a Copilot licence will generate support noise. |
| Apps running Current Channel or Monthly Enterprise, ≥ Version 2302 | 2.1, 2.2 | Copilot features are absent or degraded on older builds. Users will raise tickets thinking Copilot is broken. |
| No Finance devices on Semi-Annual Enterprise Channel | 2.3 | SAEC devices will not surface Copilot in the Office ribbon. Creates a two-tier experience within the department. |
| Guest accounts not members of Finance sites | 3.6 | External guests with access to Finance sites can be referenced in Copilot-generated content. Lower probability than internal over-permissioning but still a real exposure for a deal-team using guest access. |
| Sensitivity labels published and auto-labelling enabled | 5.1, 5.2 | Without labels, DLP policies relying on label conditions cannot enforce. Unlabelled content can be summarised and redistributed by Copilot without triggering a policy. |
| Default labels applied at SharePoint library level | 5.3 | New documents uploaded to Finance libraries inherit no label and are therefore unprotected by label-based DLP rules. |
| Purview audit logging active, CopilotInteraction events retained | 5.6 | Copilot interactions that occur before audit logging is confirmed are not logged. If an incident is reported after rollout and audit logging was not on, there is no trail to investigate. |
| No permanent high-privilege role assignments in Finance accounts | 3.5 | Lower probability of exploitation in Finance day-to-day, but an account with a permanent Admin role that also has Copilot is a high-value target. Enforce PIM before go-live. |
| Finance-specific onboarding guide created | 6.2 | Users without guidance will use Copilot exploratively against high-sensitivity content. Incidents arising from well-meaning but uninformed prompts are the most common early Copilot risk. |
| IT champions identified and briefed | 6.5 | Without champions, all user questions escalate directly to IT support, creating a surge at go-live. |

---

## Tier 3 — CAN complete during or after rollout (lower risk)

These items improve adoption, governance, and long-term compliance but do not introduce meaningful data risk if deferred by one or two weeks past pilot go-live.

| Check | Ref | Notes |
|---|---|---|
| Update compliance confirmed — no device more than one version behind | 2.4 | Devices one version behind Current Channel still receive Copilot features. Keep as a hygiene target post-rollout. |
| Restricted SharePoint Search evaluated | 4.15 | Useful as an additional pilot-phase control. Not required if Sections 4a–4c are fully remediated. |
| User awareness session delivered to all 200 users | 6.3 | Can be phased: deliver to pilot group before pilot go-live; schedule remaining sessions to coincide with broader licence assignment. |
| Feedback and incident reporting channel confirmed live | 6.4 | Should be in place by full rollout (Week 5); acceptable to set up in the days after pilot launch. |

---

## Why permissions and oversharing belong in MUST — not alongside licensing and client version

Licensing and client version are simpler to verify, and that simplicity can make them feel equally important or even more foundational. They are not. Here is the distinction.

**Licensing and client version failures are visible and recoverable.**
If a user has the wrong licence, Copilot simply does not appear. If their Office build is out of date, the Copilot icon is absent from the ribbon. The user raises a ticket, IT corrects the licence or triggers an update, and the problem is resolved within hours. No data is exposed. No harm is done.

**Permission failures are silent and potentially irreversible.**
If the permissions and oversharing checks are skipped and the Copilot add-on is assigned, there is no error message, no warning, and no visible signal that anything is wrong. Copilot operates exactly as designed — it surfaces content that the signed-in user is permitted to access. If a Finance analyst is — because of a 2019 migration inheritance that was never cleaned up — technically a member of a SharePoint group with read access to the M&A site collection, Copilot will return M&A documents in response to entirely routine prompts. The analyst may not even realise the content is restricted. The information leaves the controlled environment, potentially in a Copilot-generated email summary or a Teams message. That event is not recoverable: the data has already been seen, copied, or forwarded.

In this specific Finance context, three factors compound the risk beyond a standard department:

1. **Inherited permissions at scale.** The 2019 migration applied permissions in bulk. Broad groups, broken inheritance chains, and "Everyone"-style assignments that were acceptable on a smaller or less sensitive pre-migration estate were carried over intact. Seven years of staff turnover, restructuring, and new site creation have occurred since, with no corresponding permissions review. The current state of access across Finance SharePoint is genuinely unknown.

2. **The data categories involved.** Payroll data carries GDPR obligations and potential regulatory enforcement. Board pack content is market-sensitive under FCA rules. M&A data, if leaked to an unintended recipient, can constitute a criminal offence under the Criminal Justice Act 1993. Client financial data carries contractual confidentiality and potentially client-notification obligations on breach. A single over-permissioned access event in any of these categories is not an IT incident — it is a legal and regulatory event.

3. **Copilot lowers the access barrier to near zero.** A legacy permission error that has sat harmless for seven years because the data was in a site a user had no reason to navigate to is not harmless once Copilot is enabled. A single natural language query — "summarise the latest board materials" — issued by a user who has never visited the board pack library and would never have thought to look, can return a full summary of a document they were never meant to see. The risk that was theoretical becomes routine.

Licensing and client version checks belong in MUST because without them Copilot does not work. Permissions and oversharing checks belong in MUST because without them Copilot works exactly as designed — and that is the problem.

---

*This document should be read alongside the source readiness checklist. Item references (e.g. 4.1, 5.4) correspond to section and item numbers in copilot-m365-readiness-checklist-finance.md.*
