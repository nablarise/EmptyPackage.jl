######## Step 1: define test modules.
#
# Each test suite (unit, integration, e2e) should be a in a specific module and
# exposed by a `run` method.
# The module is loaded from a specific file.
# Example : if you want to run unit tests, you must define them in a `EmptyPackageUnitTests`
# subodule that contains a `run` method to run them all.
# The `EmptyPackageUnitTests` module is loaded from the file `EmptyPackageUnitTests/EmptyPackageUnitTests.jl`.$
# The folder and file must share the same name (like a package).

# Put all test modules in the LOAD_PATH.
# Trick from:
# https://discourse.julialang.org/t/basic-revise-jl-usage-when-developing-a-module/19140/16
for submodule in filter(item -> isdir(joinpath(@__DIR__, item)), readdir())
    push!(LOAD_PATH, joinpath(@__DIR__, submodule))
end
########

using Revise
using Test

######## Step 2: set the name of your app.
using EmptyPackage
########

######## Step 3: use test modules
using EmptyPackageUnitTests
########

# Load the script that contains the method that tracks the changes and runs
# the tests.
include("revise.jl")

######## Step 4: Put all the modules to track here.
MODULES_TO_TRACK = [
    EmptyPackage
]
########

######## Step 5: Put all the test modules to track and run here.
TEST_MODULES_TO_TRACK_AND_RUN = [
    EmptyPackageUnitTests
]
########

# The first argument is "auto" when the script is run from the shell.
# The second argument is an optional output filename for redirection.
# Take a look at `runtests.sh`.
if length(ARGS) >= 1 && ARGS[1] == "auto"
    output_file = length(ARGS) >= 2 ? ARGS[2] : nothing
    while run_tests_on_change!(
        TEST_MODULES_TO_TRACK_AND_RUN,
        MODULES_TO_TRACK,
        output_file
    ) end
    exit(222)
else
    output_file = length(ARGS) >= 1 ? ARGS[1] : nothing
    if output_file !== nothing
        open(output_file, "w") do io
            redirect_stdio(stdout=io, stderr=io) do
                for mod in TEST_MODULES_TO_TRACK_AND_RUN
                    mod.run()
                end
            end
        end
    else
        for mod in TEST_MODULES_TO_TRACK_AND_RUN
            mod.run()
        end
    end
end
