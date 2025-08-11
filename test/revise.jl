# Inspired from https://gist.github.com/torfjelde/62c1281d5fc486d3a404e5de6cf285d4
# and Coluna.jl (https://github.com/atoptima/Coluna.jl/blob/master/test/revise.jl).

const REVISE_EVAL_ERROR_MESSAGE = """
    Revise does not support this operation.
    Need to restart julia session."""

"""
    _check_other_errors(e::Exception)::Bool

Display error to stderr and return whether execution should stop.
Returns `false` for most errors (continue execution).
"""
function _check_other_errors(e::Exception)::Bool
    showerror(stderr, e, catch_backtrace())
    return false
end

"""
    _check_other_errors(e::Base.Meta.ParseError)::Bool

Handle parse errors with simplified output (no stacktrace).
"""
function _check_other_errors(e::Base.Meta.ParseError)
    showerror(stderr, e)
    return false
end

"""
    _check_other_errors(e::TaskFailedException)::Bool

Handle task failures with simplified output (no stacktrace).
"""
function _check_other_errors(e::TaskFailedException)
    showerror(stderr, e)
    return false
end

"""
    _check_other_errors(e::TestSetException)::Bool

Handle test failures - test package already prints the error.
"""
_check_other_errors(e::TestSetException)::Bool = false

"""
    _check_other_errors(composite::CompositeException)::Bool

Handle composite exceptions by checking each individual exception.
"""
function _check_other_errors(composite::CompositeException)::Bool
    return any(e -> _check_other_errors(e), composite)
end

"""
    _execute_test_modules(test_modules::Vector, output_file::Union{String,Nothing}=nothing)

Clear terminal and run all test modules. If output_file is provided,
truncate it and redirect all output there.
"""
function _execute_test_modules(test_modules::Vector, ::Nothing)
    # Normal execution with terminal clear
    run(`clear`)
    for mod in test_modules
        mod.run()
    end
end

function _execute_test_modules(test_modules::Vector, output_file::String)
    # Truncate file and redirect output
    open(output_file, "w") do io
        redirect_stdio(stdout=io, stderr=io) do
            for mod in test_modules
                mod.run()
            end
        end
    end
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
        error(REVISE_EVAL_ERROR_MESSAGE)
    else
        return _check_other_errors(exception)
    end
end

"""
Runs test modules when tracked files or modules change.
Returns `true` if session restart is needed, `false` to continue.
"""
function run_tests_on_change!(test_modules_to_track_and_run::Vector, modules_to_track::Vector, output_file::Union{String,Nothing}=nothing)::Bool
    revise_errored = false
    while true
        try
            entr(
                [],
                [test_modules_to_track_and_run..., modules_to_track...];
                postpone = revise_errored,
                all = true,
            ) do
                return _execute_test_modules(test_modules_to_track_and_run, output_file)
            end
        catch e
            println("\e[1;37;41m ****** Exception caught $(typeof(e)) ******** \e[00m")
            _should_restart_session(e) && return true
            revise_errored = true
        end
    end
end
