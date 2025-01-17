
"""
    print_callback(state,storage)

Handles formating of the callback state into a table format with consistent length independent of state values.
"""
function print_callback(data, format_string; print_header=false, print_footer=false)
    print_formatted(fmt, args...) = @eval @printf($fmt, $(args...))
    if print_header || print_footer
        temp = strip(format_string, ['\n'])
        temp = replace(temp, "%" => "")
        temp = replace(temp, "e" => "")
        temp = replace(temp, "i" => "")
        temp = replace(temp, "s" => "")
        temp = split(temp, " ")
        len = 0
        for i in temp
            len = len + parse(Int, i)
        end
        lenHeaderFooter = len + 2 + length(temp) - 1
        if print_footer
            line = "-"^lenHeaderFooter
            @printf("%s\n", line)
        end
        if print_header
            line = "-"^lenHeaderFooter
            @printf("\n%s\n", line)
            s_format_string = replace(format_string, "e" => "s")
            s_format_string = replace(s_format_string, "i" => "s")
            print_formatted(s_format_string, data...)
            @printf("%s\n", line)
        end
    else
        print_formatted(format_string, data...)
    end
end

"""
    make_print_callback(callback, print_iter, headers, format_string, format_state)

Default verbose callback for fw_algorithms, that wraps around previous callback.
Prints the state to the console after print_iter iterations.
If the callback to be wrapped is of type nothing, always return true to enforce boolean output for non-nothing callbacks.
"""
function make_print_callback(callback, print_iter, headers, format_string, format_state)
    return function callback_with_prints(state, args...)
        if (state.tt == pp || state.tt == last)
            if state.t == 0 && state.tt == last
                print_callback(headers, format_string, print_header=true)
            end
            rep = format_state(state, args...)
            print_callback(rep, format_string)
            print_callback(nothing, format_string, print_footer=true)
            flush(stdout)
        elseif state.t == 1 || mod(state.t, print_iter) == 0 || state.tt == dualstep || state.tt == last
            if state.t == 1 
                state = @set state.tt = initial
                print_callback(headers, format_string, print_header=true)
            end
            rep = format_state(state, args...)
            print_callback(rep, format_string)
            flush(stdout)
        end

        if callback === nothing
            return true
        end
        return callback(state, args...)
    end
end


"""
    make_trajectory_callback(callback, traj_data)

Default trajectory logging callback for fw_algorithms, that wraps around previous callback.
Adds the state to the storage variable.
The state data is only the 5 first fields, usually:
`(t, primal, dual, dual_gap, time)`
If the callback to be wrapped is of type nothing, always return true to enforce boolean output for non-nothing callbacks.
"""
function make_trajectory_callback(callback, traj_data::Vector)
    return function callback_with_trajectory(state, args...)
        if state.tt !== last || state.tt !== pp
            push!(traj_data, callback_state(state))
        end
        if callback === nothing
            return true
        end
        return callback(state, args...)
    end
end
