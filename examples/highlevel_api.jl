import PAPI

const NUM_EVENTS = 2
const THRESHOLD = 10_000

function computation_mult()
    tmp = 1.0
    for i=1:THRESHOLD
        tmp *= i
    end
    return tmp
end

function computation_add()
    tmp = 0
    for i=1:THRESHOLD
        tmp += i
    end
    return tmp
end

function main()

    # Precompile functions so that we are also not
    # measuring compilation overhead
    precompile(computation_add, ())
    precompile(computation_mult,())

    cs = PAPI.EventSet([PAPI.TOT_INS, PAPI.TOT_CYC])

    info("There are $(PAPI.num_counters()) counters on this system")

    # Initialize the PAPI library and start counting
    # the events named in the events array.
    # This function implicitly stops and initializes
    # any counters running as a result of a previous call
    # to PAPI.start_counters()

    info("Counters started")
    PAPI.start_counters(cs)

    computation_add()

    values = PAPI.read_counters!(cs)

    @printf("The total instructions executed for addition are %lld \n",values[1]);
    @printf("The total cycles used are %lld \n", values[2] );
end

main()
