using Test

# Creates a Hypsometric Profile, with the same area for each constant elevation increment
function linearProfile()
    cv_arr_DT = arr -> convert(Array{Float32,1}, arr)
    cv_rel_DT = numb -> convert(Float32, numb)
    cv_arr_mtx = arr -> reshape(arr, length(arr), 1)

    width = cv_rel_DT(1)
    elevation = cv_arr_DT([0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6])
    area = cv_arr_DT([0, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100])
    assets = cv_arr_mtx(cv_arr_DT([0, 300, 300, 100, 100, 0, 0, 100, 50, 0, 100, 50, 0]))
    
    profile = HypsometricProfile(width, "km", elevation, "m", area, "km^2", [], [], [], assets, ["assets"], ["mUSD"]) 
    params = Dict("width" => width, "elevation" => elevation , "area" => area, "assets" => assets)
    return (profile, params)
end

width = 10
attenuation_rate = 0.8 
extreme_waterlevel = 1
inland_propagation = (extreme_waterlevel / attenuation_rate)

hp, params  = linearProfile()


area, static, dynamic = exposure_below_attenuated(hp, extreme_waterlevel, attenuation_rate)
println(area)

# Bathtub model - DIVA
area, static, dynamic = exposure_below_bathtub(hp, extreme_waterlevel)
println(area)


# Bathtub model - calculated


area, static, dynamic = exposure_below_bathtub(hp, 4f0)
