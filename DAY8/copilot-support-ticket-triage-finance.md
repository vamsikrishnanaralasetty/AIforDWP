# Copilot for M365 — Support Ticket Triage: Finance Department

| Field | Detail |
|---|---|
| **Title** | Copilot Support Ticket Triage — Finance |
| **Version** | 1.0 |
| **Date** | 12/08/2026 |
| **Author** | Copilot |
| **Reviewed by** | Pending |
| **Status** | Draft |
| **Scope** | Finance department, ~200 users |

---

> **Triage principle:** Default to a non-Copilot cause unless the evidence genuinely rules all other explanations out. "Genuine Copilot fault" is always the last resort. In a Finance department that has just enabled Copilot against a backdrop of unaudited 2019-migration permissions, the overwhelming majority of early tickets will be permissions, indexing, or label issues — not product defects.

---

## Ticket 1

**Reported:** Finance lead — Copilot won't summarise the Q3 board pack in SharePoint. *"It's right there, I can see it myself."*

### Likely cause — ranked most probable first

1. **Data indexing lag** — The user can see the file in the browser (direct SharePoint render), but Copilot uses Microsoft Graph search, which indexes asynchronously. A recently uploaded, moved, or renamed file may not yet appear in the Graph index. This is the most common cause when the user has confirmed they can open the file directly.
2. **Sensitivity label restriction** — If the board pack carries a sensitivity label with Azure Rights Management encryption (e.g., *Highly Confidential — Finance*), the encrypted content cannot be indexed by Graph and is therefore invisible to Copilot even when the user holds valid access. The file is visible in SharePoint because the browser decrypts it client-side using the user's rights token; Copilot's server-side indexing cannot do the same.
3. **Permissions/access boundary** — Less likely given the user's statement, but worth ruling out: the user may be viewing the file via a cached session or a sharing link that their Graph token does not reflect in the same way.
4. **Genuine Copilot fault** — Last resort.

### Fastest check

In SharePoint, check when the file was last modified or uploaded (file properties > Modified date). If it is less than 24–48 hours old, indexing lag is almost certain. Also check the sensitivity label shown in the document information bar — if it shows Rights Management encryption, that explains the block.

### Is this actually a Copilot bug?

**No.** The two most probable causes — indexing lag and label-based encryption blocking Graph — are expected product behaviours, not defects. Copilot is operating correctly in both cases.

---

## Ticket 2

**Reported:** New hire (started yesterday) — Copilot in Outlook seems to know nothing about my recent emails.

### Likely cause — ranked most probable first

1. **Licence/client prerequisite issue** — The most likely cause is that the Copilot add-on has not been assigned to this account. New hire provisioning processes often lag behind licence assignment workflows. If the add-on is not assigned, Copilot appears in the interface (it is bundled in the client) but falls back to web-only mode with no mailbox grounding.
2. **Data indexing lag** — Even with a valid licence, a mailbox created yesterday contains almost no indexed history. Copilot in Outlook draws on the Graph index of the user's mailbox. A one-day-old mailbox with a handful of emails has very little for Copilot to work with. This is expected behaviour, not a fault.
3. **Client version** — A device provisioned for a new hire may be running an older M365 Apps build if update policies have not yet applied. Copilot features require a minimum build (Version 2302 / build 16130.20218).

### Fastest check

Open Microsoft 365 admin centre > Users > select the new hire's account > Licences and apps — confirm the Microsoft Copilot for M365 add-on is checked. This takes 30 seconds and rules in or out the most probable cause immediately.

### Is this actually a Copilot bug?

**No.** A missing licence or a near-empty new mailbox fully explains the behaviour. No investigation into the product is warranted until both are confirmed and the issue persists.

---

## Ticket 3

**Reported:** HR manager — Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got *"I don't have access to that content."*

### Likely cause — ranked most probable first

1. **Sensitivity label restriction** — The explicit error message *"I don't have access to that content"* is Copilot's standard response when Graph cannot read the file's content. The most common cause for a file the user *can* open directly is a sensitivity label that applies Azure Rights Management encryption with restrictions that prevent server-side processing. Copilot's back-end cannot decrypt RMS-protected content on behalf of the user in the same way the Word client can.
2. **Permissions/access boundary** — The HR manager may not actually have read access to the file at the Graph layer, even if they can reach it via a shared link or a cached session. A link-based share does not automatically grant Graph-level permission that Copilot can use.
3. **Data indexing lag** — Less likely given the specific error message; indexing lag typically produces "I couldn't find that" rather than an explicit access denial.
4. **Genuine Copilot fault** — Last resort.

