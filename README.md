# EmptyPackage

This is a simple Julia app with a single type, a single function, and a single test suite.

This app is intended to be used as a template for creating new Julia applications.

# Tests

Tests should be defined in modules.
These modules are loaded in your [current environment stack](https://docs.julialang.org/en/v1/manual/code-loading/#Environment-stacks) (i.e. in the `LOAD_PATH` variable) at the beginning of the `runtests.jl` script.
This operation allows us to track changes and run the tests easily.

## The Revise-Test Loop

The revise-test loop is a powerful workflow for Julia development that allows you to:
1. Make changes to your code
2. Automatically detect those changes
3. Run tests immediately to verify your changes work correctly
4. Continue development without restarting Julia

This workflow significantly speeds up development by eliminating the need to restart Julia sessions between code changes.

### Setting Up the Revise-Test Loop

Run the `./runtests.sh` script to start the revise-test loop.

This script:
- Calls the `test/runtests.jl` with the `"auto"` argument
- Uses the [Revise.jl](https://timholy.github.io/Revise.jl/stable/) package to track changes to your source and test files
- Automatically reruns tests when changes are detected
- Provides immediate feedback on whether your changes broke existing functionality

### Configuring What to Track and Test

You need to edit the `test/runtests.jl` file to configure the revise-test loop:

1. **Step 1 (automatic)**: The script automatically puts all test modules in the `LOAD_PATH`
2. **Step 2 (manual)**: Import your Application module
   ```julia
   using EmptyPackage
   ```
3. **Step 3 (manual)**: Import all test modules
   ```julia
   using EmptyPackageUnitTests
   ```
4. **Step 4 (manual)**: List in `MODULES_TO_TRACK` the modules to track for changes
   ```julia
   MODULES_TO_TRACK = [EmptyPackage]
   ```
5. **Step 5 (manual)**: List in `TEST_MODULES_TO_TRACK_AND_RUN` the test modules to track and run
   ```julia
   TEST_MODULES_TO_TRACK_AND_RUN = [EmptyPackageUnitTests]
   ```

With this setup, any changes to your source files in the tracked modules will trigger an automatic rerun of the specified test modules, giving you immediate feedback on your changes.

### Troubleshooting

To complete.

## Running Tests Without the Revise Loop

To run tests just once without the revise-test loop, run `]test` in the Julia REPL.
