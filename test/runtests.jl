using PAPI
using FactCheck

facts("PAPI library") do
    context("initialized") do
        @fact PAPI.is_initialized() => true
    end
end

facts("PAPI counters") do
    @fact PAPI.num_counters() > 0 => true
end

facts("PAPI components") do
    @fact PAPI.num_components() > 0 => true
end
