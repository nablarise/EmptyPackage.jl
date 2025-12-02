# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Inspired from https://gist.github.com/torfjelde/62c1281d5fc486d3a404e5de6cf285d4
# and Coluna.jl (https://github.com/atoptima/Coluna.jl/blob/master/test/revise.jl).

const REVISE_EVAL_ERROR_MESSAGE = """
    Revise does not support this operation.
    Need to restart julia session."""

"""
    _is_world_age_error(exception::Exception)::Bool

Detect if an exception is a world age error by checking if the error message
contains '@world'. World age errors occur when struct definitions change during
runtime and Julia cannot safely call methods defined in the old world age.
"""
function _is_world_age_error(exception)::Bool
    error_string = sprint(showerror, exception)
    return occursin("@world", error_string)
end

"""
    _check_other_errors(e::Exception)::Bool

Display error to stderr and return whether execution should stop.
Returns `true` if world age error detected, `false` otherwise.
"""
function _check_other_errors(e::Exception)::Bool
    if _is_world_age_error(e)
        println(stderr, "World age error detected.")
        println(stderr, "Restarting Julia session...")
        showerror(stderr, e, catch_backtrace())
        return true
    else
        showerror(stderr, e, catch_backtrace())
        return false
    end
end

"""
    _check_other_errors(e::Base.Meta.ParseError)::Bool

Handle parse errors with simplified output (no stacktrace).
Exit the loop.
"""
function _check_other_errors(e::Base.Meta.ParseError)
    showerror(stderr, e, catch_backtrace())
    exit(1)
end

"""
    _check_other_errors(e::MethodError)::Bool

Handle task failures with simplified output (no stacktrace).
"""
function _check_other_errors(e::MethodError)::Bool
    showerror(stderr, e)
    return false
end

"""
    _check_other_errors(e::Method)::Bool

Handle task failures with simplified output (no stacktrace).
"""
function _check_other_errors(e::TaskFailedException)::Bool
    return _check_other_errors(e.task.result)
end

"""
    _check_other_errors(e::TestSetException)::Bool

Handle test failures - test package already prints the error.
"""
function _check_other_errors(e::TestSetException)::Bool
    world_age_error = any(err_or_fail -> _is_world_age_error(err_or_fail), e.errors_and_fails)
    showerror(stderr, e)
    return world_age_error
end

"""
    _check_other_errors(composite::CompositeException)::Bool

Handle composite exceptions by checking each individual exception.
"""
function _check_other_errors(composite::CompositeException)::Bool
    return any(e -> _check_other_errors(e), composite)
end

"""
    _should_restart_session(exception::Exception)::Bool

Determine whether the Julia session should be restarted based on exception type.
Returns `true` for InterruptException or throws for ReviseEvalException.
"""
function _should_restart_session(exception::Exception)::Bool
    if isa(exception, InterruptException)
        return true
    elseif isa(exception, Revise.ReviseEvalException)
        println(stderr, "ERROR: LoadError: ", REVISE_EVAL_ERROR_MESSAGE)
        return true
    else
        return _check_other_errors(exception)
    end
end

"""
Runs test modules when tracked files or modules change.
Returns `true` if session restart is needed, `false` to continue.
"""
function run_tests_on_change!(
    test_modules_to_track_and_run::Vector,
    modules_to_track::Vector,
    output_file::String,
)::Bool
    # Redirect ALL output to file, including error messages
    _run_revise_loop_with_redirection(test_modules_to_track_and_run, modules_to_track, output_file)
    return true
end

function run_tests_on_change!(
    test_modules_to_track_and_run::Vector,
    modules_to_track::Vector,
    ::Nothing,
)::Bool
    return _run_revise_loop(test_modules_to_track_and_run, modules_to_track)
end

function _run_revise_loop_with_redirection(
    test_modules_to_track_and_run::Vector,
    modules_to_track::Vector,
    output_file::String,
)::Bool
    revise_errored = false
    while true
        try
            entr(
                [],
                [test_modules_to_track_and_run..., modules_to_track...];
                postpone = revise_errored,
                all = true,
            ) do
                open(output_file, "w") do io
                    redirect_stdio(; stdout = io, stderr = io) do
                        for mod in test_modules_to_track_and_run
                            mod.run()
                        end
                    end
                end
            end
        catch e
            restart_session = false
            open(output_file, "a") do io
                redirect_stdio(; stdout = io, stderr = io) do
                    println("\e[1;37;41m ****** Exception caught $(typeof(e)) ******** \e[00m")
                    restart_session = _should_restart_session(e) 
                end
            end
            restart_session && return true
            revise_errored = true
        end
    end
end

function _run_revise_loop(
    test_modules_to_track_and_run::Vector,
    modules_to_track::Vector,
)::Bool
    revise_errored = false
    while true
        try
            entr(
                [],
                [test_modules_to_track_and_run..., modules_to_track...];
                postpone = revise_errored,
                all = true,
            ) do
                run(`clear`)
                for mod in test_modules_to_track_and_run
                    mod.run()
                end
            end
        catch e
            restart_session = false
            println("\e[1;37;41m ****** Exception caught $(typeof(e)) ******** \e[00m")
            _should_restart_session(e) && return false
            revise_errored = true
        end
    end
end
