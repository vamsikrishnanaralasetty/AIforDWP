# Personal AI Usage Charter — DWP Desktop/Endpoint Engineer
*Effective: August 2026 | Review: Annually*

---

## 1. Appropriate tasks for public AI assistants

I may use public LLMs (e.g. GitHub Copilot, ChatGPT) for:

- Drafting or debugging PowerShell/batch scripts using **synthetic or anonymised data only**
- Researching Windows 11, Intune, AVD, BitLocker, OneDrive, and Teams configuration syntax
- Writing runbooks, KB articles, and incident reports after **removing all PII and ticket-specific identifiers**
- Translating technical findings into plain-English summaries for stakeholders
- Generating regex, WMI queries, or event log filter logic for general endpoint health tasks
- Reviewing inherited scripts for logic errors, using **no live environment details**

---

## 2. Tasks I will NOT use public AI assistants for

- Any input containing real usernames, employee IDs, email addresses, or device names
- Queries referencing DWP internal hostnames, IP ranges, AD structure, or network topology
- Uploading or pasting error logs that contain system identifiers or user session data
- Security policy review, GPO design decisions, or certificate/key material of any kind
- Incident triage where the prompt would reveal the nature or extent of a live security event
- Any task covered by an active DWP security classification or data handling instruction

---

## 3. Data-handling rule — End-user PII and credentials

> **I will never paste, type, or describe real PII or credentials into a public AI tool.**

Before using AI assistance I will:

- Replace real usernames with `user01`, real hostnames with `ENDPOINT-X`, and real IPs with `10.x.x.x`
- Remove or redact ticket numbers, staff IDs, and organisational unit names
- Treat any AI-generated output as potentially observable by third parties — I will not feed it back into live systems without sanitising it first
- Never use AI autocomplete or chat in the same window/session where live credentials are visible

---

## 4. Generate-then-verify rule — Scripts and system changes

> **AI output is a first draft, not a finished product.**

For every script or configuration change generated with AI help I will:

1. **Read the full output** before running anything — not just the final command
2. **Verify logic** against Microsoft documentation or a known-good reference
3. **Test in a non-production scope** (single device, test OU, or sandbox AVD pool) before wider deployment
4. **Check for destructive operations** — any `Remove-`, `Format-`, `Clear-`, `Set-` or `-Force` parameter requires explicit sign-off in my change note
5. **Own the output** — I am accountable for what runs in the DWP environment regardless of how it was generated

---

*This charter supplements, and does not replace, DWP's Acceptable Use Policy and Information Security standards.*
