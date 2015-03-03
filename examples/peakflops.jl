import PAPI

function main()
    cs = PAPI.CounterSet([PAPI.TOT_INS])
 
    PAPI.start_counters(cs)
    start = PAPI.read_counters!(cs)

    peakflops()

    stop = PAPI.accum_counters!(cs)
    PAPI.stop_counters(cs)
    
    ninst = Int(stop[1]) - Int(stop[1])
    println("Computed peakflops in $(ninst) instructions")
end

main()