### Fastest check

Ask the HR manager to open the file directly in Excel (not via a link — navigate to it in SharePoint). If it opens cleanly, check the sensitivity label displayed in the information bar. If the label includes *Do Not Forward* or *Encrypt-Only* type protections, that is the cause. If the file will not open at all via direct navigation, the issue is a permissions boundary, not a label.

### Is this actually a Copilot bug?

**No.** An explicit access-denial response from Copilot reflects a Graph-layer access or encryption issue. Both are expected product behaviours. The file's label or permissions need investigation, not the Copilot service.

---

## Ticket 4

**Reported:** Sales rep — Copilot in Teams can't find a client contract that was shared with her via a guest link from another org.

### Likely cause — ranked most probable first

1. **Guest/external sharing limitation** — The file lives in the external organisation's SharePoint tenant. Copilot for M365 indexes content within the signed-in user's own tenant Graph. Content shared from another organisation via a guest link is stored in that organisation's tenant and is not indexed by this tenant's Microsoft Graph. Copilot cannot access cross-tenant content regardless of whether the user can open the file in a browser.
2. **Permissions/access boundary** — Even in scenarios where cross-tenant content is partially available, Graph permissions for guest-linked content are handled differently from native tenant permissions and may not be traversable by Copilot's indexing.

### Fastest check

Ask the sales rep where the file is stored — is the URL in the browser `https://[our-tenant].sharepoint.com/...` or `https://[external-org].sharepoint.com/...`? If it is an external URL, the limitation is by product design and no further investigation of the tenant configuration is needed.

### Is this actually a Copilot bug?

**No.** Copilot for M365 is explicitly scoped to the user's own tenant Graph. Cross-tenant content accessed via guest links is out of scope by design. This is a product boundary, not a defect. The sales rep should be advised to request that the contract be copied into a native tenant SharePoint location if Copilot access is needed.

---

## Ticket 5

**Reported:** IT admin — Copilot suddenly stopped working for the whole Finance team this morning; was fine yesterday.

### Likely cause — ranked most probable first

1. **Licence/client prerequisite issue** — A bulk licence change is the most common cause of a sudden, department-wide Copilot outage. Check whether the Copilot add-on was accidentally removed from the Finance licence group, whether a dynamic group membership rule changed overnight and removed Finance users, or whether a billing event (payment failure, subscription expiry) has suspended the add-on.
2. **Conditional Access policy change** — A new or modified Conditional Access policy pushed overnight may be blocking the Copilot service for Finance users. CA policy changes can take effect immediately and can silently block access without a clear end-user error message.
3. **Genuine Copilot fault / service incident** — If licence assignments and CA policies are confirmed unchanged, check the Microsoft 365 Service Health dashboard in the admin centre. A genuine service incident affecting the Copilot service or the Microsoft Graph would be listed there and would explain a sudden tenant-wide or department-wide outage.

### Fastest check

Microsoft 365 admin centre > Health > Service health — check for any active incidents flagged against Microsoft Copilot for M365 or Microsoft Graph. This takes 60 seconds and either confirms a service incident (in which case wait for Microsoft resolution) or rules it out, focusing investigation on the licence and CA layer.

### Is this actually a Copilot bug?

**Unclear.** A sudden, whole-team outage with no user-side change is more likely a licence assignment or CA policy change than a Copilot defect, but a genuine service incident cannot be ruled out without checking Service Health. Investigate licence and CA first; treat as a potential service incident only if both are confirmed clean.

---

## Ticket 6

**Reported:** Manager — Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to.

### Likely cause — ranked most probable first

1. **Permissions/access boundary — working as designed, exposing an over-permissioning issue** — This is not a malfunction. Copilot surfaces content the signed-in user is legitimately permitted to access at the Graph layer. The manager holds real read access to the folder in question — most likely via an inherited or legacy permission from the 2019 migration. The permission was always there; Copilot made it visible by actively searching across everything the user can access rather than waiting for the user to navigate there manually.

### Fastest check

Ask the manager to navigate directly to the folder in SharePoint. If they can open the folder and read the file without any access prompt, the permission is real. Check the folder's permission settings (Library settings > Permissions) to identify the group or inheritance chain that grants the manager access.

### Is this actually a Copilot bug?

**No.** Copilot is operating exactly as designed. This ticket is evidence of the over-permissioning risk documented in the readiness checklist — a permission that existed silently for years has been surfaced by Copilot. The correct response is a permissions review for the folder in question, not a Copilot investigation. Escalate to the SharePoint permissions audit work stream.

