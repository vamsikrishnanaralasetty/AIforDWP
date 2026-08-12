# Incident Triage Report — Copilot: Generic Responses When Querying Contract Templates Library

**Ticket Reference:** DAY8-TRIAGE-005  
**Date:** 2026-08-12  
**Assigned Engineer:** DWP Support  
**Reporter:** Contract Specialist  
**Severity:** Medium — Single user; functional degradation rather than total loss of access  

---

## Incident Summary

A contract specialist reports that Copilot returns vague, generic answers when asked about clauses in the organisation's contract templates library. The user's expectation is that Copilot will read and reason over the specific documents in the library. Instead, Copilot appears to be responding from general knowledge rather than from the actual organisational content. This behaviour is consistent with Copilot being unable to retrieve or index the library content, rather than a product fault.

**Key distinction:** When Copilot cannot find or access relevant organisational documents, it falls back to its underlying language model knowledge and generates general responses. This is expected fallback behaviour — the question is why the specific documents are not being retrieved.

---

## User Impact

- **Affected users:** 1 (contract specialist) — may affect others using the same library if indexing or access is the cause
- **Affected workflow:** Contract clause review, template analysis, and drafting support via Copilot
- **Business impact:** Medium — user cannot use Copilot to accelerate contract work; relying on manual document review instead
- **Data at risk:** None — no data exposure concern

---

## Findings

| # | Observation | Significance |
|---|-------------|--------------|
| 1 | Copilot returns generic answers about contract clauses | Strongly suggests Copilot cannot retrieve the specific documents; falling back to language model general knowledge |
| 2 | User reports Copilot "doesn't seem to actually read the documents" | Copilot only reads documents it can find through Microsoft Search; if they are not indexed or accessible, it cannot use them |
| 3 | Content is in a "contract templates library" — likely a SharePoint document library | Location, permissions, indexing status, and sensitivity labels on this library are all unconfirmed |
| 4 | No error message reported — Copilot answers but answers poorly | Distinguishes this from a hard access block; Copilot is responding but without grounded document content |
| 5 | Prompt specificity is unknown | Broad prompts (e.g., "tell me about indemnity clauses") are more likely to produce generic answers than specific document-grounded prompts |
| 6 | No indication of a wider Copilot service issue | Isolated to this user and this content source |

---

## Likely Cause Ranking

1. **Data indexing lag or incomplete indexing of the SharePoint library** *(most probable)*  
   If the contract templates library was recently created, migrated, or significantly updated, Microsoft Search may not have fully indexed its contents. Copilot relies entirely on Microsoft Search to retrieve organisational documents. If the library is not indexed or the documents within it are not discoverable through Microsoft Search, Copilot will produce generic responses based on its language model training rather than the actual documents.

2. **Permissions/access boundary** *(probable)*  
   If the contract templates library has restricted permissions and the user does not have at least read access to the documents, Copilot will not be able to retrieve them even if they are indexed. The user believes they have access, but this should be verified — particularly at the document or folder level if inheritance has been broken.

3. **Sensitivity label restriction** *(possible)*  
   If documents in the library carry sensitivity labels that restrict Copilot processing (e.g., a label configured with "Do not allow Microsoft 365 services to process this content"), Copilot will be unable to read them and will fall back to generic responses.

4. **License/client prerequisite issue** *(possible — lower priority)*  
   If the user's Copilot for Microsoft 365 licence was recently assigned or is not fully active, some capabilities may be limited. However, since Copilot is responding (even if generically), it is more likely the licence is active but the content is unavailable.

5. **Guest/external sharing limitation** *(not applicable)*  
   The reporter is an internal user; not relevant.

6. **Genuine Copilot fault** *(last resort — not supported by evidence)*  
   Generic fallback responses are documented expected behaviour when Copilot cannot retrieve relevant content. There is no evidence of a product defect.

---

## Fastest Check

> **Verify whether the contract templates library content is searchable through Microsoft Search.**  
> Open Microsoft Search (search bar in SharePoint, Teams, or Office.com) and search for a specific, distinctive phrase or clause known to appear in one of the template documents. If Microsoft Search cannot find the document, Copilot cannot either — confirming an indexing or permissions issue.

This check takes under two minutes and immediately confirms whether the content is discoverable.

---

## Investigation Steps

1. **Test Microsoft Search discoverability** — Search for a specific phrase known to exist in a contract template document using the Microsoft Search bar in SharePoint or Office.com. If the document does not appear, the content is not discoverable by Copilot.

2. **Verify SharePoint library permissions** — Navigate to the contract templates library → **Settings** → **Library permissions** → confirm the contract specialist's account or group has at least Read access. Check for permission inheritance breaks at the folder or document level.

3. **Confirm the library location is a supported Microsoft 365 location** — Copilot can only use content stored in SharePoint Online, OneDrive for Business, Exchange Online, or Teams. If the library is in a file share, a legacy on-premises SharePoint instance, or a third-party storage system, Copilot cannot access it.

4. **Check indexing status of the library** — In the SharePoint admin center, check whether the site and library are included in search. Confirm the content source is not excluded from Microsoft Search via a search schema setting or site collection search configuration.

