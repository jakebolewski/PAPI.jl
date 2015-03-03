import PAPI

function slow_code()
    tmp = 1.1
    for i=1:200_000_000
        tmp = (tmp+100)/i
    end
    return tmp
end

function driver()
    real_time = Cfloat[0.0]
    proc_time = Cfloat[0.0]
    mflops = Cfloat[0.0]
    flpops = Clonglong[0]
    
    PAPI.flops(real_time,proc_time,flpops,mflops)
    slow_code()
    PAPI.flops(real_time, proc_time, flpops, mflops)
    
    @printf("Real_time: %f Proc_time: %f Total flpops: %lld MFLOPS: %f\n", 
             real_time[1], proc_time[1], flpops[1], mflops[1])
end
driver()
