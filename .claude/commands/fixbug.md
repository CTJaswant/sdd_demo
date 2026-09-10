Fix this bug: $ARGUMENTS

1. Use the `investigator` subagent to find the root cause. Wait for its diagnosis.
2. Pass that diagnosis to the `fixer` subagent to make the minimal change.
3. Use the `verifier` subagent to run the tests.
4. If the verifier reports FAIL, send the failure back to `fixer` once to retry,
   then re-verify. If it still fails, stop and summarize for me.
5. When tests pass, give me a 3-line summary: cause, fix, test result.