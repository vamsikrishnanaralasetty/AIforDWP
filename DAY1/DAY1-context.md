# Reusable Context Document

## Title
Personal AI Usage Charter (DWP Desktop/Endpoint Engineering)

## Version
2026-08-03

## Owner
[Your Name / Team]

## Purpose
Use public AI assistants to improve speed and quality of desktop and endpoint engineering work while protecting users, systems, and DWP data.

## Scope
Applies to day-to-day endpoint support, troubleshooting, packaging, scripting, and documentation work when using public AI tools.

## Operating Principles
- Security and privacy first, speed second.
- Minimum disclosure: share only the smallest possible technical context.
- Human accountability: all outputs and actions remain my responsibility.
- Generate then verify: no AI output is trusted until checked.

## 1) Appropriate DWP Tasks for Public LLM Help
Use public AI for low-risk, non-sensitive engineering tasks such as:
- Drafting PowerShell or batch script skeletons for generic actions (service checks, log parsing, disk cleanup logic, basic inventory collection).
- Explaining Windows endpoint concepts (startup impact, profile behavior, Outlook cache mode, Intune policy interactions at a general level).
- Turning rough notes into clear service desk updates, KB drafts, and step-by-step runbooks with sensitive details removed.
- Creating troubleshooting checklists for common desktop issues (slow boot, app launch delays, printer mapping, patch verification).
- Reviewing script readability, error handling patterns, and idempotency approach using sanitized examples.
- Generating test cases and rollback checklists for planned endpoint changes.

Rule of thumb:
- If the same prompt could be posted publicly without risk, it is likely appropriate.

## 2) Not Appropriate for Public AI
Do not use public AI for tasks involving protected DWP information or high-risk operational decisions, including:
- Incident details containing user identities, case information, health or benefit context, or internal business data.
- Raw logs, screenshots, tickets, exports, or command output containing hostnames, usernames, email addresses, IPs, device IDs, or internal paths.
- Credentials or secrets of any kind (passwords, tokens, API keys, recovery codes, private certificates).
- Security operations content (vulnerability details, detection logic, privileged architecture, hardening exceptions not already public).
- Direct production decisioning without independent validation (for example, mass-remediation scripts, registry changes, policy removals).
- Any request that would bypass policy, controls, or approval routes.

If unsure, treat as not appropriate until confirmed safe.

## 3) Data Handling Rule for End-User PII and Credentials
I will never place end-user PII or credentials into a public AI assistant.

Mandatory handling controls:
- Remove or replace personal and identifying data before prompting.
- Sanitize technical artifacts: replace real names, emails, device names, IPs, tenant identifiers, and ticket references with placeholders.
- Share patterns, not payloads: ask about structure or logic using synthetic examples.
- Never paste secrets, even temporarily.
- If a task cannot be done without real data, do not use public AI for that task.

Quick red-line test before sending a prompt:
- Could this identify a person, account, device, or internal system?
- Could this grant access if leaked?
- Could this damage DWP trust if published?
If yes to any, do not submit.

## 4) Personal Generate-Then-Verify Rule for Scripts and System Changes
For any AI-generated script, command sequence, or system change, follow this workflow:

1. Generate
- Request minimal, least-privilege, reversible steps.
- Ask for assumptions, prerequisites, and rollback plan in the same response.

2. Inspect
- Read every line before execution.
- Check for destructive actions, wide targeting, hidden downloads, privilege escalation, and hard-coded paths or secrets.

3. Verify in a safe context
- Test first on a non-production or isolated endpoint.
- Validate expected outcomes and side effects (performance, startup, app behavior, policy compliance).

4. Approve and control
- Follow normal DWP change and approval process for impactful actions.
- Use staged rollout for multi-device changes.

5. Execute and evidence
- Run with logging enabled.
- Record what was run, where, when, and why.

6. Rollback ready
- Confirm rollback steps work before broad deployment.
- Stop immediately if behavior differs from expectation.

7. Post-change check
- Confirm service restored and no regression.
- Update ticket or KB with verified, human-reviewed steps.

## Personal Commitment
I will use public AI as a drafting and reasoning aid, not as an authority. I am accountable for secure handling, policy compliance, and technical correctness of every action I take.

---

## Ready-to-Paste Context Block for Future Chats
Use this exact block in a new chat when you want the assistant to follow this charter:

```text
Use the following working context for this chat:
- I work in DWP Desktop/Endpoint Engineering.
- Treat security and privacy as top priority.
- Never ask me to share or paste end-user PII, credentials, secrets, or identifiable internal system data.
- If real data is needed, provide a sanitized-template approach instead.
- Focus on low-risk support tasks: troubleshooting checklists, script skeletons, KB/runbook drafting, and test/rollback planning.
- For any script or system change, always provide: assumptions, prerequisites, least-privilege approach, rollback plan, and validation steps.
- Explicitly flag risky or production-impacting actions and recommend staged rollout plus formal approval path.
- Keep output practical, concise, and directly usable in endpoint engineering workflows.
```
