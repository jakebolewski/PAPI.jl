module PAPI

@osx_only error("PAPI.jl currently only works on Linux")
@windows_only error("PAPI.jl currently only works on Linux")

include("counters.jl")
include("retcodes.jl")

immutable PAPIError{R} <: Exception
    msg::String
end
PAPIError(R::RetCode) = PAPIError{R}(errmsg(R))

function __init__()
    # init the library and make sure that some counters are available
    if num_counters() <= 0
        error("PAPI init error: No counters are available on the current system")
    end
    atexit() do
        ccall((:PAPI_shutdown, :libpapi), Void, ())
    end
end

type CounterSet
    counters::Vector{Counter}
    vals::Vector{Clonglong}

    CounterSet(c::Vector{Counter}) = begin
        cs = new(c, zeros(Clonglong, length(c)))
        return cs
    end
end

#### High Level Interface ####

@doc """
""" -> 
is_initialized() = Bool(ccall((:PAPI_is_initialized, :libpapi), Cint, ()))

@doc """
Get the number of hardware counters available on the system

`PAPI.num_counters()` returns the optimal length of the values array for high-level functions.
This value corresponds to the number of hardware counters supported by the current substrate. 
`PAPI.num_counters()` initializes the PAPI library using `PAPI.library_init()` if necessary. 
""" ->
num_counters() = Int(ccall((:PAPI_num_counters, :libpapi), Cint, ()))

@doc """
Add current counts to array and reset counters
""" ->
function accum_counters!(values::Vector{Clonglong})
    ret = RetCode(ccall((:PAPI_accum_counters, :libpapi), Cint, 
                        (Ptr{Clonglong}, Cint), values, length(values)))
    if ret != OK
        throw(PAPIError(ret))
    end
end
accum_counters!(cs::CounterSet) = (accum_counters!(cs.vals); copy(cs.vals))

@doc """
Get the number of components available on the system
""" ->
num_components() = Int(ccall((:PAPI_num_components, :libpapi), Cint, ()))

@doc """
""" ->
function read_counters!(values::Vector{Clonglong})
    ret = RetCode(ccall((:PAPI_read_counters, :libpapi), Cint,
                        (Ptr{Clonglong}, Cint), values, length(values)))
    if ret != OK
        throw(PAPIError(ret))
    end
end
read_counters!(cs::CounterSet) = (read_counters!(cs.vals); copy(cs.vals))

@doc """
Start counting hardware events

`PAPI.start_counters()` initializes the PAPI library (if necessary) and starts counting the events named in the events array. 
This function implicitly stops and initializes any counters running as a result of a previous call to `PAPI.start_counters()`. 
It is the user's responsibility to choose events that can be counted simultaneously by reading the vendor's documentation.
The number of events should be no larger than the value returned by `PAPI.num_counters()`. 
""" ->
function start_counters(events::Vector{Counter}) 
    ret = RetCode(ccall((:PAPI_start_counters, :libpapi), Cint, 
                        (Ptr{Cint}, Cint), pointer(events), length(events)))
    if ret != OK
        throw(PAPIError(ret))
    end
end
start_counters(cs::CounterSet) = start_counters(cs.counters)

@doc """
Stop counters and return current counts
""" ->
function stop_counters(events::Vector{Counter}) 
    ret = RetCode(ccall((:PAPI_stop_counters, :libpapi), Cint, 
                        (Ptr{Cint}, Cint), pointer(events), length(events)))
    if ret != OK
        throw(PAPIError(ret))
    end
end
stop_counters(cs::CounterSet) = stop_counters(cs.counters)

@doc """
Get Mflips/s (floating point instruction rate), real time and processor time
""" ->
function flips!(rtime, ptime, flpins, mflips)
    ret = RetCode(ccall((:PAPI_flips, :libpapi), Cint,
                        (Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                        rtime, ptime, flpins, mflips))
    if ret != OK
        throw(PAPIError(ret))
    end
end

@doc """
Get Mflips/s (floating point instruction rate), real time and processor time
""" ->
const flips = let rtime = Cfloat[0.0], 
                  ptime = Cfloat[0.0],
                  flpins = Clonglong[0], 
                  mflips = Cfloat[0.0]
    
     flips() = begin
        flips!(rtime, ptime, flpins, mflips)
        return (rtime[1], ptime[1], flpins[1], mflips[1])
    end
end

macro flips(blk)
    :(PAPI.flips(); $(esc(blk)); PAPI.flips())
end

@doc """
Get Mflop/s (floating point operand rate), real time and processor time
""" ->
function flops!(rtime, ptime, flpops, mflops)
    ret = RetCode(ccall((:PAPI_flops, :libpapi), Cint,
                        (Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                        rtime, ptime, flpops, mflops))
    if ret != OK
        throw(PAPIError(ret))
    end
end

@doc """
Get Mflop/s (floating point operand rate), real time and processor time
""" ->
const flops = let rtime = Cfloat[0.0], 
                  ptime = Cfloat[0.0],
                  flpops = Clonglong[0], 
                  mflops = Cfloat[0.0]
    flops() = begin
        flops!(rtime, ptime, flpops, mflops)
        return (rtime[1], ptime[1], flpops[1], mflops[1])
    end
end
 
macro flops(blk)
    :(PAPI.flops(); $(esc(blk)); PAPI.flops())
end


@doc """
Get instructions per cycle, real time and processor time
""" ->
function ipc(rtime, ptime, ins, ipc)
    ret = RetCode(ccall((:PAPI_ipc, :libpapi), Cint,
                        (Ptr{Void}, Ptr{Cfloat}, Ptr{Clonglong}, Ptr{Cfloat}),
                        rtime, ptime, ins, ipc))
    if ret != OK
        throw(PAPIError(ret))
    end
end

@doc """
Get events per cycle, real time and processor time
""" ->
function epc(event, rtime, ptime, ref, core, evt, epc)
    ret = RetCode(ccall((:PAPI_epc, :libpapi), Cint,
                        (Cint, Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Clonglong}, 
                         Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cfloat}),
                        event, rtime, ptime, ref, core, evt, epc))
    if ret != OK
        throw(PAPIError(ret))
    end
end  

end # module
