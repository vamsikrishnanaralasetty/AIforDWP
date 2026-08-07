Resolved.

Cause: Post-migration mismatch between the original GPO user logon script behavior and the new Intune PowerShell script delivery behavior prevented drive S: from mapping during Finance user sign-in on DESKTOP-FB devices.

Action: Applied the recommended remediation to the migrated Intune mapping path, corrected delivery behavior for user-logon mapping requirements, re-applied script/policy behavior to affected DESKTOP-FB endpoints, and validated successful S: mapping at user logon.

Preventive: Enforce pre-cutover and post-cutover user-logon parity checks, explicit execution-context verification, pilot gates on representative Finance users/devices, and first-hour post-change mapped-drive monitoring.

User confirmed working.
