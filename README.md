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
TEST_MODULES_TO_TRACK_AND_RUN = [EmptyPackageUnitTests]
```

Each test module needs a `run()` function that executes all tests in that module.

**Run tests once (no revise loop):**
```julia
] test                  # Terminal output
] test output.log       # File output
```