5. **Check sensitivity labels on template documents** — Review one or more documents in the library in Microsoft Purview or by checking document properties. Confirm whether any label policy restricts Copilot or Microsoft 365 service processing.

6. **Confirm Copilot licence status** — Microsoft 365 Admin Center → Users → select the user → Licences and apps → confirm Copilot for Microsoft 365 is active and fully provisioned.

7. **Test with a specific Copilot prompt referencing the document** — Ask the user to try a direct prompt such as: *"Summarise the indemnity clause in [document name] in the contract templates library."* A document-specific prompt is more likely to retrieve grounded content than a broad general question.

8. **Test with a known document URL** — Ask the user to paste a direct SharePoint URL to a specific template into the Copilot chat context. If Copilot can then answer using the document content, the issue is discoverability/indexing rather than a processing fault.

9. **Review library creation and modification dates** — If the library was recently created or documents were recently uploaded, allow 24–72 hours for full indexing before concluding there is a configuration problem.

10. **Check Microsoft Search crawl status** — In the SharePoint admin center → More features → Search → search schema and content sources — verify the site is being crawled and is not excluded.

---

## Root Cause

**Most probable root cause: Contract templates library content is not indexed or discoverable through Microsoft Search.**

Copilot uses Microsoft Search as its retrieval layer to find and ground its responses in organisational content. When it cannot find relevant documents, it does not fail silently with an error — it generates a response using its underlying language model training, which produces accurate but generic answers that are not based on the specific organisational documents. This fallback behaviour explains exactly what the user is experiencing.

The most likely reason the content is not being retrieved is one of the following:
- The library or site is not indexed by Microsoft Search (new library, exclusion setting, or crawl not yet complete)
- The user's access to the library exists at a high level but is blocked at the document or folder level
- Documents carry sensitivity labels that prevent Copilot from processing them

Root cause confirmation requires completing investigation steps 1–4.

---

## Business Impact Assessment

| Dimension | Assessment |
|-----------|------------|
| Productivity impact | Medium — contract review and clause analysis must be done manually; slows drafting and review cycles |
| Scope | Potentially wider — if the library is not indexed, any colleague using Copilot for contract work will experience the same issue |
| Data risk | None — no exposure or leakage concern |
| Urgency | Medium — not a P1; no complete loss of service, but a significant capability gap for a specialist workflow |
| Escalation required | No — resolvable through standard admin investigation |

---

## Recommended Resolution

**If indexing is the cause:**
1. Confirm the SharePoint site is included in Microsoft Search and not excluded.
2. If documents were recently uploaded, wait 24–72 hours for indexing to complete, then ask the user to retry.
3. If the site is excluded from search, work with the SharePoint admin to include it in the search scope.

**If permissions are the cause:**
4. Grant the contract specialist appropriate read access to the library and all folders/documents within it.
5. Confirm permission inheritance has not been broken at a sub-folder level.

**If sensitivity labels are the cause:**
6. Review the label policy with the Information Governance team. If the label is preventing legitimate Copilot use, consider whether the policy is configured correctly for internal users.

**Prompt improvement (applicable regardless of root cause):**
7. Advise the user to use more specific, document-grounded prompts (see user communication for guidance). Specific prompts referencing document names or pasting content directly into the Copilot chat context can improve results significantly.

**If the library is in a non-supported location:**
8. Work with the user and their team to migrate the library to SharePoint Online so it becomes accessible to Copilot and Microsoft Search.

---

## Validation Steps

1. Confirm the contract templates library appears in Microsoft Search results for known document content.
2. Ask the user to retry a specific Copilot prompt referencing a named template document.
3. Confirm Copilot returns a grounded, document-specific response rather than a generic answer.
4. If multiple users work with the library, ask a second user to test to confirm the fix is not user-specific.
5. Close the ticket only after the user confirms Copilot is returning accurate, document-grounded responses.

---

## Preventive Recommendations

- **Verify Microsoft Search indexing before rolling out Copilot for a new content area** — Before directing users to use Copilot against a document library, confirm the library is indexed and searchable through Microsoft Search.
- **Avoid sensitivity labels that block Copilot processing on broadly accessible libraries** — Review label policies to ensure they are calibrated correctly for internal use cases and do not inadvertently block Copilot from legitimate content.
- **Provide prompt guidance to users** — Users who understand how to write specific, document-grounded prompts get significantly better Copilot responses. Include prompt guidance in Copilot onboarding materials.
- **Include SharePoint library location checks in Copilot readiness assessments** — Confirm all key document libraries are in supported Microsoft 365 locations (SharePoint Online, OneDrive for Business) before enabling Copilot for content-heavy workflows.
- **Establish a minimum 72-hour wait after new library creation** before expecting Copilot to work against new content.

---

## Triage Conclusion

**Is this actually a Copilot bug? No.**

Generic fallback responses when organisational documents cannot be retrieved is documented, expected Copilot behaviour — not a product fault. Copilot is behaving correctly given what it can and cannot access. The issue is upstream: the contract templates library content is either not indexed, not accessible to the user at the required level, or blocked by a sensitivity label configuration.

**Action required:** Confirm library is indexed and accessible via Microsoft Search; check permissions and sensitivity labels; provide the user with prompt guidance in the interim.

---

*Report prepared by DWP Support Engineering | 2026-08-12*
