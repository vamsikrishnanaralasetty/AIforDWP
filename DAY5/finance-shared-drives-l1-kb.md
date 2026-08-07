# Finance Team Cannot Access Shared Drives (S: Missing) - L1 KB

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Audience** | Service Desk (L1) |
| **Related Runbook** | `finance-shared-drives-runbook.md` |

---

## 1. What users report

Common user statements:
- "My S drive is missing after I sign in"
- "I cannot access Finance shared files"
- "The shared drive was there yesterday and is gone today"

Primary symptom for this incident:
- Finance users on `DESKTOP-FB*` endpoints do not see mapped drive `S:` at sign-in.

---

## 2. L1 quick triage checklist

1. Confirm user is in Finance team.
2. Confirm device name starts with `DESKTOP-FB`.
3. Confirm issue is specifically mapped drive `S:` missing (not full network outage).
4. Ask user to sign out, wait 30 seconds, and sign in again.
5. Ask user to open File Explorer and check `S:`.

If `S:` appears after second sign-in:
- Mark as workaround success.
- Keep ticket linked to active incident/problem record.
- Advise user engineering is applying permanent fix.

If `S:` is still missing:
- Continue to Section 3 and escalate to L2.

---

## 3. Safe steps L1 can perform

Ask user to run in PowerShell (non-admin):

```powershell
Get-PSDrive -Name S -ErrorAction SilentlyContinue
Test-Path "\\<server>\\<share>"
```

Interpretation:
- `Test-Path = True` and `S:` missing: likely mapping policy/script issue.
- `Test-Path = False`: possible network/path/permission issue, escalate with details.

Do not ask users to manually edit registry or run unsigned scripts.

---

## 4. When to escalate immediately

Escalate to L2/L3 without delay if:
- User cannot access `S:` after one full sign-out/sign-in retry
- Multiple Finance users report same issue within short window
- User is on `DESKTOP-FB*` and issue started after known change window

Escalation priority:
- High during first business hour if more than 3 affected users

---

## 5. Required ticket notes before escalation

Include all items:
- User UPN
- Department (Finance)
- Device name
- First seen time
- Result of sign-out/sign-in retry
- Output summary of `Get-PSDrive` and `Test-Path`
- Whether other Finance users reported same issue

---

## 6. User communication template

Use this message:

"We identified an issue affecting Finance shared drive mapping at sign-in. Your files are still on the server and not lost. We are applying a fix now. Please sign out, wait 30 seconds, and sign in again. If the S: drive is still missing, we will escalate your device for immediate engineering action."

---

## 7. Do not do at L1

- Do not remove broad policy assignments.
- Do not change Intune script execution context.
- Do not apply registry/script fixes outside approved runbook.
- Do not close ticket only because one retry worked; link to incident until monitoring window ends.
