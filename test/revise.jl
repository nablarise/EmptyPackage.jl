# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Inspired from https://gist.github.com/torfjelde/62c1281d5fc486d3a404e5de6cf285d4
# and Coluna.jl (https://github.com/atoptima/Coluna.jl/blob/master/test/revise.jl).

using Dates, JSON, Test

"""
    json_log(io::IO, event::String, data::Pair...)

Write a log entry in valid JSONL format.
Uses JSON.jl to ensure correct formatting (escaping, types, etc.).
"""
function json_log(io::IO, event::String, data::Pair...)
    # Construct the dictionary
    log_entry = Dict{String, Any}(
        "event" => event,
        "timestamp" => string(now()), # ISO 8601 default via string()
        data...
    )

    # Clean serialization via JSON.jl
    JSON.print(io, log_entry)
    println(io) # Newline for JSONL format
    flush(io)
end

"""
    log_output(io::IO, format::String, event::String, data::Pair...)

Dispatch to appropriate formatter based on format type.
"""
function log_output(io::IO, format::String, event::String, data::Pair...)
    if format == "plain"
        log_plain(io, event, data...)
    else
        json_log(io, event, data...)
    end
end

"""
    log_plain(io::IO, event::String, data::Pair...)

Human-readable plain text logging for interactive terminal use.
"""
function log_plain(io::IO, event::String, data::Pair...)
    data_dict = Dict(data...)

    if event == "system"
        # System messages (e.g., "Waiting for changes...")
        message = get(data_dict, "message", "")
        state = get(data_dict, "state", "")
        if state == "idle"
            println(io, "\n⏳ $message")
        else
            println(io, "ℹ️  $message")
        end

    elseif event == "test_run_start"
        println(io, "\n🔄 Running tests...")

    elseif event == "test_result"
        # Test results for a module
        mod = get(data_dict, "module", "")
        status = get(data_dict, "status", "")
        passed = get(data_dict, "passed", 0)
        failed = get(data_dict, "failed", 0)
        errored = get(data_dict, "errored", 0)
        broken = get(data_dict, "broken", 0)

        icon = status == "success" ? "✓" : "✗"
        println(io, "\n$mod: $icon ($passed passed, $failed failed, $errored errored, $broken broken)")

    elseif event == "test_run_end"
        # Overall test run summary
        status = get(data_dict, "status", "")
        duration = get(data_dict, "duration", 0.0)

        if status == "success"
            println(io, "\n✅ All tests passed ($(duration)s)")
        else
            println(io, "\n❌ Some tests failed ($(duration)s)")
        end

    elseif event == "test_error"
        # Runtime test errors
        error_msg = get(data_dict, "error", "")
        println(io, "\n⚠️  Test Error:")
        println(io, error_msg)

    elseif event == "critical_error"
        # Critical errors (parse, world age, etc.)
        error_type = get(data_dict, "type", "")
        action = get(data_dict, "action", "")
        error_msg = get(data_dict, "error", get(data_dict, "message", ""))

        println(io, "\n🚨 Critical Error ($error_type)")
        println(io, "Action: $action")
        println(io, error_msg)

    else
        # Fallback for unknown events
        println(io, "Event: $event")
        for (k, v) in data_dict
            println(io, "  $k: $v")
        end
    end

    flush(io)
end


function _handle_error(e, io::IO, format::String)
    # Capture full error with stacktrace as string
    error_str = sprint(showerror, e, catch_backtrace())

    # Case 1: World Age Error -> Request a clean restart
    if occursin("@world", error_str)
        log_output(io, format, "critical_error",
            "type" => "world_age",
            "action" => "restarting",
            "error" => error_str
        )
        exit(100)

    # Case 2: Parse Error (Syntax) -> FATAL ERROR -> EXIT
    elseif e isa Base.Meta.ParseError
        log_output(io, format, "critical_error",
            "type" => "parse_error",
            "action" => "exiting",
            "error" => error_str
        )
        exit(1)

    # Case 3: Standard errors (Test failures, runtime bugs) -> Keep running
    else
        log_output(io, format, "test_error",
            "type" => "runtime_error",
            "error" => error_str
        )
    end