> **Note for the DAY8 audit record:** This ticket is the real-world manifestation of checklist items 4.1–4.6. If Copilot is surfacing content to users who "forgot they had access," there are likely more cases like this across the Finance site collections. Use this ticket as a trigger to accelerate the full permissions audit if it has not yet completed.

---

## Ticket 7

**Reported:** Analyst — Copilot gives generic answers, doesn't seem to use any of our internal SharePoint content at all.

### Likely cause — ranked most probable first

1. **Permissions/access boundary** — The analyst may not have read access to the SharePoint sites they expect Copilot to draw from. Copilot only searches content the user is permitted to access. If the analyst has no permissions on Finance SharePoint sites, Copilot will fall back to web knowledge and produce generic answers.
2. **Restricted SharePoint Search enabled** — If the tenant is using Restricted SharePoint Search (a SharePoint Advanced Management feature sometimes enabled during Copilot pilots to limit scope), Copilot is constrained to a defined list of allowed sites. If the analyst's relevant sites are not on that list, Copilot will behave as if internal content does not exist.
3. **Data indexing lag** — If the analyst's OneDrive or team sites were recently created or had large content migrations, the Graph index may not yet reflect the full content set.
4. **Client version** — An out-of-date M365 Apps build can degrade Copilot's grounding behaviour in some clients.

### Fastest check

Ask the analyst to open SharePoint and navigate directly to one of the sites they expect Copilot to use. Can they access it without an access request prompt? If not, the cause is a permissions boundary. If yes, check the SharePoint Admin Centre > Settings for Restricted SharePoint Search — confirm whether it is enabled and whether the analyst's sites are in the allowed list.

### Is this actually a Copilot bug?

**No.** Generic, ungrounded responses from Copilot are a reliable signal that it cannot reach the expected content — either because the user lacks access or because a tenant-level search restriction is in place. Neither is a product defect.

---

## Ticket 8

**Reported:** Executive assistant — Copilot in Outlook can't see a shared mailbox's calendar that she manages on behalf of her director.

### Likely cause — ranked most probable first

1. **Licence/client prerequisite issue — known product limitation** — Copilot for M365 in Outlook operates on the signed-in user's primary mailbox only. Delegate access and shared mailbox scenarios are a documented current limitation of Copilot in Outlook. The EA's Graph token grants Copilot access to her own mailbox and calendar; it does not traverse delegate grants to the director's mailbox or the shared mailbox calendar, even though the EA can access both natively in Outlook.
2. **Permissions/access boundary** — Secondary possibility: if the delegate or shared mailbox permission was granted in a way that is not reflected correctly in Graph (e.g., via a legacy Exchange on-premises delegation carried forward), the permission may be invisible to Copilot even if it works in the Outlook client.

### Fastest check

Check the Microsoft 365 Copilot product documentation or admin centre Copilot release notes for the current status of shared mailbox and delegate calendar support. As of the current product release, this is a known limitation — confirming this takes 5 minutes and saves an unnecessary deep-dive into the tenant configuration.

### Is this actually a Copilot bug?

**No.** This is a known product boundary. Copilot in Outlook does not currently support delegate or shared mailbox calendar access. The EA should be advised that this is a product limitation rather than a configuration fault, and the team should monitor Microsoft 365 release notes for when delegate/shared mailbox support is added.

---

## Triage summary

| Ticket | User | Root cause category | Copilot bug? |
|---|---|---|---|
| 1 | Finance lead | Data indexing lag / sensitivity label restriction | No |
| 2 | New hire | Licence not assigned / new mailbox with no index history | No |
| 3 | HR manager | Sensitivity label restriction (RMS encryption) / permissions boundary | No |
| 4 | Sales rep | Guest/external sharing limitation — cross-tenant content out of scope by design | No |
| 5 | IT admin | Licence assignment change / Conditional Access policy change / service incident | Unclear — check Service Health |
| 6 | Manager | Permissions working as designed — over-permissioning surfaced by Copilot | No — escalate to permissions audit |
| 7 | Analyst | Permissions boundary / Restricted SharePoint Search | No |
| 8 | Executive assistant | Known product limitation — delegate/shared mailbox not supported | No |

> Of eight tickets, zero are confirmed Copilot product defects. Six are non-Copilot configuration or access issues. One (Ticket 5) requires service health confirmation before the cause can be determined. One (Ticket 6) is Copilot functioning correctly and should be treated as a permissions audit trigger, not a support ticket.
