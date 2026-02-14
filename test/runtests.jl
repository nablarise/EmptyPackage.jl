# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
using JSON

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
TEST_MODULES = [
    EmptyPackageUnitTests
]
########

# If run via "runtests.sh auto <file>"
if length(ARGS) >= 1 && ARGS[1] == "auto"
    # Parse arguments
    raw_output_file = length(ARGS) >= 2 ? ARGS[2] : ""
    output_dest = isempty(raw_output_file) ? nothing : raw_output_file
    format = length(ARGS) >= 3 ? ARGS[3] : "jsonl"

    # Launch infinite loop (never returns unless exit is called)
    run_revise_loop_with_redirection(TEST_MODULES, MODULES_TO_TRACK, output_dest, format) 
else
    # Manual mode (CI/CD or direct launch)
    for mod in TEST_MODULES
        mod.run()
    end
end