end

"""
    _run_tests_core(io::IO, test_modules, format)

Core logic to execute tests and log results.
Extracted to avoid duplication between file and stdout modes.
"""
function _run_tests_core(io::IO, test_modules::Vector, format::String)
    log_output(io, format, "test_run_start")
    start_time = time()

    try
        # Suppress Test.jl's default printing for JSONL, allow for plain text
        # Note: This is internal Julia API, might be fragile but necessary here.
        Test.TESTSET_PRINT_ENABLE[] = (format == "plain")

        all_passed = true
        for mod in test_modules
            ts = nothing
            exception_caught = false
            try
                ts = mod.run()  # Capture testset return value
            catch e
                if e isa Test.TestSetException
                    # TestSetException has fields: pass, fail, error, broken
                    exception_caught = true
                    all_passed = false

                    log_output(io, format, "test_result",
                        "module" => string(mod),
                        "passed" => e.pass,
                        "failed" => e.fail,
                        "errored" => e.error,
                        "broken" => e.broken,
                        "status" => "failed"
                    )
                else
                    # Unexpected error - rethrow to outer handler
                    rethrow()
                end
            end

            # If no exception was caught, log successful testset results
            if !exception_caught && ts !== nothing
                # Count test results manually from the TestSet object
                n_failed = count(r -> r isa Test.Fail, ts.results)
                n_errored = count(r -> r isa Test.Error, ts.results)
                n_broken = count(r -> r isa Test.Broken, ts.results)

                log_output(io, format, "test_result",
                    "module" => string(mod),
                    "passed" => ts.n_passed,
                    "failed" => n_failed,
                    "errored" => n_errored,
                    "broken" => n_broken,
                    "status" => (n_failed == 0 && n_errored == 0) ? "success" : "failed"
                )

                if n_failed > 0 || n_errored > 0
                    all_passed = false
                end
            end
        end

        duration = round(time() - start_time, digits=3)
        log_output(io, format, "test_run_end",
            "status" => all_passed ? "success" : "failed",
            "duration" => duration
        )

    catch e
        _handle_error(e, io, format)
    end

    log_output(io, format, "system", "state" => "idle", "message" => "Waiting for changes...")
end

"""
    run_revise_loop_with_redirection(test_modules, track_modules, output_file, format)

Main loop that watches files and triggers tests.
- If output_file is a String: writes to that file (truncate mode).
- If output_file is nothing: writes to stdout.
"""
function run_revise_loop_with_redirection(
    test_modules::Vector,
    track_modules::Vector,
    output_file::Union{String, Nothing}, 
    format::String="jsonl",
)::Bool
    # Initial startup message
    if !isnothing(output_file)
        touch(output_file)
        open(output_file, "a") do io
            log_output(io, format, "system", "message" => "Watcher started. Logs redirected to file.")
        end
    else
        log_output(stdout, format, "system", "message" => "Watcher started. Output to terminal.")
    end

    revise_errored = false

    while true
        try
            entr(
                [],
                [test_modules..., track_modules...];
                postpone = revise_errored,
                all = true,
            ) do
                if !isnothing(output_file)
                    # FILE MODE: Open, write/truncate, and redirect stdout/stderr
                    # We use "w" to clear the log file on each run, keeping it clean for the AI agent.
                    open(output_file, "w") do io
                        redirect_stdio(stdout=io, stderr=io) do
                            _run_tests_core(io, test_modules, format)
                        end
                    end
                else
                    # TERMINAL MODE: Write directly to stdout
                    # No redirection needed, Julia writes to stdout by default.
                    _run_tests_core(stdout, test_modules, format)
                end
            end
        catch e
            # Critical crash in Revise or the watcher itself
            io_target = isnothing(output_file) ? stdout : open(output_file, "a")
            try
                log_output(io_target, format, "critical_error", "message" => sprint(showerror, e))
            finally
                if !isnothing(output_file)
                    close(io_target)
                end
            end
            # If the watcher itself crashes, we probably should exit too to be safe
            exit(1)
        end
    end
end