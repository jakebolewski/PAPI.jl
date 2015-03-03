import PAPI

function slow_code()
    tmp = 1.1
    for i=1:200_000_000
        tmp = (tmp+100)/i
    end
    return tmp
end

function driver()
    cnts = @PAPI.flops begin
        slow_code()
    end
    real_time, proc_time, flpops, mflops = cnts
    @printf("Real_time: %f Proc_time: %f Total flpops: %lld MFLOPS: %f\n", 
             real_time, proc_time, flpops, mflops)
end
driver()
