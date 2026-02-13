# EmptyPackage

Julia package template with revise-test loop for fast iterative development.

## Tests

Tests are organized in modules (one per test suite) and loaded into your `LOAD_PATH` at the start of `runtests.jl`. Each test module must have a `run()` function.

## Revise-Test Loop

Automatically runs tests when code changes—no Julia restart needed:
1. Edit code → 2. [Revise.jl](https://timholy.github.io/Revise.jl/stable/) detects changes → 3. Tests run → 4. Continue coding

**Start the loop:**
```bash
./runtests.sh                    # Output to terminal
./runtests.sh test/output.log    # Redirect to test/output.log (truncated each run)
```

**Configure in `test/runtests.jl`:**
```julia
# Step 2: Import your package
using EmptyPackage

# Step 3: Import test modules
using EmptyPackageUnitTests

# Step 4: List modules to track for changes
MODULES_TO_TRACK = [EmptyPackage]

# Step 5: List test modules to track and run
TEST_MODULES = [EmptyPackageUnitTests]
```

Each test module needs a `run()` function that executes all tests in that module.

**Run tests once (no revise loop):**
```julia
] test                  # Terminal output
] test output.log       # File output
```

## For AI Coding Agents (Claude-code)

This package uses an automatic test-rerun workflow with two interaction modes:

**Expected Behavior:**
- ✅ Regular test failures: Continue watching, fix and save to retry
- ⚠️ World age errors: Auto-restart Julia (wait ~5 seconds)
- ❌ Parse errors: Exit loop, manual restart required after fix

### JSONL Log Architecture

When using file output mode (`./runtests.sh test/output.log`), logs are structured as [JSON Lines](https://jsonlines.org/) for reliable parsing:

**Exit Codes:**
- `0` - Clean exit (Ctrl+C)
- `1` - Fatal error (parse error detected)
- `100` - Restart request (world age error)

**Event Types:**
```jsonl
{"event":"system","state":"idle","message":"Waiting for changes..."}
{"event":"test_run_start","timestamp":"2026-02-13T22:58:35.501"}
{"event":"test_run_end","status":"success","duration":0.266}
{"event":"test_result","status":"failed","error_message":"..."}
{"event":"critical_error","message":"ParseError: ..."}
```

**Parsing Strategy:**
- Each line is a valid JSON object
- Use `JSON.parse()` per line, not regex
- Filter by `event` field for specific information
- The file is **overwritten** (mode `w`) on each test run—no infinite history
