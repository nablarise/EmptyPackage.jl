# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Inspired from https://gist.github.com/torfjelde/62c1281d5fc486d3a404e5de6cf285d4
# and Coluna.jl (https://github.com/atoptima/Coluna.jl/blob/master/test/revise.jl).

using Dates, JSON

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


function _handle_error(e, io::IO)
    error_str = sprint(showerror, e)
    
    # Case 1: World Age Error -> Request a clean restart
    if occursin("@world", error_str)
        json_log(io, "status", 
            "status" => "error", 
            "type" => "world_age", 
            "action" => "restarting_request"
        )
        println(io, "\n[SYSTEM] World Age Error detected. Requesting restart (exit 100)...")
        exit(100) # Signal for the Bash script to restart
    
    # Case 2: Parse Error (Syntax) -> FATAL ERROR -> EXIT
    elseif e isa Base.Meta.ParseError
        json_log(io, "status", 
            "status" => "fatal_error", 
            "type" => "parse_error", 
            "message" => "Syntax error in source file. Exiting."
        )
        println(io, "\n[SYSTEM] Syntax Error detected. Exiting script (exit 1)...")
        showerror(io, e)
        exit(1) # Signal for the Bash script to terminate
        
    # Case 3: Standard errors (Test failures, runtime bugs) -> Keep running
    else
        json_log(io, "test_result", 
            "status" => "failed", 
            "error_message" => error_str
        )
        showerror(io, e)
    end
end

function run_revise_loop_with_redirection(
    test_modules::Vector,
    track_modules::Vector,
    output_file::String,
)::Bool
touch(output_file)
    revise_errored = false
    
    open(output_file, "a") do io
        json_log(io, "system", "message" => "Watcher started. Waiting for changes...")
    end

    while true
        try
            entr(
                [],
                [test_modules..., track_modules...];
                postpone = revise_errored,
                all = true,
            ) do
                open(output_file, "w") do io 
                    redirect_stdio(stdout=io, stderr=io) do
                        
                        json_log(io, "test_run_start")
                        start_time = time()
                        
                        try
                            for mod in test_modules
                                mod.run() 
                            end
                            
                            duration = round(time() - start_time, digits=3)
                            json_log(io, "test_run_end", 
                                "status" => "success", 
                                "duration" => duration
                            )
                            
                        catch e
                            _handle_error(e, io)
                        end
                        
                        json_log(io, "system", "state" => "idle", "message" => "Waiting for changes...")
                    end
                end
            end
        catch e
            # Critical crash in Revise or the watcher itself
            open(output_file, "a") do io
                 json_log(io, "critical_error", "message" => sprint(showerror, e))
            end
            # If the watcher itself crashes, we probably should exit too to be safe
            exit(1) 
        end
    end
end