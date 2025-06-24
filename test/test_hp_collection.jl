using Pkg
Pkg.activate("$(ENV["DIVA_LIB"])")
include("$(ENV["DIVA_LIB"])/src/DIVACoast.jl")
using .DIVACoast
using DataFrames    
using Test


@info "Test HypsometricProfileCollection"

println(load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc"))
exit()
# Load a HypsometricProfile mapping from a netCDF file and convert it to a HypsometricProfileCollection
hpc = load_hsps_nc(Int32, Float32, "./testdata/UKIRL/nc/UKIRL_hspfs_floodplains.nc") |> HypsometricProfileCollection

# Calculate exposure for all HypsometricProfiles in the collection individually
# and sum the results for each exposure type
exps = map(p -> exposure(p, 3.0), hpc)
area = reduce(hcat, map(e -> e[1], exps)) |> sum
exp1 = reduce(hcat, map(e -> e[2][1], exps)) |> sum
exp2 = reduce(hcat, map(e -> e[2][2], exps)) |> sum

# Combine all HypsometricProfiles from the collection into a single HypsometricProfile
hpcomb = hpc |> HypsometricProfile

# Calculate exposure on the combined HypsometricProfile
expsc = exposure(hpcomb, 3.0)
area_comb, (exp1_comb, exp2_comb) = expsc

@testset "HypsometricProfileCollection - Exposure Calculation" begin
    @test isapprox(area, area_comb)
    @test isapprox(exp1, exp1_comb)
    @test isapprox(exp2, exp2_comb)
end

@testset "HypsometricProfileCollection - Indexing" begin
    @test typeof(hpc["22"]) == HypsometricProfile{Float32}
    @test typeof(hpc[22]) == HypsometricProfile{Float32}
    @test hpc["22"] != hpc[22]
end

@testset "HypsometricProfileCollection - Iteration" begin
    @test length(hpc) >= 0
    @test all(h -> isa(h, HypsometricProfile), hpc)
end

# Create a DataFrame directly from the HypsometricProfileCollection and then sum values by elevation
hpc_df = hpc |> DataFrame
exposure_df = combine(groupby(hpc_df, :elevation), :cumulativeArea => sum, :population => sum, :assets => sum)
exposure_df = select(exposure_df, :cumulativeArea_sum, :population_sum, :assets_sum, :elevation)
rename!(exposure_df, :cumulativeArea_sum => :cumulativeArea, :population_sum => :population, :assets_sum => :assets)
sort!(exposure_df, :elevation) # Importrant to compare same values

# Create a DataFrame by first converting the HypsometricProfileCollection to a HypsometricProfile
hpc_df2 = HypsometricProfile(hpc) |> DataFrame 
hpc_df2 = select(hpc_df2, :elevation, :cumulativeArea, :population, :assets)

sort!(hpc_df2, :elevation) # Important to compare same values

@testset "HypsometricProfileCollection - DataFrame Conversion" begin
    for col in [:cumulativeArea, :population, :assets]
        @test all(hpc_df2[!, col] .≈ exposure_df[!, col])
    end
end

