---
description: Check the latest test results from the revise-test loop
---

Check the most recent test output from the revise-test loop.

**Steps:**

1. Check if `test/output.log` exists:
   - If it doesn't exist, inform user no test output found
   - Suggest they run `/test-loop` first

2. Read and display the test results:
   - Read the `test/output.log` file
   - Show the test pass/fail status
   - Highlight any errors or failures
   - Show the test summary

3. Interpret the results:
   - Clearly state if tests PASSED or FAILED
   - If failed, show which tests failed and why
   - If the file shows a parse error or world age error, explain what it means

**Important:**
- Always show clear pass/fail status
- If tests are currently running, the file may be incomplete
- This command is useful when the test loop is running in the background
