import PAPI

function slow_code()
    tmp = 1.1
    for i=1:200_000_000
        tmp = (tmp+100)/i
    end
    return tmp
end

function main()
    precompile(slow_code, ())

    real_time, proc_time, flpins, mflips = @PAPI.flips slow_code()

    @printf("Real_time: %f Proc_time: %f Total flpins: %lld MFLIPS: %f\n",
             real_time, proc_time, flpins, mflips)
end

main()
