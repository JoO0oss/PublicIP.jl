import Dates
import Random

# Minimum number of hours between cache refreshes.
const CACHE_CYCLE = 12
const CACHE_LOCATION = joinpath(@__DIR__, "cache")  # Same as "$(pwd())/cache".

show_error = false
force_curl = false
show_newline = true
show_source = false

success = 0  # This stores whether the program succeeded, also sed as an exit code.

"Return ip, date and source from the cache file. This function does not check the data or that the file exists."
function read_cache()::Tuple{String, Dates.DateTime, String}
    ip_str, date_str, source = readlines(CACHE_LOCATION)
    
    cached_time = Dates.DateTime(date_str, "yyyy-mm-dd HH:MM:ss")
    
    return ip_str, cached_time, source
end

"Pass in an IP address, and it gets written to the cache file along with the current time."
function write_cache(ip_string::String, source::String)
    date_string = Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:ss")
    
    text = join([ip_string, date_string, source], "\n")
    open(CACHE_LOCATION, "w") do file
        text = write(file, text)
    end
end

"A function that is called when some form of fault is detected in connection information."
function connection_error()::String
    return "Connection error."
end

"Determines whether a given string is in the form of an IPv4 address."
function is_ip(ip_addr::String)::Bool
    vals = split(ip_addr, '.')
    if length(vals) != 4
        return false
    end
    
    nums::Array{UInt8, 1} = Array{UInt8, 1}(undef, 4)
    try
        nums = [parse(UInt8, val) for val in vals]
    catch err
        if isa(err, ArgumentError) || isa(err, OverflowError)
            # These two exceptions should only occur if the string is not an IP address.
            return false
        else
            rethrow(err)
        end
    end
    
    return true
end

# These are just different websites I have found that can be used if one or two go down.

# Don't use this one.
function attempt0()::String
    return "127.0.0.1"
end

function attempt1()::String
    return read(`curl -s ifconfig.me`, String)
end

function attempt2()::String
    # Just chomp() to remove the new line at the end in this case.
    return chomp(read(`curl -s icanhazip.com`, String))
end

function attempt3()::String
    return read(`curl -s ipecho.net/plain`, String)
    # You can try to use just ipecho.net, and decode the html yourself if something happens to
    # ipecho.net/plain.
end

function attempt4()::String
    text = read(`curl -s ipinfo.io`, String)

    text = strip(text, ['{', '}', '\n'])
    text = replace(text, "\"" => "")
    text = replace(text, " " => "")
    lines = [strip(line, ',') for line in split(text, '\n')]
    
    # "ip": "..." should be on the first line, but if it isn't, just go through all of them.
    for line in lines
        pair = split(line, ':', limit=2)
        if pair[1] == "ip"
            return pair[2]
        end
    end
    return "incomprehensible data"
end

SOURCES = Dict(
        "ifconfig.me" => attempt1,
        "icanhazip.com" => attempt2,
        "ipecho.net" => attempt3,
        "ipinfo.io" => attempt4,
)

"Returns the network's public IP address and the server it used to determine it."
function get_public_ip()::Tuple{String, String}
    global success
    # Try to reduce strain on any one server. Comment out and choose order in SOURCES if more
    # precise behaviour is needed.
    sources_ordered = Random.shuffle([source for source in SOURCES])
    
    # Each pair in sources_ordered stores the name of the server and the function to read info from
    # that server.
    for pair in sources_ordered
        source, attempt_func = pair
        
        try
            ip_addr = attempt_func()
            success = 0
            
            if show_error
                # Just show that the `curl` command worked, not necessarily that the data is valid.
                println("Recieved data from `$(source)`.")
            end
            return ip_addr, source
        catch err
            success = -1
            
            if show_error
                println("publicip.jl caught the following error when connecting to `$(source)`:")
                showerror(stdout, err)
            end
        end
    end
end

"Tries to get cached data where it can, and formats the output according to the command line options."
function read_ip()::String
    use_cache = true

    output = ""
    source = ""

    cached_ip = ""
    cached_date = Dates.DateTime(1, 1, 1)
    cached_source = ""

    # If there is no cache file at all,
    if isfile(CACHE_LOCATION)
        try
            cached_ip, cached_date, cached_source = read_cache()
        catch err
            use_cache = false  # if the cached data is not readable,
        end
    else
        use_cache = false
    end
    if !is_ip(cached_ip)
        use_cache = false  # if the cached IP is not useable,
    end
    if Dates.now() - cached_date > Dates.Hour(CACHE_CYCLE)
        use_cache = false  # or if the cached IP was last updated too long ago,
    end
    
    if force_curl
        use_cache = false
    end
    
    if use_cache
        output = cached_ip
        source = cached_source
    else
        output, source = get_public_ip()  # then generate a new value for the IP address.
        # Only overwrite cache if your new IP address is valid.
        if is_ip(output)
            write_cache(output, source)
        end
    end
    
    if show_source
        if use_cache
            output = "IP Address: $(output)\nServer used: $(source)  \t(results from cache)\n"
        else
            output = "IP Address: $(output)\nServer used: $(source)\n"
        end
    elseif show_newline && !show_error
        # newline options have no effect if source-showing or error-showing options are set true.
        output *= "\n"
    end
    
    return output
end

function main()
    global show_error
    global force_curl
    global show_newline
    global show_source
    
    if "-h" in ARGS || "--help" in ARGS || "--version" in ARGS
        if "--version" in ARGS
            print("""PublicIP.jl version 1.0.0
A command line tool to get the public IP address of your network.
- github link: https://github.com/JoO0oss/PublicIP.jl
""")
        else
            print("""PublicIP.jl help menu:
-e   --error        to show outputs to help troubleshoot errors.
-f   --force        to force the use of servers instead of cached data.
-h   --help         show this help screen.
-v   --verbose      show a bit more about where/how the output was produced.
     --version      show version information.
""")
        end
    else
        if length(ARGS) > 0
            if "-e" in ARGS || "--error" in ARGS
                show_error = true
            end
            if "-f" in ARGS || "--force" in ARGS
                force_curl = true
            end
            if "-n" in ARGS || "--no-newline" in ARGS
                show_newline = false
            end
            if "-v" in ARGS || "--verbose" in ARGS
                show_source = true
            end
        end
        print(read_ip())
    end
end

main()
