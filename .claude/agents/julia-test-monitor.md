# Julia Test Monitor Agent

**Agent Type:** `julia-test-monitor`

**Purpose:** Monitor and interact with Julia package tests running in the revise-test loop, analyze test failures, and help debug issues.

## When to Use This Agent

Use this agent when:
- Tests are failing and you need to understand why
- You want to monitor the revise-test loop output
- You need to analyze test results and suggest fixes
- You're debugging test issues in real-time
- You want to check if recent code changes broke tests

## Agent Capabilities

This agent should be able to:

1. **Monitor Test Output**
   - Read test/output.log or terminal output
   - Parse Julia test results (@testset output)
   - Identify passing and failing tests
   - Track test status over time

2. **Analyze Failures**
   - Parse stack traces from failed tests
   - Identify the root cause of failures
   - Find the relevant source code lines
   - Suggest potential fixes

3. **Revise-Test Loop Integration**
   - Check if revise loop is running (look for Julia processes)
   - Start/stop the revise loop via runtests.sh
   - Monitor for world age errors (triggers Julia restart)
   - Track test output files

4. **Reporting**
   - Summarize test results (X passed, Y failed)
   - Show which test modules are failing
   - Highlight error messages clearly
   - Compare results across test runs

## Example Usage

```
User: "Check if my tests are passing"
Agent: *Reads test/output.log*
Agent: "Tests are failing. 3/5 tests passed. Failures in:
- EmptyPackageUnitTests.test_foo: Expected 42, got 41
- EmptyPackageUnitTests.test_bar: MethodError: no method matching baz(::String)

Would you like me to investigate these failures?"
```

```
User: "Start monitoring my tests"
Agent: *Starts runtests.sh in background with output.log*
Agent: "Revise-test loop started. Monitoring test/output.log..."
Agent: *Periodically checks output and reports status*
Agent: "Tests passed! ✓ All 5 tests in EmptyPackageUnitTests passed."
```

## Implementation Notes

- Should have access to all tools (Read, Grep, Bash, etc.)
- Should understand Julia test output format (@testset, @test)
- Should be able to parse Julia stack traces
- Should work with the EmptyPackage.jl revise-test loop pattern
- Should detect world age errors and handle Julia restarts gracefully
