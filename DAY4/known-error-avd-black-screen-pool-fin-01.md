Symptom     : Users in the Finance AVD pool saw a black screen after successful sign-in. For some sessions it cleared after about 30 seconds, while others disconnected and retried.

Cause       : A graphics/render stack regression in the POOL-FIN-01 image update caused dwm.exe to crash in igdumd64.dll during session initialization after logon.

Scope       : Impact was on POOL-FIN-01, with approximately 40% of users affected. POOL-FIN-02 was not updated and was unaffected.

Workaround  : Contain affected POOL-FIN-01 hosts and route users to known-good capacity where available. Apply the graphics/render mitigation path and recover impacted hosts, then validate logons before reopening hosts.

Permanent fix: Use a corrected image with a validated graphics/render stack and keep a known-good baseline for rapid redeploy. Enforce image promotion guardrails and ringed rollout so deployment halts if post-logon DWM crash signatures appear.

How to spot it: On affected hosts, look for Event 21 (logon success) followed by Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll (exception 0xc0000005), then DWM Event 9009 and LSM Event 40 disconnects. In unaffected comparison hosts, DWM Event 9011 appears and matching Event 1000 crashes are absent in the same window.
