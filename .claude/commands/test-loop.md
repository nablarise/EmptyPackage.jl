---
description: Start the revise-test loop for continuous testing
---

Start the automatic test loop that watches for file changes and reruns tests.

**Steps:**

1. Start the revise-test loop in the background:
   - Run `./runtests.sh test/output.log` as a background process
   - Tests will write to `test/output.log`

2. Monitor test results:
   - Read and display the `test/output.log` file
   - Show test pass/fail status
   - Highlight any errors

3. Keep the loop running:
   - The loop continues running in the background
   - Tests automatically rerun when you save files in `src/` or `test/`
   - Remind user they can stop the loop by asking you to kill the background process

**Important:**
- Tests auto-rerun on file changes
- Parse errors exit the loop (requires manual restart)
- World age errors trigger automatic Julia restart
- Always show clear pass/fail status from the output file
